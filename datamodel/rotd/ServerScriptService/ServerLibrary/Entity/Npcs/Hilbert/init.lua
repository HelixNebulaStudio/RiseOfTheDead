local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Hilbert";
    HumanoidType = "Human";
    
	Configurations = {};
    Properties = {
        Immortal = 1;
    };

    DialogueInteractable = true;

    AddComponents = {
        "TargetHandler";
        "Chat";
    };

    Voice = {
        VoiceId = 3;
        Pitch = 1.0;
        Speed = 1.0;
        PlaybackSpeed = 1.0;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
    npcClass.PlayAnimation("Unconscious");
end

return npcPackage;