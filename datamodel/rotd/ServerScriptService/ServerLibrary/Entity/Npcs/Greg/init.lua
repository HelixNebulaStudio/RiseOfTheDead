local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Greg";
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
        VoiceId = 71;
        Pitch = -2;
        Speed = 0.7;
        PlaybackSpeed = 0.95;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;