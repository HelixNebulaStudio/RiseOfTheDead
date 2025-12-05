local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Jefferson";
    HumanoidType = "Human";
    
	Configurations = {};
    Properties = {};

    DialogueInteractable = true;

    AddComponents = {
        "TargetHandler";
        "Chat";
    };

    Voice = {
        VoiceId = 3;
        Pitch = -10;
        Speed = 1.5;
        PlaybackSpeed = 0.95;
    };
};

function npcPackage.Spawned(npcClass: NpcClass)
    npcClass.PlayAnimation("Wounded");
end

return npcPackage;