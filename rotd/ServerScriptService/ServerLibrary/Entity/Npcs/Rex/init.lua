local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Rex";
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
        Pitch = 0.7;
        Speed = 0.95;
        PlaybackSpeed = 0.99;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;