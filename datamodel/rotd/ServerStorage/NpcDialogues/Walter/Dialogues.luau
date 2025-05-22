local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="Gas Concentration Meter readings appears to be slowly increasing...";
	};
	["init2"]={
		Reply="This place smells like death. Lots of it.";
	};
	["init3"]={
		Reply="Zombie density appears to be growing..";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {

};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	-- Dialogues.DialogueHandler = function(player, dialog, data)
	-- end 
end

return Dialogues;