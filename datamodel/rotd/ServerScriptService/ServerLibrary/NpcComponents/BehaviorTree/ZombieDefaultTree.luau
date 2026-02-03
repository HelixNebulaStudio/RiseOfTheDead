local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modRaycastUtil = shared.require(game.ReplicatedStorage.Library.Util.RaycastUtil);

--[[
    All zombie humanoid type npcs will default to this logic tree.
]]
local treePackage = {
    LogicString = {
        Default = "PreLogic | HasEnemy & (AlertTree | AggroTree) | IdleTree";
        AlertTree = "!WasDamaged & LookAtEnemy";
        AggroTree = "InMeleeRange & CanAttack & [Attack] | [FollowEnemy]";
        IdleTree = "[Idle]";
    };
}
--==

function treePackage.PreLogic(npcClass: NpcClass)
    return false;
end

function treePackage.HasEnemy(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local targetHandlerComp = npcClass:GetComponent("TargetHandler");

    local curServerTime = workspace:GetServerTimeNow();

    local enemyTargetData = targetHandlerComp:MatchFirstTarget(function(targetData)
        if targetData.HealthComp == nil then return end;
        local targetCharacterClass: CharacterClass = targetData.HealthComp.CompOwner;

        if targetCharacterClass.ClassName == "PlayerClass" then
            local player: Player = (targetCharacterClass :: PlayerClass):GetInstance();

            if npcClass.NetworkOwners then
                local isNetOwner = table.find(npcClass.NetworkOwners, player) ~= nil;
                if not isNetOwner then
                    return false;
                end
            end
        end

        local isAlive = targetCharacterClass.HealthComp.IsDead ~= true;
        if not isAlive then return false end;

        local isTargettable = targetCharacterClass.HealthComp:CanTakeDamageFrom(npcClass);
        if not isTargettable then return false end;

        if properties.HordeAggression then return true; end;
        if npcClass.HealthComp.LastDamagedBy and npcClass.HealthComp.LastDamageTaken+25 > curServerTime then return true end;

        local isInRange = (targetData.Distance <= properties.TargetableDistance);
        if not isInRange then return false end;

        local isInVision = npcClass:IsInVision(targetCharacterClass.RootPart, 75);
        if not isInVision then return false end;

        return true;
    end);

    if enemyTargetData ~= nil then
        local lockOnExpireDuration = math.random(1, 3);
        if properties.LockOnExpireDuration then
            lockOnExpireDuration = math.random(properties.LockOnExpireDuration.Min, properties.LockOnExpireDuration.Max);
        end
        properties.EnemyTargetData = enemyTargetData;
        properties.LastEnemyLockOn = tick() + lockOnExpireDuration;
        return true;

    elseif properties.CanForgetTargets ~= false then
        enemyTargetData = properties.EnemyTargetData;
        if enemyTargetData ~= nil then
            local targetCharacterClass: CharacterClass = enemyTargetData.HealthComp.CompOwner;
            if targetCharacterClass.HealthComp.IsDead then
                properties.LastEnemyLockOn = nil;
            end
        end

        if properties.LastEnemyLockOn == nil or tick() > properties.LastEnemyLockOn then
            properties.LastEnemyLockOn = nil;

            if properties.EnemyTargetData then
                npcClass.Move:Stop();
                properties.EnemyTargetData = nil;
            end
        end
        
    end

    return properties.EnemyTargetData ~= nil;
end

function treePackage.WasDamaged(npcClass: NpcClass)
    local properties = npcClass.Properties;

    if properties.HordeAggression then
        npcClass.Move:SetMoveSpeed("remove", "walk");
        return true;
    end;

    local wasDamaged = npcClass.HealthComp.LastDamagedBy ~= nil;
    if wasDamaged then
        npcClass.Move:SetMoveSpeed("remove", "walk");
    else
        npcClass.Move:SetMoveSpeed("set", "walk", math.random(5, 9), npcClass.Move.MoveSpeedPriority.Idle);
    end

    return wasDamaged;
end

function treePackage.LookAtEnemy(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    local curTick = tick();
    if properties.LookAtEnemyTick == nil then
        properties.LookAtEnemyTick = curTick + math.random(2000, 3200)/1000;
		npcClass.PlayAnimation("Aggro");
        return true;

    elseif properties.LookAtEnemyTick > curTick then
        npcClass.Move:Face(enemyNpcClass.RootPart);
        return true;

    end

    return false;
end

function treePackage.InMeleeRange(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    return enemyTargetData.Distance <= npcClass.Configurations.AttackRange;
end

function treePackage.CanAttack(npcClass: NpcClass)
    local properties = npcClass.Properties;
    return properties.AttackCooldown == nil or tick() > properties.AttackCooldown;
end

function treePackage.Attack(npcClass: NpcClass)
    local configurations = npcClass.Configurations;
    local properties = npcClass.Properties;

    local enemyTargetData = npcClass.Properties.EnemyTargetData;

    local enemyHealthComp: HealthComp = enemyTargetData.HealthComp;
    local enemyNpcClass: NpcClass = enemyHealthComp.CompOwner;

    local targetPosition = enemyNpcClass.RootPart.Position;
    local relativeCframe = npcClass.RootPart.CFrame:ToObjectSpace(CFrame.new(targetPosition));
    
    local dirAngle = math.deg(math.atan2(relativeCframe.X, -relativeCframe.Z));
    if math.abs(dirAngle) > 50 then
        properties.AttackCooldown = tick() + math.random(10, 20)/100;
        return false;
    end;
    
    properties.AttackCooldown = tick() + (configurations.AttackSpeed * math.random(90, 110)/100);
    
    local attackComp = npcClass:GetComponent("ZombieBasicMeleeAttack");
    if attackComp then
        attackComp();
    end
    
    return true;
end

function treePackage.FollowEnemy(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    npcClass.Move:Follow(enemyNpcClass.RootPart);
    return true;
end

function treePackage.Idle(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local spawnPoint = npcClass.SpawnPoint.Position;

    properties.LookAtEnemyState = nil;

    if properties.FakeSpawnPoint then
        spawnPoint = properties.FakeSpawnPoint.Position;
    end

    if properties.IsMoving == false then
        local idleGrowlRandom = properties.IdleGrowlRandom;
        if idleGrowlRandom == nil then
            idleGrowlRandom = math.random(20, 40);
            properties.IdleGrowlRandom = idleGrowlRandom;
        end

        local idleMoveRandom = properties.IdleMoveRandom;
        if idleMoveRandom == nil then
            idleMoveRandom = math.random(35, 55);
            properties.IdleMoveRandom = idleMoveRandom;
        end

        if math.random(1, idleGrowlRandom) == 1 then
            npcClass.PlayAnimation("Idle");
            modAudio.Play(`ZombieIdle{math.random(1,4)}`, npcClass.RootPart).PlaybackSpeed = math.random(80, 120)/100;
            
        elseif math.random(1, idleMoveRandom) == 1 then
            npcClass.Move:SetMoveSpeed("set", "walk", math.random(3, 6), npcClass.Move.MoveSpeedPriority.Idle);

            local castHitResults = modRaycastUtil.SplashCast(npcClass.RootPart.Position, {
                Radius = 16;
            });
            
            local wanderTargetPoint;
            if #castHitResults > 0 then
                wanderTargetPoint = castHitResults[math.random(1, #castHitResults)].Position;

            else
                local randomVec = Vector3.new(
                    (math.random(1, 2) == 1 and 1 or -1) * math.random(4, 16),
                    0,
                    (math.random(1, 2) == 1 and 1 or -1) * math.random(4, 16)
                );
                wanderTargetPoint = npcClass.RootPart.Position + randomVec;

            end

            local dirFromSpawn = (spawnPoint - npcClass.RootPart.Position).Unit;
            local magFromSpawn = (spawnPoint - npcClass.RootPart.Position).Magnitude;

            wanderTargetPoint = wanderTargetPoint + (dirFromSpawn * (magFromSpawn * math.random(50, 400)/1000));

            npcClass.Move:MoveTo(wanderTargetPoint);
        end
    end

    return true;
end

return treePackage;