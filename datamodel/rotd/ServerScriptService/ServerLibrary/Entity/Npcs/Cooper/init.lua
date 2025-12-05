local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Cooper";
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
        VoiceId = 5;
        Pitch = -2;
        Speed = 0.98;
        PlaybackSpeed = 0.98;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;