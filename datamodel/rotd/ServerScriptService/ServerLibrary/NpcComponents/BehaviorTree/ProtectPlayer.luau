local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local treePackage = {
    LogicString = {
        Default = "ProtectPlayer & [SurvivorCombatTree]";
    };
}

function treePackage.ProtectPlayer(npcClass: NpcClass)
    if npcClass.Properties.IsProtectingPlayer == true then
        if npcClass.Properties.EnemyTargetData == nil then 
            npcClass.BehaviorTree:RunTree("FollowPlayer", false);
        end;
    end
    return false;
end

function treePackage.SurvivorCombatTree(npcClass: NpcClass)
    return npcClass.BehaviorTree:RunTree("SurvivorCombatTree", false);
end

return treePackage;