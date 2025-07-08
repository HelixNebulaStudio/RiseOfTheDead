local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Jane";
    HumanoidType = "Human";
    
	Configurations = {};
    Properties = {};

    DialogueInteractable = true;

    AddComponents = {
        "TargetHandler";
        "Chat";
    };

    Voice = {
        VoiceId = 6;
        Pitch = 3;
        Speed = 0.9;
        PlaybackSpeed = 1.1;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;