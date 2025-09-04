local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "The Prisoner2";
    CharacterPrefabName = "The Prisoner";
    HumanoidType = "Zombie";
    
	Configurations = {};
    Properties = {};

    DialogueInteractable = true;

    AddComponents = {
        "TargetHandler";
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
end

return npcPackage;