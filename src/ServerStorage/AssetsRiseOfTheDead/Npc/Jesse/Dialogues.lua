local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="Why buy tomorrow when you can buy today!";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	["aGoodDeal_questions"]={
		Say="Hey, this is the first time you are outside the shop!"; 
		Reply="Yes, I wanted to take a breath of the fresh air..";
	};
	["aGoodDeal_org"]={
		Say="Who do you work for?"; 
		Reply="R.A.T., now stop asking..";
	};
	["aGoodDeal_why"]={
		Say="Why are you working in this apocalypse?"; 
		Reply="I work for them and they protect me alright? I'm not going to answer anymore questions.";
	};

};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	-- Dialogues.DialogueHandler = function(player, dialog, data)
	-- end 
end

return Dialogues;