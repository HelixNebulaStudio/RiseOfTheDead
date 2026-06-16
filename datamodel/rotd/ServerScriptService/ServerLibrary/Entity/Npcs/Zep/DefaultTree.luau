local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local treePackage = {
    LogicString = {
        Default = "SurvivorCombatTree | CutsceneTree | [NpcRoutine]";
    };
}

function treePackage.SurvivorCombatTree(npcClass: NpcClass)
    return npcClass.BehaviorTree:RunTree("SurvivorCombatTree", false);
end

function treePackage.CutsceneTree(npcClass: NpcClass)
    local isInCutscene = npcClass.BehaviorTree:RunTree("CutsceneTree", false);
    return isInCutscene;
end

function treePackage.NpcRoutine(npcClass: NpcClass)
    return npcClass:GetComponent("NpcRoutine"):Process();
end

function treePackage.Idle()

end

return treePackage;