local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Mason";
    HumanoidType = "Human";
    
	Configurations = {};
    Properties = {};

    DialogueInteractable = true;

    AddComponents = {
        "TargetHandler";
        "ProtectOwner";
        "Chat";
    };
};

function npcPackage.Spawning(npcClass: NpcClass)

    -- if game:GetService("RunService"):IsStudio() then
    --     local protectOwnerComp = npcClass:GetComponent("ProtectOwner");
    --     protectOwnerComp:Activate();
    -- end
end

return npcPackage;