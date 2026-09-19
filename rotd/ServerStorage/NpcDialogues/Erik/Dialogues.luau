local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="Errr, hello again.";
	};
	["init2"]={
		Reply="Umm, I feel so much safer when you're here..";
	};
	["init3"]={
		Reply="The view of the sea is always so beautiful..";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	["general_hello"]={
		Say="Hello...";
		Reply="...world!";
	};
};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	-- Dialogues.DialogueHandler = function(player, dialog, data)
	-- end 
	
end

return Dialogues;