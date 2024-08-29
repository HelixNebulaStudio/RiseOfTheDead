local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="...";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
	end

	-- MARK: EquipmentDialogueHandler
	Dialogues.EquipmentDialogueHandler = function(player, dialog, data)
	end
	
end

return Dialogues;