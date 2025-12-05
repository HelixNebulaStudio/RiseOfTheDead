local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Bunny Man";
    HumanoidType = "Human";
    
	Configurations = {};
    Properties = {
        Immortal = 1;
    };

    DialogueInteractable = true;

    AddComponents = {
        "TargetHandler";
        "Chat";
        "ProtectPlayer";
        "FollowPlayer";
        "WaitForPlayer";
    };

    Voice = {
        VoiceId = 3;
        Pitch = -5;
        Speed = 1.5;
        PlaybackSpeed = 1.4;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;