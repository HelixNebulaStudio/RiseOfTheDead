local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local treePackage = {
    LogicString = {
        Default = "(HasEnemy & MissionCheck) | SurvivorCombatTree | [Idle]";
    };
};

function treePackage.HasEnemy(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local enemyTargetData = properties.EnemyTargetData;

    return enemyTargetData ~= nil;
end

function treePackage.MissionCheck(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local enemyTargetData = properties.EnemyTargetData;

    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;
    local enemyStatusComp: StatusComp = enemyNpcClass.StatusComp;

    local entityLeashStatus: StatusClassInstance = enemyStatusComp:GetOrDefault("EntityLeash");

    if entityLeashStatus then
        if properties.LeashQuestion == nil or tick() > properties.LeashQuestion then
            properties.LeashQuestion = tick() + 5;

            local applyBy: PlayerClass = entityLeashStatus.ApplyBy :: PlayerClass;
            local player = applyBy and applyBy:GetInstance();
            if player and player.Parent ~= nil then
                local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
                local mission = modMission:Progress(player, 53);
                if mission == nil or mission.ProgressionPoint < 8 then
                    modMission:Progress(player, 53, function(mission)
                        if mission.ProgressionPoint == 6 then
                            mission.ProgressionPoint = 7;
                        end
                    end)
                end
            end
            						
            npcClass.Chat(game.Players:GetPlayers(), "Hey! What are you trying to do?!");
        end
        
        return true;
    end

    return false;
end

function treePackage.SurvivorCombatTree(npcClass: NpcClass)
    return npcClass.BehaviorTree:RunTree("SurvivorCombatTree", false);
end

function treePackage.Idle(npcClass: NpcClass)
    local spawnPos = npcClass.SpawnCFrame.Position;
    if not npcClass.Move:IsAtPosition(spawnPos) then
        npcClass.Move:Follow(spawnPos);
    end
end

return treePackage;