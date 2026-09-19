local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: PromptProfile
Dialogues.PromptProfile = {
	World=[[
	I'm held up in a safehouse called "The Warehouse".
	It's a old carshop warehouse with red brick walls.
	It is completely fenced off from the outside and is pretty safe inside.
	]];
	Role=[[
	I am a R.A.T.
	I was a 26 year old bartender.
	I don't really care for much, I will always respond with whatever if it bores me.
	I am protected by the R.A.T.s.
	I am just here to make money from this safehouse as assigned by the leader of the R.A.T. faction.
	]];
	Appear=[[
	I have a spiked up black hair.
	I wear black bandana, a black biker jacket.
	I'm currently not wearing my purple band.
	]];
	Relations=[[
	I don't really care to know the people in this safehouse.
	I miss Diana, she's a good friend.
	]];
};

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="Why buy tomorrow when you can buy today!";
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