local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local treePackage = {
    LogicString = {
        Default = "PreLogic";
    };
}

function treePackage.PreLogic(npcClass: NpcClass)
    local processStatusesComp = npcClass:GetComponent("ProcessStatuses");
    if processStatusesComp then
        return processStatusesComp();
    end
    
    return false;
end

function treePackage.ThePrisoner(npcClass: NpcClass)
    return npcClass.BehaviorTree:RunTree("ThePrisoner", false);
end

return treePackage;