local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Wilson";
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
        Pitch = 1;
        Speed = 1;
        PlaybackSpeed = 1;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
    npcClass.WieldComp:Equip{ ItemId = "walkietalkie" };
    --npcClass.WieldComp:InvokeToolAction("PrimaryFireRequest", true);
end

return npcPackage;