local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Carlson";
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
        Pitch = 1.05;
        Speed = 0.95;
        PlaybackSpeed = 1.05;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;