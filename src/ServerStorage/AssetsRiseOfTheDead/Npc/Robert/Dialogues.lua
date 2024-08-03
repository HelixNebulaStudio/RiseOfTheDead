local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="Thanks again, dude.";
	};
	["init2"]={
		Reply="I feel so much better now.";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	["general_salads"]={
		Face="Hehe";
		Say="How do you make your salads?";
		Reply="2 purple lemons and boiled bloxy cola.";
	};
	["general_funny"]={
		Face="Oops";
		Say="You're funny.";
		Reply="No you.";
	};
};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		dialog:AddChoice("general_salads");
		dialog:AddChoice("general_funny");
	end 
end

return Dialogues;