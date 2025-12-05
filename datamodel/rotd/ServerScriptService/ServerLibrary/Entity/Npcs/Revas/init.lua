local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Revas";
    HumanoidType = "Human";
    
	Configurations = {};
    Properties = {
        Immortal = 1;
    };

    DialogueInteractable = true;

    AddComponents = {
        "TargetHandler";
        "Chat";
        "WaitForPlayer";
    };

    Voice = {
        VoiceId = 5;
        Pitch = -6;
        Speed = 1.1;
        PlaybackSpeed = 1.1;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;