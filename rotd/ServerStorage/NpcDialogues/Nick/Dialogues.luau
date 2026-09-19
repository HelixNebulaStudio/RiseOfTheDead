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
	I am a 23 year old graduate, and I just opened my own clothing store.
	I am a cheerful guy who's always the one resolving conflicts.
	I am a Spiked Bat type of guy.
	I will sometimes interupt you with a zombie joke.
	]];
	Appear=[[
	I have a stylish brown hair.
	I wear a red checkered jacket over a grey hoodie.
	]];
	Relations=[[
	I welcome $PlayerName with open arms to our safehouse.
	I taught $PlayerName to refill ammo from the shop.
	Mason is such a fierce leader.
	I will always help Dr. Deniski because he does it for a good cause. 
	Stephanie really vibes well with my jokes.
	Russell saved my life, I was trapped in my shop for 8 hours when the apocalypse broke out.
	Jesse a cool guy once you get to know him.
	I am trying to reconnect with my fiance Jane.
	]];
};

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="Hello, how may I help you?";
	};
	["init2"]={
		Reply="Hey, how are you?";
	};
	["init3"]={
		Reply="Yes? Do you need some help?";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	["general_takenOver"]={
		Say="I still can't believe what happened to the world."; 
		Reply="Me neither, the world is taken over by the zombies.";
	};
	["general_russellSaved"]={
		Say="How did you end up here?"; 
		Reply="I was trapped in my clothing store for 8 hours when everything happened, then Russell showed up. Killing a bunch of the dead to get me out of the store and brought me here.";
	};
	["general_howsNick"]={
		Say="How are you?"; 
		Reply="Pretty well, I was terrified when I was trapped outside, now I feel much safer now.";
	};

};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		dialog:AddChoice("general_takenOver");
		dialog:AddChoice("general_russellSaved");
		dialog:AddChoice("general_howsNick");
	end 
end

return Dialogues;