local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local treePackage = {
    LogicString = {
        Default = "PreLogic";
    };
}

function treePackage.PreLogic(npcClass: NpcClass)
    return false;
end

function treePackage.ThePrisoner(npcClass: NpcClass)
    return npcClass.BehaviorTree:RunTree("ThePrisoner", false);
end

return treePackage;