local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Skinner";
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
        VoiceId = 201;
        Pitch = 0.9;
        Speed = 0.95;
        PlaybackSpeed = 0.99;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;