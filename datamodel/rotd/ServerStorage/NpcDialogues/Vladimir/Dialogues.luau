local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="Buy now and no regrets!";
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