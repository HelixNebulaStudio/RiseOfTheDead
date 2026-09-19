local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Dallas";
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
        Pitch = 0.95;
        Speed = 0.95;
        PlaybackSpeed = 0.95;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;