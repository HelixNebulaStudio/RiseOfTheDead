local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local treePackage = {
    LogicString = {
        Default = "(HasEnemy & MissionCheck) | (!InCutscene & SurvivorCombatTree) | [Idle]";
    };
};

function treePackage.HasEnemy(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local enemyTargetData = properties.EnemyTargetData;

    return enemyTargetData ~= nil;
end

function treePackage.InCutscene(npcClass: NpcClass)
    return npcClass.Properties.CutsceneActive == true;
end

function treePackage.MissionCheck(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local enemyTargetData = properties.EnemyTargetData;

    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;
    local enemyStatusComp: StatusComp = enemyNpcClass.StatusComp;

    return false;
end

function treePackage.SurvivorCombatTree(npcClass: NpcClass)
    return npcClass.BehaviorTree:RunTree("SurvivorCombatTree", false);
end

function treePackage.Idle(npcClass: NpcClass)
    local spawnPos = npcClass.SpawnCFrame.Position;
    if shared.WorldName == "TheMall" then
        if not npcClass.Move:IsAtPosition(spawnPos) then
            npcClass.Move:MoveTo(spawnPos);
        end
    end
end

return treePackage;