local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Dr. Deniski";
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
        Pitch = -3;
        Speed = 0.9;
        PlaybackSpeed = 0.9;
    };

    IdleRandomChat = {
		"Only if there's some way I can help..";
		"Невероятно!";
		"я скучаю по дому..";
		"We may be running out of supplies..";
		"I wonder how is it in mother Russia..";
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;