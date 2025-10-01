local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Stan";
    HumanoidType = "Human";
    
	Configurations = {};
    Properties = {
        Immortal = 1;
    };

    DialogueInteractable = true;

    AddComponents = {
        "TargetHandler";
        "Chat";
        "WaitForPlayer";
        "FollowPlayer";
        "AttractNpcs";
        "ProtectPlayer";
    };

    Voice = {
        VoiceId = 3;
        Pitch = 0.8;
        Speed = 0.85;
        PlaybackSpeed = 1.03;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;