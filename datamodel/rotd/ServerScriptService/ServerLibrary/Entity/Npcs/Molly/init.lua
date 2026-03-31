local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Molly";
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
        VoiceId = 8;
        Pitch = 1;
        Speed = 1;
        PlaybackSpeed = 1;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;