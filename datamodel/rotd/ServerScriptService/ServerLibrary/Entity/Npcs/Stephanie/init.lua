local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

local npcPackage = {
    Name = "Stephanie";
    HumanoidType = "Human";
    
	Configurations = {};
    Properties = {};

    DialogueInteractable = true;

    AddComponents = {
        "TargetHandler";
        "Chat";
    };

    Voice = {
        VoiceId = 2;
        Pitch = -3;
        Speed = 1;
        PlaybackSpeed = 1;
    };

    IdleRandomChat = {
		"Ropes.. check. Ammunition.. check. Guns.. oh..";
		"Hmmm.. should I check the shelves again..? nah.";
		"Maybe this would work.. oh wait, no...";
		"Mixing sulfur with the.. hmm.. Maybe that's not a good idea..";
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
    if modBranchConfigs.IsWorld("TheWarehouse") then
        
    end
end

return npcPackage;