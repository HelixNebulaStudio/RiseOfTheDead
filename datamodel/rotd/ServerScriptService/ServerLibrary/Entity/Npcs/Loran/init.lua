local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Vladimir";
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
        VoiceId = 2;
        Pitch = -5;
        Speed = 0.8;
        PlaybackSpeed = 1.1;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;