local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Nate";
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
        VoiceId = 3;
        Pitch = -1;
        Speed = 0.95;
        PlaybackSpeed = 0.95;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;