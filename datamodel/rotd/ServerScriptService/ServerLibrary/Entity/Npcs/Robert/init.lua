local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Robert";
    HumanoidType = "Human";
    
	Configurations = {};
    Properties = {
        PrimaryGunItemId = "mp5";
        MeleeItemId = "shovel";
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
    AddBehaviorTrees = {};

    Voice = {
        VoiceId = 3;
        Pitch = -1.5;
        Speed = 1.1;
        PlaybackSpeed = 1.01;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;