local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Joseph";
    HumanoidType = "Human";
    
	Configurations = {};
    Properties = {
        Immortal = 1;
    };

    DialogueInteractable = true;

    AddComponents = {
        "TargetHandler";
        "Chat";
        "AttractNpcs";
        "ProtectPlayer";
        "FollowPlayer";
        "WaitForPlayer";
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