local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply=".. Hey";
	};
	["init2"]={
		Reply="*cough* *cough*";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	--== Lvl0
	["shelter_new"]={Face="Confident"; Reply="This place will do..";};
	
	--== Lvl1 
	["shelter_lvl1_init"]={
		Face="Skeptical"; 
		Reply="Alright, let's cut to the chase. I'm going to need some items to start recycling..";
	};
	
	["shelter_lvl1_choice1"]={
		Face="Suspicious"; 
		Say="What are you looking for?";
		Reply="Let's go with 2 gears first.";
	};
	["shelter_lvl1_a"]={
		Face="Joyful"; 
		Say="Here you go. *give 2 gears*.";
		Reply="Thanks, I'll get to work..";
	};
	["shelter_lvl1_b"]={
		Face="Welp"; 
		Say="I'll go get some gears.";
		Reply="Very well.";
	};
	
	
	--== Lvl2
	["shelter_lvl2_init"]={
		Face="Yeesh"; 
		Reply="*tinkering* ...";
	};
	["shelter_lvl2_choice1"]={
		Face="Question"; 
		Say="How's it going?";
		Reply="Almost done..";
	};
	
	
	--== Lvl3
	["shelter_lvl3_init"]={
		Face="Welp"; 
		Reply="*cleans hand with cloth* Okay, going to need another thing..";
	};
	["shelter_lvl3_choice1"]={
		Face="Surprise";
		Say="What's that?";
		Reply="4 steel fragments, pronto.";
	};
	["shelter_lvl3_choice1_a"]={
		Face="Welp"; 
		Say="Here you go. *give steel fragments*.";
		Reply="Great, thanks!";
	};
	["shelter_lvl3_choice2"]={
		Face="Happy"; 
		Say="Soo, what is recycling?";
		Reply="Oh, just give me some of you unwanted items, if they are recyclable, I could exchange something for them..";
	};
	
	
	--== Lvl4
	["shelter_lvl4_init"]={
		Face="Happy"; 
		Reply="$PlayerName, all right. It's all done, now where can I get some food?";
	};
	["shelter_lvl4_choice1"]={
		Face="Smirk"; 
		Say="There's a freezer where we keep our food. One person can take one per day.";
		Reply="Oh, alright.";
	};
	
	["shelter_lvl4_choice2"]={
		Face="Serious"; 
		Say="Can I ask how does recycling actually work?";
		Reply="Well, if I told you, I would be out of a job, wouldn't I.";
	};
	
	--== Recycle
	["shelter_recycle"]={
		Face="Smirk"; 
		Say="I want to recycle some stuff.";
		Reply="Let's see what you got.";
	};
		
};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local survivorDialogueHandler = shared.require(script.Parent.Parent.Survivor);
		survivorDialogueHandler(player, dialog, data);
	end 
end

return Dialogues;