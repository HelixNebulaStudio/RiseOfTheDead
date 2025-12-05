local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");
local RunService = game:GetService("RunService");

local modAoeHighlight = shared.require(game.ReplicatedStorage.Particles.AoeHighlight);
local modProjectile = shared.require(game.ReplicatedStorage.Library.Projectile);
local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local ROCKETS_AOE_TWEENINFO = TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.In, -1, true, 0);
local ROPE_DEPLOY_TWEENINFO = TweenInfo.new(5);

local treePackage = {
    LogicString = {
        CircleTree = "HasEnemy & IsCirclingState & [Circle]";
        MolotovTree = "HasEnemy & IsMolotovState & [Molotov]";
        RocketBarrageTree = "HasEnemy & CanRocketBarrage & [RocketBarrage]";
        DeployHeavyBanditsTree = "HasEnemy & CanDeployHeavyBandits & [DeployHeavyBandits]";
        Default = "RocketBarrageTree | DeployHeavyBanditsTree | CircleTree | MolotovTree | Idle";
    };
};
--==
function treePackage.HasEnemy(npcClass: NpcClass)
    local hasEnemy = npcClass.BehaviorTree:RunTree("HasEnemy", false);
    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;

    return enemyTargetData ~= nil;
end

function treePackage.Idle(npcClass: NpcClass)
    local properties = npcClass.Properties;

    if properties.State == "Idle" then
        properties.State = "Circle";
        properties.StateChangedTick = tick();
    end

    return true;
end


--MARK: CircleTree
function treePackage.IsCirclingState(npcClass: NpcClass)
    return npcClass.Properties.State == "Circle";
end

