local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local treePackage = {
    LogicString = {
        Default = "PreLogic | !InCutscene & Idle";
    };
}

function treePackage.PreLogic(npcClass: NpcClass)
    return false;
end

function treePackage.InCutscene(npcClass: NpcClass)
    return npcClass.Properties.CutsceneActive == true;
end

function treePackage.Idle(npcClass: NpcClass)
    return false;
end

return treePackage;