local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Zark";
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
        Pitch = -7;
        Speed = 0.8;
        PlaybackSpeed = 1.2;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;