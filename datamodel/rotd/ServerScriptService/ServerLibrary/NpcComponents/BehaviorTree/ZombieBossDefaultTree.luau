local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local treePackage = {
    LogicString = {
        AggroTree = "InMeleeRange & CanAttack & [Attack] | [FollowEnemy]";
        Default = "HasEnemy & AggroTree | Idle";
    };
};

--==
function treePackage.HasEnemy(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local targetHandlerComp = npcClass:GetComponent("TargetHandler");

    local curServerTime = workspace:GetServerTimeNow();

    local enemyTargetData: NpcTargetData = targetHandlerComp:MatchFirstTarget(function(targetData)
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

        local aggroDuration = properties.AggroDuration or 60;
        if npcClass.HealthComp.LastDamagedBy and npcClass.HealthComp.LastDamageTaken+aggroDuration > curServerTime then 
            return true;
        end;

        local isInRange = (targetData.Distance <= properties.TargetableDistance);
        if not isInRange then return false end;

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

function treePackage.InMeleeRange(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    return enemyTargetData.Distance <= npcClass.Configurations.AttackRange;
end

function treePackage.FollowEnemy(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    local maxFollowDist, minFollowDist;

    if npcClass.WieldComp.EquipmentClass and npcClass.WieldComp.EquipmentClass.Class == "Gun" then
        maxFollowDist = 50;
        minFollowDist = 15;
    end

    npcClass.Move:Follow(enemyNpcClass.RootPart, maxFollowDist, minFollowDist);
    return true;
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
    if math.abs(dirAngle) > 70 then
        properties.AttackCooldown = tick() + math.random(10, 20)/100;
        return false;
    end;
    
    properties.AttackCooldown = tick() + (configurations.AttackSpeed * math.random(90, 110)/100);
    
    if npcClass.WieldComp.EquipmentClass and npcClass.WieldComp.EquipmentClass.Class == "Melee" then
        npcClass.Move:LookAt(targetPosition);
        npcClass.WieldComp:InvokeToolAction("PrimarySwingRequest");

    else
        local attackComp = npcClass:GetComponent("ZombieBasicMeleeAttack");
        if attackComp then
            attackComp();
        end

    end
    
    return true;
end


function treePackage.Idle(npcClass: NpcClass)
end

return treePackage;