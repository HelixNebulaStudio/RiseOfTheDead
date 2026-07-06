local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modRegion = shared.require(game.ReplicatedStorage.Library.Region);

local treePackage = {
    LogicString = {
        Default = "PreLogic | HasEnemy & (AlertTree | AggroTree) | (ShouldDetonate & [Detonate]) | [Idle]";
        AlertTree = "LookAtEnemy";
        AggroTree = "IgniteDetonation & [Detonate] | [FollowEnemy]";
    };
}

function treePackage.PreLogic(npcClass: NpcClass)
    local properties = npcClass.Properties;

    local processStatusesComp = npcClass:GetComponent("ProcessStatuses");
    if processStatusesComp then
        local skipTree = processStatusesComp();
        
        if skipTree then
            if properties.TickingSound then
                properties.TickingSound:Stop();
                game.Debris:AddItem(properties.TickingSound, 0);
                properties.TickingSound = nil;
                npcClass.Character:SetAttribute("DetonationTime", nil);
            end

            properties.DetonationReady = nil;
        end

        return skipTree;
    end
    
    return false;
end

function treePackage.HasEnemy(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local targetHandlerComp = npcClass:GetComponent("TargetHandler");

    local enemyTargetData = targetHandlerComp:MatchFirstTarget(function(targetData)
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

        local isInRange = (targetData.Distance <= properties.TargetableDistance);
        if not isInRange then return false end;

        return true;
    end);

    properties.EnemyTargetData = enemyTargetData;

    return enemyTargetData ~= nil;
end

function treePackage.LookAtEnemy(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local targetData = npcClass.Properties.EnemyTargetData;
    local targetEntityClass: EntityClass = targetData.HealthComp.CompOwner;

    if targetEntityClass.ClassName == "Destructible" then
        return false;
    end

    local curTick = tick();
    if properties.LookAtEnemyTick == nil then
        properties.LookAtEnemyTick = curTick + math.random(200, 300)/1000;
		npcClass.PlayAnimation("Aggro");
        return true;

    elseif properties.LookAtEnemyTick > curTick then
        npcClass.Move:Face((targetEntityClass :: CharacterClass).RootPart);
        return true;

    end

    return false;
end

function treePackage.IgniteDetonation(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local targetData = npcClass.Properties.EnemyTargetData;

    local npcChar = npcClass.Character;

    local targetEntityClass: EntityClass = targetData.HealthComp.CompOwner;
    local targetRootPart = targetEntityClass.RootPart;
    
    local detonTime = npcChar:GetAttribute("DetonationTime");
    if detonTime == nil then
        if modRegion:InRegion(npcClass.RootPart.Position, targetRootPart.Position, 30) then

            if targetEntityClass.ClassName == "PlayerClass" then
                local dynamicLevel = npcClass:GetComponent("DynamicLevel");
                if dynamicLevel and properties.Level == nil then
                    dynamicLevel(targetEntityClass);
                end
            end

            local duration = 4;
            npcChar:SetAttribute("DetonationTime", workspace:GetServerTimeNow()+duration);
            
            local tickingSound = modAudio.Play("ZombieAttack3", targetRootPart);
            tickingSound.Looped = true;
            tickingSound.Volume = 0;

            properties.TickingSound = tickingSound;
            npcClass.Garbage:Tag(tickingSound);
            
            task.spawn(function()
                detonTime = npcChar:GetAttribute("DetonationTime");

                while workspace:GetServerTimeNow() <= detonTime do
                    if npcChar:GetAttribute("DetonationTime") == nil then return end;
                    local timeLeft = npcChar:GetAttribute("DetonationTime")-workspace:GetServerTimeNow();
                    
                    timeLeft = duration-math.clamp(timeLeft, 0, duration);
                    
                    tickingSound.PlaybackSpeed = 1+ (timeLeft/duration * 8);
                    tickingSound.Volume = math.clamp(timeLeft/duration, 0.5, 1);
                    task.wait(0.2);
                    if npcClass.HealthComp.IsDead then break end;
                end
                
                properties.DetonationReady = true;
                npcClass.OnThink:Fire();
            end)
        end
    end

    if properties.DetonationReady then
        return true;
    end

    return false;
end

function treePackage.ShouldDetonate(npcClass: NpcClass)
    local properties = npcClass.Properties;
    return properties.DetonationReady == true;
end

function treePackage.Detonate(npcClass: NpcClass)
    local configurations = npcClass.Configurations;
    local properties = npcClass.Properties;

    if properties.IsDetonating then return end;
    properties.IsDetonating = true;

    if not properties.DetonationReady then return end;

    local tickCombustionComp = npcClass:GetComponent("TickCombustion");
    if tickCombustionComp then 
        tickCombustionComp(configurations.AttackDamage);
    end;

    return true;
end

function treePackage.FollowEnemy(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    npcClass.Move:Follow(enemyNpcClass.RootPart);    
end

function treePackage.Idle(npcClass: NpcClass)
    return false;
end

return treePackage;