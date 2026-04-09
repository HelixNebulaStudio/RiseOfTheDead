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
    local processStatusesComp = npcClass:GetComponent("ProcessStatuses");
    if processStatusesComp then
        return processStatusesComp();
    end

    return false;
end

function treePackage.HasEnemy(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local targetHandlerComp = npcClass:GetComponent("TargetHandler");

    local curServerTime = workspace:GetServerTimeNow();

    local enemyTargetData = targetHandlerComp:MatchFirstTarget(function(targetData: NpcTargetData)
        local targetHealthComp: HealthComp = targetData.HealthComp;
        if targetHealthComp == nil then return false; end;

        local isAlive = targetHealthComp.IsDead ~= true;
        if not isAlive then return false end;

        local targetEntityClass: EntityClass = targetHealthComp.CompOwner;
        if targetEntityClass.ClassName == "PlayerClass" then
            local player: Player = (targetEntityClass :: PlayerClass):GetInstance();

            if npcClass.NetworkOwners then
                local isNetOwner = table.find(npcClass.NetworkOwners, player) ~= nil;
                if not isNetOwner then
                    return false;
                end
            end
        end

        local isTargettable = targetHealthComp:CanTakeDamageFrom(npcClass);
        if not isTargettable then return false end;

        if properties.HordeAggression then return true; end;
        if npcClass.HealthComp.LastDamagedBy and npcClass.HealthComp.LastDamageTaken+25 > curServerTime then return true end;

        local isInRange = (targetData.Distance <= properties.TargetableDistance);
        if not isInRange then return false end;

        if targetEntityClass.ClassName ~= "Destructible" then
            local isInVision = targetData.Model.PrimaryPart and npcClass:IsInVision(targetData.Model.PrimaryPart, 75) or false;
            if not isInVision then return false end;
        end

        if targetEntityClass.Character and targetEntityClass.Character:FindFirstChild("GodModeFF") then
            return false;
        end

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
    local targetData = npcClass.Properties.EnemyTargetData;

    local enemyCharClass: CharacterClass = targetData.HealthComp.CompOwner;
    if enemyCharClass.ClassName == "NpcClass" or enemyCharClass.ClassName == "PlayerClass" then
        local curTick = tick();
        if properties.LookAtEnemyTick == nil then
            local lockOnEnemyDuration = properties.LockEnemyOnDuration or NumberRange.new(2, 3.2);
            properties.LookAtEnemyTick = curTick + math.random(lockOnEnemyDuration.Min * 1000, lockOnEnemyDuration.Max *1000)/1000;
            npcClass.PlayAnimation("Aggro");
            return true;

        elseif properties.LookAtEnemyTick > curTick then
            npcClass.Move:Face(enemyCharClass.RootPart);
            return true;

        end
    end

    return false;
end

function treePackage.InMeleeRange(npcClass: NpcClass)
    local targetData = npcClass.Properties.EnemyTargetData;
    return targetData.Distance <= npcClass.Configurations.AttackRange;
end

function treePackage.CanAttack(npcClass: NpcClass)
    local properties = npcClass.Properties;
    return properties.AttackCooldown == nil or tick() > properties.AttackCooldown;
end

function treePackage.Attack(npcClass: NpcClass)
    local configurations = npcClass.Configurations;
    local properties = npcClass.Properties;

    local targetData = npcClass.Properties.EnemyTargetData;

    local targetHealthComp: HealthComp = targetData.HealthComp;
    local targetEntityClass: EntityClass = targetHealthComp.CompOwner;

    local targetPosition = targetEntityClass:GetCFrame().Position;
    if targetEntityClass.ClassName == "PlayerClass" then
        local relativeCframe = npcClass.RootPart.CFrame:ToObjectSpace(CFrame.new(targetPosition));
        
        local dirAngle = math.deg(math.atan2(relativeCframe.X, -relativeCframe.Z));
        if math.abs(dirAngle) > 50 then
            properties.AttackCooldown = tick() + math.random(10, 20)/100;
            return false;
        end;
    end
    
    properties.AttackCooldown = tick() + (configurations.AttackSpeed * math.random(90, 110)/100);
    
    local attackComp = npcClass:GetComponent("ZombieBasicMeleeAttack");
    if npcClass.WieldComp.EquipmentClass and npcClass.WieldComp.EquipmentClass.Class == "Melee" then
        npcClass.Move:LookAt(targetPosition);
        npcClass.WieldComp:InvokeToolAction("PrimarySwingRequest");

    elseif attackComp then
        attackComp(targetData.TargetPart);
    end
    
    return true;
end

function treePackage.FollowEnemy(npcClass: NpcClass)
    local targetData: NpcTargetData = npcClass.Properties.EnemyTargetData;

    local targetPart = targetData.TargetPart or targetData.Model.PrimaryPart;

    npcClass.Move:Follow(targetPart);
    return true;
end

function treePackage.Idle(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local spawnPoint = npcClass.SpawnCFrame.Position;

    properties.LookAtEnemyState = nil;

    if properties.FakeSpawnPoint then
        spawnPoint = properties.FakeSpawnPoint.Position;
    end

    if properties.IsMoving == false and (tick()-npcClass.LastRespawnTick) > 10 then
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

    local healthComp = npcClass.HealthComp;
    if healthComp.LastDamagedBy == nil and healthComp.CurHealth < healthComp.MaxHealth then
        healthComp:SetHealth(healthComp.CurHealth + math.ceil(healthComp.MaxHealth * 0.1));
    end

    return true;
end

return treePackage;