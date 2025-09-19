local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Lennon";
    HumanoidType = "Human";
    
	Configurations = {};
    Properties = {
        PrimaryGunItemId = "cz75";
        MeleeItemId = "broomspear";
        Immortal = 1;
    };

    DialogueInteractable = true;

    AddComponents = {
        "TargetHandler";
        "Chat";
    };

    Voice = {
        VoiceId = 3;
        Pitch = 0.85;
        Speed = 1;
        PlaybackSpeed = 1.05;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;