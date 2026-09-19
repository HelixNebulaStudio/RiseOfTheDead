local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Eugene";
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
        VoiceId = 7;
        Pitch = 0.85;
        Speed = 1.05;
        PlaybackSpeed = 1.05;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;