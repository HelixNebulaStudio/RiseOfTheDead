local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Rachel";
    HumanoidType = "Human";
    
	Configurations = {};
    Properties = {
        Immortal = 1;
    };

    DialogueInteractable = true;

    AddComponents = {
        "TargetHandler";
        "Chat";
        --SafehomeSurvivor;
    };

    Voice = {
        VoiceId = 6;
        Pitch = 0.95;
        Speed = 0.95;
        PlaybackSpeed = 0.95;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;