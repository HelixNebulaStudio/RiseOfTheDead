local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
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
        VoiceId = NumberRange.new(1, 7);
        Pitch = NumberRange.new(-3, 2);
        Speed = NumberRange.new(0.98, 1.02);
        PlaybackSpeed = NumberRange.new(0.98, 1.02);
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;