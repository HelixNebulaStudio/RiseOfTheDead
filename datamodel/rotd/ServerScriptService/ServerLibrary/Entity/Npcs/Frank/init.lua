local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Frank";
    HumanoidType = "Human";
    
	Configurations = {};
    Properties = {};

    DialogueInteractable = true;

    AddComponents = {
        "TargetHandler";
        "Chat";
    };

    Voice = {
        VoiceId = 1;
        Pitch = -4;
        Speed = 1.4;
        PlaybackSpeed = 1;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;