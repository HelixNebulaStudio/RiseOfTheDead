local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="Heya!";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	--== Lvl0
	["shelter_new"]={
		Face="Worried"; 
		Reply="Wow, what a place..";
	};
	
	
	--== Lvl1 
	["shelter_lvl1_init"]={
		Face="Angry"; 
		Reply="Ouch..";
	};
	
	["shelter_lvl1_choice1"]={
		Face="Worried"; 
		Say="What do you need for your injuries?";
		Reply="Hmm, I think I'll need about 2 medkits..";
	};
	["shelter_lvl1_a"]={
		Face="Joyful"; 
		Say="Here you go. *give 2 medkits*.";
		Reply="Ohh, that's just what I needed.";
	};
	["shelter_lvl1_b"]={
		Face="Worried"; 
		Say="Ok, wait here.";
		Reply="Alrighty.";
	};
	
	
	--== Lvl2
	["shelter_lvl2_init"]={
		Face="Welp"; 
		Reply="This stings..";
	};
	["shelter_lvl2_choice1"]={
		Face="Happy"; 
		Say="How are you feeling?";
		Reply="Much better, still need some time though..";
	};
	
	
	--== Lvl3
	["shelter_lvl3_init"]={
		Face="Disgusted"; 
		Reply="Hey, $PlayerName, I'm kinda hungry.";
	};
	["shelter_lvl3_choice1"]={
		Face="Surprise"; 
		Say="There's a freezer where we keep our food. One person can take one per day.";
		Reply="Ohh, okay, thank you!";
	};
	["shelter_lvl3_choice2"]={
		Face="Happy"; 
		Say="Hey, what's your job before the apocalypse?";
		Reply="Lifeguard at the W.D. Lighthouse! I do miss my job..";
	};
	
	
	--== Lvl4
	["shelter_lvl4_init"]={
		Face="Happy"; 
		Reply="$PlayerName, is there anyway I could contribute?";
	};
	["shelter_lvl4_choice1"]={
		Face="Excited"; 
		Say="Could you be our medic?";
		Reply="Absolutely!";
	};
	["shelter_lvl4_choice2"]={
		Face="Confident"; 
		Say="How are you feeling?";
		Reply="I feel like brand new!";
	};
	
	
	--== Medic
	["shelter_medic"]={
		Face="Excited"; 
		Say="Can you heal me?";
		Reply="Of course!.";
	};
};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local survivorDialogueHandler = require(script.Parent.Parent.Survivor);
		survivorDialogueHandler(player, dialog, data);
	end 
end

return Dialogues;