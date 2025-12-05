local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modAoeHighlight = shared.require(game.ReplicatedStorage.Particles.AoeHighlight);
local modProjectile = shared.require(game.ReplicatedStorage.Library.Projectile);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);

local ROCKETS_AOE_TWEEN = TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.In, -1, true, 0);
local GROUNDPUNCH_AOE_TWEEN = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false);

local treePackage = {
    LogicString = {
        GroundPunchTree = "HasEnemy & CanGroundPunch & [GroundPunch]";
        RocketBarrageTree = "HasEnemy & CanRocketBarrage & [RocketBarrage]";
        Default = "GroundPunchTree | RocketBarrageTree | ZombieBossDefaultTree";
    };
};
--==

function treePackage.ZombieBossDefaultTree(npcClass: NpcClass)
    return npcClass.BehaviorTree:RunTree("ZombieBossDefaultTree", false);
end

function treePackage.HasEnemy(npcClass: NpcClass)
    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;
    return enemyTargetData ~= nil;
end


--MARK: GroundPunchTree
function treePackage.CanGroundPunch(npcClass: NpcClass)
    local properties = npcClass.Properties;

    local groundPunchInterval = 15;
    if properties.GroundPunchCooldown and tick()-properties.GroundPunchCooldown <= groundPunchInterval then return false; end;
    return true;
end

function treePackage.GroundPunch(npcClass: NpcClass)
    local properties = npcClass.Properties;
    properties.GroundPunchCooldown = tick();

    local groundPunchRange = properties.GroundPunchRange or 32;
    if properties.GroundPunchRange == nil then
       properties.GroundPunchRange = groundPunchRange;
    end
    properties.GroundPunchRange = properties.GroundPunchRange + 4;

    npcClass.Move:SetMoveSpeed("set", "groundpunch", 0, npcClass.Move.MoveSpeedPriority.Action, 4);

    task.wait(0.5);
    if npcClass.HealthComp.IsDead then return end;

    local groundCframe = modAoeHighlight:Ray(npcClass.RootPart.Position, Vector3.new(0, -8, 0));
    if groundCframe == nil then return end;

    npcClass.PlayAnimation("GroundPunch");

    
    local new = modAoeHighlight.newCylinder(2.3);
    new.CFrame = groundCframe
    new.Size = Vector3.new(2, 2, 1);
    new.Parent = workspace.Debris;

    TweenService:Create(new, GROUNDPUNCH_AOE_TWEEN, {Size = Vector3.new(groundPunchRange*2, groundPunchRange*2, 1)}):Play();
    
    task.wait(2);
    if npcClass.HealthComp.IsDead then return end;

    local targetDataList = npcClass:GetComponent("TargetHandler"):MatchTargets(function(targetData: NpcTargetData)
        if targetData.HealthComp == nil or targetData.HealthComp.IsDead then return end;
        return targetData.Distance <= groundPunchRange-1;
    end)

    for a=1, #targetDataList do
        local targetData: NpcTargetData = targetDataList[a];
        local targetCharClass: CharacterClass = targetData.HealthComp.CompOwner;
        if targetCharClass == nil or targetCharClass.HealthComp.IsDead then continue end;

        local throwTargetComp = npcClass:GetComponent("ThrowTarget");
        throwTargetComp(targetCharClass, 100, 50);

        if targetCharClass.ClassName == "PlayerClass" then
            local playerClass: PlayerClass = targetCharClass :: PlayerClass;
            local player: Player = playerClass:GetInstance();

            modStatusEffects.Stun(player, 3);
        end
    end
end


--MARK: RocketBarrageTree
function treePackage.CanRocketBarrage(npcClass: NpcClass)
    local properties = npcClass.Properties;

    local rocketBarrageInterval = 15.5;
    if properties.RocketBarrageCooldown and tick()-properties.RocketBarrageCooldown <= rocketBarrageInterval then return false; end;
    
    if #properties.LauncherPoints <= 0 then return false; end;

    return true;
end

function treePackage.RocketBarrage(npcClass: NpcClass)
    local properties = npcClass.Properties;
    properties.RocketBarrageCooldown = tick();
    
    npcClass.Move:SetMoveSpeed("set", "rocketbarrage", 0, npcClass.Move.MoveSpeedPriority.Action, 10);

    npcClass.PlayAnimation("RocketBarrage");


    local rocketCount = 8;

    local bodyDestructiblesComp = npcClass:GetComponent("BodyDestructibles");
    local powerSrcDestructible: DestructibleInstance = bodyDestructiblesComp:Get("PowerSource");
    if powerSrcDestructible and not powerSrcDestructible.HealthComp.IsDead then
        rocketCount = 12;
    end

    local launcherPoints = properties.LauncherPoints;
    if #launcherPoints <= 0 then return end;

    for t=1, rocketCount do
        if #launcherPoints <= 0 then break end;
        local targetDataList = npcClass:GetComponent("TargetHandler"):MatchTargets(function(targetData: NpcTargetData)
            if targetData.HealthComp == nil or targetData.HealthComp.IsDead then return false; end;
            if not targetData.HealthComp:CanTakeDamageFrom(npcClass) then return false; end;
            return true;
        end)

        for a=1, #targetDataList do
            if #launcherPoints <= 0 then break end;
            local targetData: NpcTargetData = targetDataList[a];

            local targetCharClass = targetData.HealthComp.CompOwner;
            local rootpart = targetCharClass.RootPart;

            local positionRoundOff = Vector3.new(
                math.floor(rootpart.Position.X/5)*5, 
                rootpart.Position.Y, 
                math.floor(rootpart.Position.Z/5)*5
            );

            local groundCframe = modAoeHighlight:Ray(positionRoundOff, Vector3.new(0, -8, 0));
            if groundCframe then
                local travelTime = 1;
                
                local new = modAoeHighlight.newCylinder(travelTime);
                new.CFrame = groundCframe
                new.Size = Vector3.new(2, 2, 1);
                new.Parent = workspace.Debris;

                TweenService:Create(new, ROCKETS_AOE_TWEEN, {Size = Vector3.new(32, 32, 1)}):Play();
                
                local launcherPointAtt = launcherPoints[math.random(1,#launcherPoints)];
                local originCf = launcherPointAtt.WorldCFrame;
                local targetPoint = groundCframe.Position;

                local projectileInstance: ProjectileInstance = modProjectile.fire("zomborgrocket", {
                    OriginCFrame = CFrame.lookAlong(originCf.Position, launcherPointAtt.CFrame.LookVector);
                    CharacterClass = npcClass;
                });

                local velocity = projectileInstance.ArcTracer:GetVelocityByTime(originCf.Position, targetPoint, travelTime);
                modProjectile.serverSimulate(projectileInstance, {
                    Velocity = velocity;
                    RayWhitelist = {workspace.Environment; workspace.Terrain};
                    IgnoreEntities = true;
                });

            end
        end

        task.wait(0.5);
        if npcClass.HealthComp.IsDead then return end;
    end

    npcClass.StopAnimation("RocketBarrage");
end

return treePackage;