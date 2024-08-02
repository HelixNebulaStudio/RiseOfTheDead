local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="Hey";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	--== Lvl0
	["shelter_new"]={
		Face="Worried";
		Reply="Pretty cosy place.";
	};
	
	--== Lvl1 
	["shelter_lvl1_init"]={
		Face="Skeptical"; 
		Reply="This pain ain't going away for a while..";
	};
	
	["shelter_lvl1_choice1"]={
		Face="Worried"; 
		Say="What do you need for your injuries?";
		Reply="Hmmm, 2 medkits, *sigh*, this is going to take a while to heal.";
	};
	["shelter_lvl1_a"]={
		Face="Joyful"; 
		Say="Here you go. *give 2 medkits*.";
		Reply="Thanks, I'll patch up my arm and let it heal..";
	};
	["shelter_lvl1_b"]={
		Face="Worried"; 
		Say="Ok, wait here.";
		Reply="Okay.";
	};
	
	
	--== Lvl2
	["shelter_lvl2_init"]={
		Face="Welp"; 
		Reply="*healing* ...";
	};
	["shelter_lvl2_choice1"]={
		Face="Skeptical"; 
		Say="How are you feeling?";
		Reply="Still hurts, I can't heal that quick.";
	};
	
	
	--== Lvl3
	["shelter_lvl3_init"]={
		Face="Welp"; 
		Reply="$PlayerName, is there any food around here?";
	};
	["shelter_lvl3_choice1"]={
		Face="Surprise"; 
		Say="There's a freezer where we keep our food. One person can take one per day.";
		Reply="Hmmm, one per person.. Okay, thanks.";
	};
	["shelter_lvl3_choice2"]={
		Face="Happy"; 
		Say="Hey, what's your job before the apocalypse?";
		Reply="Oh, I was a doctor.";
	};
	
	
	--== Lvl4
	["shelter_lvl4_init"]={
		Face="Happy"; 
		Reply="$PlayerName, got anything for me to do here?";
	};
	["shelter_lvl4_choice1"]={
		Face="Smirk"; 
		Say="Could you be our medic?";
		Reply="Alright.";
	};
	["shelter_lvl4_choice2"]={
		Face="Confident"; 
		Say="How are you feeling?";
		Reply="The pain is bearly noticable now.";
	};
	
	
	--== Medic
	["shelter_medic"]={
		Face="Welp"; 
		Say="Can you heal me?";
		Reply="Again?";
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