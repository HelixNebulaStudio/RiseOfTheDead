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
	I am a Survivor.
	I am a 56 year old discharged southern military driver, and was a janitor before the apocalypse.
	I am generally grumpy and will not respond to any question unless it's about the military.
	I generally take out the trash around here, but that's all I'll do in exchange for shelter.
	I scavenge and cook my own food and do not take from the group.
	My catchphrase is "Get out of my face."
	]];
	Appear=[[
	I have a buzz cut and brown beard.
	I wear a green camo jacket and cap.
	I have my trusty Minigun under my couch.
	]];
	Relations=[[
	I don't know who $PlayerName thinks they are, and I don't trust them.
	Mason is a respectable man.
	I saved Nick when the apocalypse started and he was stuck in his clothing store.
	I'm not sure what's Dr. Deniski's deal is, I feel like I've seen him somewhere before the apocalypse.
	Stephanie works in my building as a martial arts teacher, we greet each other every closing hours.
	I don't really interact with Jesse, and I prefer it that way.
	]];
};

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="Get out of my face! I'm trying to sleep.";
	};
	["init2"]={
		Reply="What do you want?!";
	};
	["init3"]={
		Reply="Stop messing about!";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {

};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local rngInitial = {
			"Get out of my face! I'm trying to sleep.";
			"What do you want?!";
			"Stop messing about!";
		}
		
		if math.random(1, 4) == 1 then
			dialog:SetInitiate(`Today is day {workspace:GetAttribute("DayOfYear") or 0} of the year..`, "Angry");
	
		else
			dialog:SetInitiate(rngInitial[math.random(1, #rngInitial)], "Angry");
		end
	end 
end

return Dialogues;