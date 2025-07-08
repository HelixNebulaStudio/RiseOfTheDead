local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Michael";
    HumanoidType = "Human";
    
	Configurations = {};
    Properties = {};

    DialogueInteractable = true;

    AddComponents = {
        "TargetHandler";
        "Chat";
    };

    Voice = {
        VoiceId = 7;
        Pitch = -4;
        Speed = 1.2;
        PlaybackSpeed = 0.9;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;