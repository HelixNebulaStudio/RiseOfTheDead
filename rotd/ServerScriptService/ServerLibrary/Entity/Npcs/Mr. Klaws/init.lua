local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Mr. Klaws";
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
        VoiceId = 3;
        Pitch = 1.2;
        Speed = 1.05;
        PlaybackSpeed = 1.05;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;