local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local treePackage = {
    LogicString = {
        Default = "SurvivorCombatTree | CutsceneTree | [Idle]";
    };
}

function treePackage.SurvivorCombatTree(npcClass: NpcClass)
    return npcClass.BehaviorTree:RunTree("SurvivorCombatTree", false);
end

function treePackage.CutsceneTree(npcClass: NpcClass)
    return npcClass.BehaviorTree:RunTree("CutsceneTree", false);
end

function treePackage.Idle()
end

return treePackage;