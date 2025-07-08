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

    Voice = {
        VoiceId = 3;
        Pitch = -4;
        Speed = 1.4;
        PlaybackSpeed = 0.95;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)

    -- if game:GetService("RunService"):IsStudio() then
    --     local protectOwnerComp = npcClass:GetComponent("ProtectOwner");
    --     protectOwnerComp:Activate();
    -- end
end

return npcPackage;