local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Nick";
    HumanoidType = "Human";
    
	Configurations = {};
    Properties = {
        Immortal = 1;
    };

    DialogueInteractable = true;

    AddComponents = {
        "TargetHandler";
        "Chat";
    };

    Voice = {
        VoiceId = 5;
        Pitch = 0.95;
        Speed = 1;
        PlaybackSpeed = 1.05;
    };

    IdleRandomChat = {
		"When will there be rescue?!";
		"Hope there's a rescue team out there...";
		"I want to put a bullet in every zombie!";
		"Never thought that this could ever happen...";
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;