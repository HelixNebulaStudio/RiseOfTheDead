local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService")

local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modParticleSprinkler = shared.require(game.ReplicatedStorage.Particles.ParticleSprinkler);
local modMath = shared.require(game.ReplicatedStorage.Library.Util.Math);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local npcPackage = {
    Name = "Vexeron";
    HumanoidType = "Zombie";
    
	Configurations = {
        MaxHealth = 100;
    };
    
    Properties = {
        BasicEnemy = false;
        IsHostile = true;

        TargetableDistance = 256;
        LockOnExpireDuration = NumberRange.new(100, 120);

        Level = 1;
        ExperiencePool = 1000;
        MoneyReward = NumberRange.new(2000, 3500);

        ContactDamage = 10;
        SpeedRatio = 1;

        KnockbackResistant = 1;
    };

    Audio = {};

    AddComponents = {
        "DropReward";
        "TargetHandler";
        "BodyDestructibles";
    };
    AddBehaviorTrees = {
        "HasEnemy";
    };

    TouchHandler = nil;
    ThinkCycle = 1;
};
--==

function npcPackage.Spawning(npcClass: NpcClass)
    local character = npcClass.Character;
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;
    local healthComp: HealthComp = npcClass.HealthComp;

    npcClass.Character:SetAttribute("EntityHudHealth", true);

    local isHard = properties.HardMode;
    local level = math.max(properties.Level, 0);

    local bodyVelocity = Instance.new("BodyVelocity");
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge);
    bodyVelocity.Velocity = Vector3.new(0, 0, 0);
    bodyVelocity.P = 50;
    bodyVelocity.Parent = npcClass.RootPart;
    properties.BodyVelocity = bodyVelocity;
		
    local bodyGyro = Instance.new("BodyGyro");
	bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge);
	bodyGyro.P = 40000;
	bodyGyro.Parent = npcClass.RootPart;
	properties.BodyGyro = bodyGyro;	

    npcClass.Humanoid.PlatformStand = true;
    npcClass.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true);
    npcClass.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true);

    local twistAngleLimit = 65;
	local vexBodyPrefab = character:WaitForChild("Vexeworm");

    if isHard then
        properties.VexeronLength = 16;

        configurations.BaseValues.MaxHealth = math.max(2300400 + 10000*level, 100);
        properties.ContactDamage = 20;

    else
        properties.VexeronLength = 8;

        configurations.BaseValues.MaxHealth = math.max(204800 + 10000*level, 100);
        properties.ContactDamage = 10;

        vexBodyPrefab.Material = Enum.Material.Sand;
        vexBodyPrefab.Color = Color3.fromRGB(121, 86, 75);
    end


    local bodyWeights = {};
    local ballConstraints = {};

    local prevLowerLink = vexBodyPrefab:WaitForChild("LowerLink");
    for a=1, properties.VexeronLength do
        local new = vexBodyPrefab:Clone();
        new.Name = new.Name..a;
        
        if isHard then
            new.Size = vexBodyPrefab.Size * 1.6;
            local nULink = new:WaitForChild("UpperLink");
            local nLLink = new:WaitForChild("LowerLink");
            nULink.Position = Vector3.new(0, 8, 0);
            nLLink.Position = Vector3.new(0, -8, 0);

        else
            new.Size = vexBodyPrefab.Size * 1.1;
            local nULink = new:WaitForChild("UpperLink");
            local nLLink = new:WaitForChild("LowerLink");
            nULink.Position = Vector3.new(0, 5, 0);
            nLLink.Position = Vector3.new(0, -5, 0);

        end
        
        local constraint = Instance.new("BallSocketConstraint");
        constraint.Attachment0 = new:WaitForChild("UpperLink");
        constraint.Attachment1 = prevLowerLink;
        constraint.LimitsEnabled = true;
        constraint.TwistLimitsEnabled = true;
        constraint.UpperAngle = twistAngleLimit;
        constraint.TwistLowerAngle = -twistAngleLimit;
        constraint.TwistUpperAngle = twistAngleLimit;
        constraint.Parent = new;
        prevLowerLink = new:WaitForChild("LowerLink");

        table.insert(ballConstraints, constraint);
        
        local newBodyVelocity = Instance.new("BodyVelocity");
        newBodyVelocity.Name = "Weight";
        local force = 1000000;
        newBodyVelocity.MaxForce = Vector3.new(force, force, force);
        newBodyVelocity.Velocity = Vector3.new(0, 0, 0);
        newBodyVelocity.P = 1500;
        newBodyVelocity.Parent = new;
        
        table.insert(bodyWeights, newBodyVelocity);
        
        new.Parent = character;
    end



    local vexeronRemote = Instance.new("RemoteEvent");
    vexeronRemote.Name = "VexeronRemote";
    vexeronRemote.Parent = character;

    npcClass.Garbage:Tag(vexeronRemote.OnServerEvent:Connect(function(player: Player, vexBodyPart: BasePart)
        local playerClass: PlayerClass = shared.modPlayers.get(player);
        local hitCharacter = playerClass.Character;
        if hitCharacter == nil or playerClass.HealthComp.IsDead then return end;
        if vexBodyPart == nil or not vexBodyPart:IsDescendantOf(character) then return end;
        if not playerClass.HealthComp:CanTakeDamageFrom(npcClass) then return end;

        local vexeronHitDebounce = playerClass.Properties.VexeronHitDebounceTick;
        if vexeronHitDebounce and tick() <= vexeronHitDebounce then return end;

        playerClass.Properties.VexeronHitDebounceTick = tick() + 0.3;

        playerClass.HealthComp:TakeDamage(DamageData.new{
            Damage = properties.ContactDamage;
            DamageBy = npcClass;
        });

        if isHard then
            modStatusEffects.Knockback(player, vexBodyPart, 50);
        end
    end))

    function properties.UpdateVelocity()
        bodyVelocity.Velocity = bodyGyro.CFrame.UpVector * bodyVelocity.P;

        for a=1, #bodyWeights do
            if bodyWeights[a].Parent == nil then continue end;
            
            bodyWeights[a].Velocity = bodyWeights[a].Parent.CFrame.UpVector * bodyVelocity.P;
        end
    end

    bodyVelocity:GetPropertyChangedSignal("P"):Connect(properties.UpdateVelocity);
    bodyGyro:GetPropertyChangedSignal("CFrame"):Connect(properties.UpdateVelocity);
    npcClass.Garbage:Tag(bodyVelocity);
    npcClass.Garbage:Tag(bodyGyro);

    for _, v in next, character:GetDescendants() do
        if not v:IsA("BasePart") then continue end;
        v.CollisionGroup = "CollisionOff";
    end

    npcClass.Garbage:Tag(function()
		modAudio.Play("VexeronGrowl", properties.DeathPosition);

        for a=1, #ballConstraints do
            game.Debris:AddItem(ballConstraints[a], 0);
        end
        table.clear(ballConstraints);

        for a=1, #bodyWeights do
            local parentPart = bodyWeights[a].Parent;
            if parentPart:IsA("BasePart") then
                parentPart.CollisionGroup = "Debris";
                parentPart.CanCollide = true;
            end
            game.Debris:AddItem(bodyWeights[a], 0);
        end
        table.clear(bodyWeights);
    end)

    properties.State = "Hunt";
    properties.StageChangedTick = tick();