function treePackage.Circle(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local heliInstance = properties.HelicopterInstance;
    local gunmenNpcClasses = properties.GunmenNpcClasses;

    heliInstance:ToggleDoors(true);
    if heliInstance.MoveState ~= "Circle" then
        heliInstance.MoveState = "TransitionToCircle";
    end

    local tl = tick()-properties.StateChangedTick;
    if properties.GunmenSpawned == false then
        if tl >= 2 then
            if npcClass.HealthComp.IsDead then return end;
            if properties.GunmenSpawned then return end;
            properties.GunmenSpawned = true;

            if #gunmenNpcClasses <= 0 then
                for a=1, 2 do
                    local seatPart = heliInstance.GunmenSeats[a];
                    table.insert(gunmenNpcClasses, shared.modNpcs.spawn2{
                        Name = "Bandit";
                        CFrame = seatPart.CFrame;
                        PackageOverride = "Bandit Gunmen";
                        NetworkOwners = npcClass.NetworkOwners;
                        BindSetup = function(banditNpcClass: NpcClass)
                            banditNpcClass.RootPart.Anchored = true;
                            
                            banditNpcClass.Properties.Seat = seatPart;
                            banditNpcClass.RootPart.Massless = true;
                            banditNpcClass.Humanoid.PlatformStand = true;

                            banditNpcClass.HealthComp.OnIsDeadChanged:Connect(function(isDead, oldVal, damageData)
                                if not isDead then return end;

                                for a=#gunmenNpcClasses, 1, -1 do
                                    if gunmenNpcClasses[a] == banditNpcClass then
                                        table.remove(gunmenNpcClasses, a);
                                    end
                                end

                                npcClass.HealthComp:TakeDamage(DamageData.new{
                                    Damage = 20;
                                    DamageBy = damageData and damageData.DamageBy or nil;
                                });
                            end)
                        end
                    });
                end
            end
        end

    else
        if tl >= 60 or #properties.GunmenNpcClasses <= 0 then
            properties.State = "Molotov";
            properties.StateChangedTick = tick();
            properties.MolotovState = 1;
        end
    end
end


--MARK: MolotovTree
function treePackage.IsMolotovState(npcClass: NpcClass)
    return npcClass.Properties.State == "Molotov";
end

function treePackage.Molotov(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local heliInstance = properties.HelicopterInstance;

    heliInstance:ToggleDoors(false);
    local molotovState = properties.MolotovState or 1;

    if molotovState == 1 then
        local random = math.random(1, 4);
        local startPosition = Vector3.new(0, heliInstance.Altitude, 150);
        if random == 1 then
            startPosition = Vector3.new(150, heliInstance.Altitude, 0);
        elseif random == 2 then
            startPosition = Vector3.new(75, heliInstance.Altitude, 75);
        elseif random == 3 then
            startPosition = Vector3.new(-75, heliInstance.Altitude, 75);
        end
        startPosition = startPosition;

        heliInstance.Speed = 100;
        heliInstance:Move(heliInstance.CirclingPoint + startPosition);

        properties.MolotovStartPosition = startPosition;
        properties.MolotovState = 2;
        properties.DropMolotovActive = true;

    elseif molotovState == 2 then
        if heliInstance.IsAtTarget then
            properties.MolotovState = 3;
        end

    elseif molotovState == 3 then
        local startPosition = properties.MolotovStartPosition;

        local endPosition = startPosition * Vector3.new(-1, 1, -1);
        heliInstance.Speed = 140;
        heliInstance:Move(heliInstance.CirclingPoint + endPosition);

        properties.MolotovState = 4;

    elseif molotovState == 4 then
        if heliInstance.IsAtTarget then
            properties.MolotovState = 5;
        end

    elseif molotovState == 5 then
        properties.DropMolotovActive = false;
        properties.State = "Circle";
        properties.StateChangedTick = tick();

    end

end


--MARK: RocketBarrageTree
function treePackage.CanRocketBarrage(npcClass: NpcClass)
    local properties = npcClass.Properties;

    local heliInstance = properties.HelicopterInstance;
    if heliInstance.LeftLaunchers == nil and heliInstance.RightLaunchers == nil then return false; end;

    if properties.State == "RocketBarrage" then return true; end;
    if properties.State ~= "Circle" then return false; end;

    if properties.HardMode ~= true then return false end;

    local rocketBarrageInterval = 16;
    if properties.RocketBarrageCooldown == nil then
        properties.RocketBarrageCooldown = tick();
    end
    if properties.RocketBarrageCooldown and tick()-properties.RocketBarrageCooldown <= rocketBarrageInterval then 
        return false; 
    end;
    
    properties.RocketBarrageCooldown = tick();
    properties.RocketBarrageCount = 0;
    heliInstance.MoveState = "TransitionToCircle";
    properties.State = "RocketBarrage";
    properties.StateChangedTick = tick();

    return true;
end

function treePackage.RocketBarrage(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local heliInstance = properties.HelicopterInstance;

    properties.RocketBarrageCooldown = tick();
    if heliInstance.MoveState == "TransitionToCircle" then return end;


    if properties.RocketBarrageCount == nil then
        properties.RocketBarrageCount = 0;
        properties.RocketIntervalCooldown = tick()+0.3;
    end
    if properties.RocketIntervalCooldown and tick() < properties.RocketIntervalCooldown then return end;
    properties.RocketIntervalCooldown = tick()+0.3;

    properties.RocketBarrageCount += 1;
    if properties.RocketBarrageCount >= 10 then
        properties.State = "Circle";
        properties.StateChangedTick = tick();
        return;
    end
    
    local targetHandlerComp = npcClass:GetComponent("TargetHandler");
    local validTargets: {NpcTargetData} = targetHandlerComp:MatchTargets(function(targetData: NpcTargetData)
        if targetData.HealthComp.IsDead then return false end;
        return true;
    end)

    if #validTargets <= 0 then return end;
    local pickTarget: NpcTargetData = validTargets[math.random(1, #validTargets)];
    if pickTarget == nil then return end;

    heliInstance:ToggleDoors(false);

    local selectedLaunchers = heliInstance.LeftLaunchers or heliInstance.RightLaunchers;
    if math.random(1, 2) == 1 then
        selectedLaunchers = heliInstance.RightLaunchers or heliInstance.LeftLaunchers;
    end
    if selectedLaunchers == nil then return; end

    local pickLauncherAtt = selectedLaunchers[math.random(1, #selectedLaunchers)];

    local travelTime = math.random(90, 120)/100;
                     
    local characterClass = pickTarget.HealthComp.CompOwner;
    local targetPosition = characterClass.RootPart.Position;
                   
    local origin = pickLauncherAtt.WorldCFrame.Position;

    local groundCframe = modAoeHighlight:Ray(targetPosition, Vector3.new(0, -8, 0));
    
    if groundCframe then
        local new = modAoeHighlight.newCylinder(travelTime);
        new.CFrame = groundCframe
        new.Size = Vector3.new(2, 2, 1);
        new.Parent = workspace.Debris;

        TweenService:Create(new, ROCKETS_AOE_TWEENINFO, {Size = Vector3.new(32,32,1)}):Play();
        
        local projectileInstance: ProjectileInstance = modProjectile.fire("zomborgrocket", {
            OriginCFrame = CFrame.lookAlong(origin, pickLauncherAtt.WorldCFrame.LookVector);
            CharacterClass = npcClass;
        });

        local velocity = projectileInstance.ArcTracer:GetVelocityByTime(origin, targetPosition, travelTime);
        modProjectile.serverSimulate(projectileInstance, {
            Velocity = velocity;
            RayWhitelist = {workspace.Environment; workspace.Terrain};
            IgnoreEntities = true;
        });
        
    end

end


--MARK: DeployHeavyBandits
function treePackage.CanDeployHeavyBandits(npcClass: NpcClass)
    local properties = npcClass.Properties;

    if npcClass.Properties.State == "DeployHeavyBandits" then return true; end;
    if properties.State ~= "Circle" then return false; end;

    if properties.HardMode ~= true then return false end;
    if #properties.HeavyBanditsNpcClasses > 0 then return false; end;

    local heavyDeployInterval = 10;
    if properties.DeployHeavyBanditsCooldown == nil then
        properties.DeployHeavyBanditsCooldown = tick();
    end
    if properties.DeployHeavyBanditsCooldown and tick()-properties.DeployHeavyBanditsCooldown <= heavyDeployInterval then 
        return false; 
    end;
    
    properties.State = "DeployHeavyBandits";
    properties.StateChangedTick = tick();
    properties.DeployTimer = nil;

    return true;
end

function treePackage.DeployHeavyBandits(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local heliInstance = properties.HelicopterInstance;

    local heavyBanditsNpcClasses = properties.HeavyBanditsNpcClasses;

    heliInstance:ToggleDoors(false);
    local deployState = properties.DeployState or 1;
    local deployTimer = properties.DeployTimer;
    if deployTimer == nil then
        deployTimer = tick();
        properties.DeployTimer = deployTimer;
    end

    if deployState == 1 then
        heliInstance.Speed = 50;
        heliInstance:Move(heliInstance.CirclingPoint);
        properties.DeployState = 2;

    elseif deployState == 2 then
        if heliInstance.IsAtTarget then
            properties.DeployTimer = tick();
            properties.DeployState = 3;
        end

    elseif deployState == 3 then

        if tick()-properties.DeployTimer <= 2 then return end;

        properties.DeployState = 4;
        properties.DeployTimer = tick();

        for a=1, #properties.DeployRopes do
            local ropeObj = properties.DeployRopes[a];
            if ropeObj.Name == "RopePointJoint" then
                ropeObj.Enabled = false;
                
            else
                ropeObj.Length = 1;
                ropeObj.Visible = true;
                TweenService:Create(ropeObj, ROPE_DEPLOY_TWEENINFO, {
                    Length = 45;
                }):Play();
            end
        end

        for a=1, 2 do
            local deploySeat: Seat = properties.DeploySeats[a];
            if deploySeat:CanSetNetworkOwnership() then
                deploySeat:SetNetworkOwner(nil);
            end
            table.insert(heavyBanditsNpcClasses, shared.modNpcs.spawn2{
                Name = "Heavy Bandit";
                CFrame = deploySeat.CFrame;
                NetworkOwners = npcClass.NetworkOwners;
                
                BindSetup = function(banditNpcClass: NpcClass)
                    banditNpcClass.RootPart.Anchored = true;
                    
                    banditNpcClass.Properties.Seat = deploySeat;
                    banditNpcClass.RootPart.Massless = true;
                    banditNpcClass.Humanoid.PlatformStand = true;

                    banditNpcClass.HealthComp.OnIsDeadChanged:Connect(function(isDead, oldVal, damageData)
                        if not isDead then return end;

                        for a=#heavyBanditsNpcClasses, 1, -1 do
                            if heavyBanditsNpcClasses[a] == banditNpcClass then
                                table.remove(heavyBanditsNpcClasses, a);
                            end
                        end
                    end)

                    task.delay(5, function()
                        banditNpcClass:Sit(nil);
                    end)
                end
            });
        end

    elseif deployState == 4 then
        if tick()-deployTimer >= 6 then
            properties.DeployState = 5;
            properties.DeployTimer = tick();
        end

    elseif deployState == 5 then
        if tick()-deployTimer >= 10 then
            properties.DeployState = 6;
        end

    elseif deployState == 6 then
        for a=1, #properties.DeployRopes do
            local ropeObj = properties.DeployRopes[a];
            if ropeObj.Name == "RopePointJoint" then
                ropeObj.Enabled = false;
                
            else
                ropeObj.Length = 1;
                ropeObj.Visible = false;
            end
        end

        npcClass.Properties.State = "Circle";
        npcClass.Properties.StateChangedTick = tick();
        properties.DeployTimer = nil;
        properties.DeployState = 1;

    end

end

return treePackage;