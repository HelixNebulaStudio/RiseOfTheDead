local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Lewis";
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
        VoiceId = 1;
        Pitch = -1;
        Speed = 0.97;
        PlaybackSpeed = 1.02;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;