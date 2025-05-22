local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="Well?";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	--== Lvl0
	["shelter_new"]={
		Face="Skeptical"; 
		Reply="Hmm, this place needs improvement.";
	};
	
	--== Lvl1 
	["shelter_lvl1_init"]={
		Face="Frustrated"; 
		Reply="Ugh, this bloody hurts.";
	};
	
	["shelter_lvl1_choice1"]={
		Face="Worried"; 
		Say="What do you need for your injuries?";
		Reply="2 medkits, make it quick.";
	};
	["shelter_lvl1_a"]={
		Face="Joyful"; 
		Say="Here you go. *give 2 medkits*.";
		Reply="There we go.. Much better.";
	};
	["shelter_lvl1_b"]={
		Face="Worried"; 
		Say="Ok, wait here.";
		Reply="Hurry.";
	};
	
	
	--== Lvl2
	["shelter_lvl2_init"]={
		Face="Welp"; 
		Reply="Hmmm, I don't like to be watched while I'm doing this..";
	};
	["shelter_lvl2_choice1"]={
		Face="Happy"; 
		Say="How are you feeling?";
		Reply="Never better.. Still need to rest though.";
	};
	
	
	--== Lvl3
	["shelter_lvl3_init"]={
		Face="Smirk"; 
		Reply="I'm hungry, $PlayerName, where's the food?";
	};
	["shelter_lvl3_choice1"]={
		Face="Surprise"; 
		Say="There's a freezer where we keep our food. One person can take one per day.";
		Reply="Good! People better follow the rules.";
	};
	["shelter_lvl3_choice2"]={
		Face="Happy"; 
		Say="Hey, what's your job before the apocalypse?";
		Reply="I lived in the cabins near a camp site on mount Lottarocks, people come to be for help if they get injuired during their camp.";
	};
	
	
	--== Lvl4
	["shelter_lvl4_init"]={
		Face="Confident"; 
		Reply="$PlayerName, I need something to do.";
	};
	["shelter_lvl4_choice1"]={
		Face="Serious"; 
		Say="Could you be our medic?";
		Reply="Alright.";
	};
	["shelter_lvl4_choice2"]={
		Face="Confident"; 
		Say="How are you feeling?";
		Reply="Like I resurrected.";
	};
	
	
	--== Medic
	["shelter_medic"]={
		Face="Skeptical";
		Say="Can you heal me?";
		Reply="Here *heals*, do you need me to watch your back out there?";
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