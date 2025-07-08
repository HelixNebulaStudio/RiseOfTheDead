local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Nick";
    HumanoidType = "Human";
    
	Configurations = {};
    Properties = {};

    DialogueInteractable = true;

    AddComponents = {
        "TargetHandler";
        "Chat";
    };

    Voice = {
        VoiceId = 5;
        Pitch = 1.1;
        Speed = 1;
        PlaybackSpeed = 0.95;
    };

    IdleRandomChat = {
		"When will there be rescue?!";
		"Hope there's a rescue team out there...";
		"I want to put a bullet in every one of them!";
		"Never thought that this could ever happen...";
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;