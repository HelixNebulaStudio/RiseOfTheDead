local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="O. M. G. Can't believe it's almost 3 months since this happened.";
	};
	["init2"]={
		Reply="I'm looking for a charger for my phone, has anyone seen it?";
	};
	["init3"]={
		Reply="Hey there!";
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