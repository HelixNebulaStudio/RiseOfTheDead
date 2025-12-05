local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Lydia";
    HumanoidType = "Human";
    
	Configurations = {};
    Properties = {
        Immortal = 1;
    };

    DialogueInteractable = true;

    AddComponents = {
        "TargetHandler";
        "Chat";
        "ProtectPlayer";
        "FollowPlayer";
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;