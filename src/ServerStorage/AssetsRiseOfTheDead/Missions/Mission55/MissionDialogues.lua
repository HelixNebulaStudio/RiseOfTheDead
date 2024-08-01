local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local genericDialogueHandler = require(script.Parent.AnotherSurvivor);

local missionId = 55;

local Dialogues = {};
--==

-- MARK: Berry Handler
Dialogues.Berry = {
	DialogueStrings = {
		["shelter_init"]={
			Face="Confident"; 
			Reply="Hello there. I have a deal for you..\n\nYou let me open shop in your base for R.A.T. and we'll give you bonuses for doing business with us.";
		};
		["shelter_accept"]={
			Face="Smirk"; 
			Say="Sure, I'll take that deal..";
			Reply="Great! Let me get my things..";
		};
		["shelter_decline"]={
			Face="Suspicious"; 
			Say="I'm afraid we can't accept anyone at the moment.";
			Reply="Oh well..";
		};
	};
	DialogueHandler = genericDialogueHandler;
};
	
-- MARK: Jackie Handler
Dialogues.Jackie = {
	DialogueStrings = {
		["shelter_init"]={
			Face="Confident"; 
			Reply="Hi, I would like to order a number 9 large.. Haha, just kidding around, don't shoot me.. Let's make a deal..\n\nYou let me open shop in your base for R.A.T. and we'll give you bonuses for doing business with us.";
		};
		["shelter_accept"]={
			Face="Smirk"; 
			Say="Sure, I'll take that deal..";
			Reply="Hack yeah! Let me make myself at home..";
		};
		["shelter_decline"]={
			Face="Suspicious"; 
			Say="I'm afraid we can't accept anyone at the moment.";
			Reply="Alright then..";
		};
	};
	DialogueHandler = genericDialogueHandler;
};
	
-- MARK: Jackson Handler
Dialogues.Jackson = {
	DialogueStrings = {
		["shelter_init"]={
			Face="Worried"; 
			Reply="My goodness, I just got away from that thing and might have injured myself doing so. Hey, can I stay here for a bit?";
		};
		["shelter_accept"]={
			Face="Worried"; 
			Say="Sure, stay as long as you want..";
			Reply="Why thank you.";
		};
		["shelter_decline"]={
			Face="Worried"; 
			Say="I'm afraid we can't accept anyone at the moment.";
			Reply="Ah well.";
		};
	};
	DialogueHandler = genericDialogueHandler;
};
	
-- MARK: Kat Handler
Dialogues.Kat = {
	DialogueStrings = {
		["shelter_init"]={
			Face="Worried"; 
			Reply="Heeeelp!!! Yeeek!! Something was chasing me and I'm hurt, please, please let me stay here for a bit..";
		};
		["shelter_accept"]={
			Face="Worried"; 
			Say="Don't worry, you will be safe here, stay as long as you want..";
			Reply="Ohh, thank you, thank you so much!!";
		};
		["shelter_decline"]={
			Face="Surprised"; 
			Say="I'm afraid we can't accept anyone at the moment.";
			Reply="*Gasp*";
		};
	};
	DialogueHandler = genericDialogueHandler;
};
	
-- MARK: Lydia Handler
Dialogues.Lydia = {
	DialogueStrings = {
		["shelter_init"]={
			Face="Skeptical"; 
			Reply="Let me stay, and I will tell you your fortune..";
		};
		["shelter_accept"]={
			Face="Smirk"; 
			Say="Ummm, okay.";
			Reply="Very well..";
		};
		["shelter_decline"]={
			Face="Frustrated"; 
			Say="I'm afraid we can't accept anyone at the moment.";
			Reply="I see.. I hope this place will not be ill fated..";
		};
	};
	DialogueHandler = genericDialogueHandler;
};
	
-- MARK: Nicole Handler
Dialogues.Nicole = {
	DialogueStrings = {
		["shelter_init"]={
			Face="Worried"; 
			Reply="Ahhh, what was that chasing me!? God, my arm! Hey, I can't go back out there, I'm staying here.";
		};
		["shelter_accept"]={
			Face="Worried"; 
			Say="Sure, stay as long as you want..";
			Reply="Thank god.. Err, I mean thank you..";
		};
		["shelter_decline"]={
			Face="Worried"; 
			Say="I'm afraid we can't accept anyone at the moment.";
			Reply="Fine, I'll look for another place.";
		};
	};
	DialogueHandler = genericDialogueHandler;
};
	
-- MARK: Rachel Handler
Dialogues.Rachel = {
	DialogueStrings = {
		["shelter_init"]={
			Face="Worried"; 
			Reply="Hey $PlayerName.. Mind if I move into your safehouse? I don't want to stay in the train station anymore..";
		};
		["shelter_accept"]={
			Face="Worried"; 
			Say="Sure, stay as long as you want..";
			Reply="Thanks! I injuired myself on my way here, I'll need to rest for a bit.";
		};
		["shelter_decline"]={
			Face="Worried"; 
			Say="I'm afraid we can't accept anyone at the moment.";
			Reply="Oh god, where will I go...";
		};
	};
	DialogueHandler = genericDialogueHandler;
};
	
-- MARK: Scarlett Handler
Dialogues.Scarlett = {
	DialogueStrings = {
		["shelter_init"]={
			Face="Confident"; 
			Reply="Hey, looking for a recycler?";
		};
		["shelter_accept"]={
			Face="Smirk"; 
			Say="Yes, I do! Welcome to the safehome.";
			Reply="Great, straight to the point. I like it.";
		};
		["shelter_decline"]={
			Face="Suspicious"; 
			Say="I'm afraid we can't accept anyone at the moment.";
			Reply="Very well, farewell.";
		};
	};
	DialogueHandler = genericDialogueHandler;
};
	
-- MARK: Sullivan Handler
Dialogues.Sullivan = {
	DialogueStrings = {
		["shelter_init"]={
			Face="Worried"; 
			Reply="God, that stupid thing almost tore my arm off! I can't believe this but I really need to stay here for a bit.";
		};
		["shelter_accept"]={
			Face="Worried"; 
			Say="Sure, stay as long as you want..";
			Reply="That's what I like to hear.";
		};
		["shelter_decline"]={
			Face="Worried"; 
			Say="I'm afraid we can't accept anyone at the moment.";
			Reply="What! What do you mean.";
		};
	};
	DialogueHandler = genericDialogueHandler;
};
	
-- MARK: Zoey Handler
Dialogues.Zoey = {
	DialogueStrings = {
		["shelter_init"]={
			Face="Confident"; 
			Reply="Hey, nice place you got there. Let's make a deal..\n\nYou let me open shop in your base for R.A.T. and we'll give you bonuses for doing business with us.";
		};
		["shelter_accept"]={
			Face="Smirk"; 
			Say="Sure, I'll take that deal..";
			Reply="Good choice, Mr. Remington would be very pleased.";
		};
		["shelter_decline"]={
			Face="Suspicious"; 
			Say="I'm afraid we can't accept anyone at the moment.";
			Reply="Alright then..";
		};
	};
	DialogueHandler = genericDialogueHandler;
};


return Dialogues;