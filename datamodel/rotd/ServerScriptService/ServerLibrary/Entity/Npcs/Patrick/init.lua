local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Patrick";
    HumanoidType = "Human";
    
	Configurations = {};
    Properties = {
        Immortal = 1;
    };

    DialogueInteractable = true;

    AddComponents = {
        "TargetHandler";
        "Chat";
        "FollowPlayer";
        "ProtectPlayer";
    };

    Voice = {
        VoiceId = 3;
        Pitch = -2;
        Speed = 1;
        PlaybackSpeed = 1.01;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;