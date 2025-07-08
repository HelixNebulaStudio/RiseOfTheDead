local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Carlos";
    HumanoidType = "Human";
    
	Configurations = {};
    Properties = {};

    DialogueInteractable = true;

    AddComponents = {
        "TargetHandler";
        "Chat";
    };

    Voice = {
        VoiceId = 5;
        Pitch = 2;
        Speed = 1;
        PlaybackSpeed = 0.96;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;