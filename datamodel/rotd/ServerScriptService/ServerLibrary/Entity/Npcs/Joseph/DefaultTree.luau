local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

local treePackage = {
    LogicString = {
        Default = "SurvivorCombatTree | CutsceneTree | [NpcRoutine]";
    };
}

function treePackage.SurvivorCombatTree(npcClass: NpcClass)
    local canCombat = true;

    if npcClass.Player then
        local mission = modMission:GetMission(npcClass.Player, 52);
        if mission and (mission.Type == 3 or mission.ProgressionPoint >= 10) then
            canCombat = false;
        end
    end
    npcClass.Properties.CanCombat = canCombat;

    return npcClass.BehaviorTree:RunTree("SurvivorCombatTree", false);
end

function treePackage.CutsceneTree(npcClass: NpcClass)
    return npcClass.BehaviorTree:RunTree("CutsceneTree", false);
end

function treePackage.NpcRoutine(npcClass: NpcClass)
    return npcClass:GetComponent("NpcRoutine"):Process();
end

function treePackage.Idle()

end

return treePackage;