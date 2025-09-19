local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local treePackage = {
    LogicString = {
        Default = "PreLogic | ProtectPlayer | !InCutscene & SurvivorIdleTree";
    };
}

function treePackage.PreLogic(npcClass: NpcClass)
    return false;
end

function treePackage.InCutscene(npcClass: NpcClass)
    return npcClass.Properties.CutsceneActive == true;
end

function treePackage.ProtectPlayer(npcClass: NpcClass)
    if npcClass.Properties.IsProtectingPlayer == true then
        if npcClass.Properties.EnemyTargetData == nil then 
            npcClass:GetComponent("FollowPlayer")();
        end;
    end
    return false;
end

function treePackage.SurvivorIdleTree(npcClass: NpcClass)
    return npcClass.BehaviorTree:RunTree("SurvivorIdleTree", false);
end

return treePackage;