end

function npcPackage.Spawned(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local healthComp = npcClass.HealthComp;
    local rootPart = npcClass.RootPart;
    local character = npcClass.Character;

    local isHard = properties.HardMode;
    local bodyVelocity = properties.BodyVelocity;
    local bodyGyro = properties.BodyGyro;


    local bodyDestructiblesComp = npcClass:GetComponent("BodyDestructibles");
    local bodyParts = character:GetChildren();
    for a=1, #bodyParts do
        local bodyPart: BasePart = bodyParts[a];
        if not bodyParts[a]:IsA("BasePart") then continue end;

        if bodyPart.Name:match("Vexeworm") then
            local newWormModel = Instance.new("Model");
            newWormModel.Name = bodyPart.Name;
            newWormModel.Parent = character;
            bodyPart.Name = "PrimaryPart";
            bodyPart.Parent = newWormModel;
            newWormModel.PrimaryPart = bodyPart;

            local destructible: DestructibleInstance = bodyDestructiblesComp:Create(newWormModel.Name, newWormModel);
            destructible.Properties.DestroyModel = false;
            local newHealth = isHard and 50000 or 25000;
            
            destructible:SetupHealthbar{
                Size = UDim2.new(1.2, 0, 0.25, 0);
                Distance = 64;
                OffsetWorldSpace = Vector3.new(0, 1, 0);
                ShowLabel = false;
            };
            destructible:SetHealthbarEnabled(true);

            local limbHealthComp: HealthComp = destructible.HealthComp;
            limbHealthComp:SetMaxHealth(newHealth);
            limbHealthComp:Reset();

            limbHealthComp.OnHealthChanged:Connect(function(newHealth, prevHealth, damageData)
                if limbHealthComp.IsDead then return end;
                if newHealth == prevHealth then return end;
                if damageData.Damage == nil then return end;

                healthComp:TakeDamage(damageData);
            end)

            destructible.OnDestroy:Connect(function()
                bodyPart.Color = Color3.fromRGB(50, 50, 50);

                healthComp:TakeDamage(DamageData.new{
                    Damage = isHard and 100000 or 7500;
                    DamageBy = limbHealthComp.LastDamagedBy;
                });

                properties.SpeedRatio = math.clamp(properties.SpeedRatio-0.05, 0.5, 1);
                
                modAudio.Play("TicksZombieExplode", bodyPart).PlaybackSpeed = math.random(30,40)/100;
                modAudio.Play("VexeronPain", bodyPart).PlaybackSpeed = math.random(90,110)/100;
                modParticleSprinkler:Emit{
                    Type = 1;
                    Origin = CFrame.new(bodyPart.Position);
                    Velocity = Vector3.new(0, 1, 0);
                    SizeRange = {Min=1; Max=3};
                    Material = bodyPart.Material;
                    DespawnTime = 5;
                    Speed = 60;
                    Color = bodyPart.Color;
                };
            end)
        end
    end


    function properties.PointTo(point: Vector3, lerpIntensity: number?)
		local newFrontCf = CFrame.new(rootPart.Position, point) * CFrame.Angles(-math.pi/2, 0, 0);
		
		bodyGyro.CFrame = bodyGyro.CFrame:Lerp(newFrontCf, math.clamp(lerpIntensity or (isHard and 0.04 or 0.01), 0.01, 1));
	end

    local bodyParts = npcClass.Character:GetChildren();
    for a=1, #bodyParts do
        local bodyPart: BasePart = bodyParts[a];
        if not bodyParts[a]:IsA("BasePart") then continue end;

        bodyPart:SetNetworkOwner(nil);
    end
    
    local spawnPoint = npcClass.SpawnCFrame;
    task.spawn(function() 
        while not healthComp.IsDead do
			bodyVelocity.P = (isHard and 90 or 50) * properties.SpeedRatio;

            local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;
            local enemyPosition = enemyTargetData and enemyTargetData.HealthComp.CompOwner.RootPart.Position or spawnPoint.Position;

            local t = tick()/8;

            local targetPoint;
            if enemyTargetData == nil or properties.State == "Idle" then
                local spinVec = Vector3.new(math.sin(t), 0, math.cos(t)); 
                targetPoint = spawnPoint.Position + spinVec * 70;


            elseif properties.State == "Hunt" then
                local enemyDistance = enemyTargetData.Distance;

                local spinVec = Vector3.new(math.sin(t), 0, math.cos(t));
                local lapseRatio = math.clamp(tick()-properties.StageChangedTick, 0, 6)/6;

                local newPos = enemyPosition + spinVec * lapseRatio*2 * 25;
                newPos = newPos+ Vector3.new(0, -math.clamp(enemyDistance/4, 0, 25), 0);
                targetPoint = newPos;
                

            elseif properties.State == "Attack" then
                local tpi = t * math.pi;
                local s = math.ceil(tick()/2%5);
                
                local x = math.sin((tpi-1)/2);
                local z = math.cos(tpi-1);
                
                local v;
                if s == 1 then
                    v = Vector3.new(x, 0, z);
                elseif s == 2 then
                    v = Vector3.new(z, 0, x);
                elseif s == 3 then
                    v = Vector3.new(-x, 0, -z);
                elseif s == 4 then
                    v = Vector3.new(-z, 0, x);
                elseif s == 5 then
                    v = Vector3.new(z, 0, -x);
                end

                local swerveVec = v;
                targetPoint = enemyPosition + swerveVec * 25;
            end

            if targetPoint then
                local dist = npcClass:DistanceFromCharacter(targetPoint);
                local lerpIntensity = modMath.MapNum(dist, 0, 400, 0, 1, true);
                properties.PointTo(targetPoint, lerpIntensity);
            end

            task.wait();
        end
    end)
end

return npcPackage;