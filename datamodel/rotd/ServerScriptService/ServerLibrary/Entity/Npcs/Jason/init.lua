local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Jason";
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
        Pitch = -3;
        Speed = 1.1;
        PlaybackSpeed = 1.1;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;