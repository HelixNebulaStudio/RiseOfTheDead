local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="Sup!";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	--== Lvl0
	["shelter_new"]={
		Face="Worried"; 
		Reply="Cool place!";
	};
	
	--== Lvl1 
	["shelter_lvl1_init"]={
		Face="Skeptical"; 
		Reply="Oof, this hurts.";
	};
	
	["shelter_lvl1_choice1"]={
		Face="Worried"; 
		Say="What do you need for your injuries?";
		Reply="I'll probably need 2 medkits.";
	};
	["shelter_lvl1_a"]={
		Face="Joyful"; 
		Say="Here you go. *give 2 medkits*.";
		Reply="Thanks, that should do it.";
	};
	["shelter_lvl1_b"]={
		Face="Worried"; 
		Say="Ok, wait here.";
		Reply="Sure.";
	};
	
	
	--== Lvl2
	["shelter_lvl2_init"]={
		Face="Welp"; 
		Reply="A bandage here.. A bandage there..";
	};
	["shelter_lvl2_choice1"]={
		Face="Happy"; 
		Say="How are you feeling?";
		Reply="The pain is much more bearable, thanks for asking."
	};
	
	
	--== Lvl3
	["shelter_lvl3_init"]={
		Face="Smile"; 
		Reply="Sooo, $PlayerName, where can I get food around here?";
	};
	["shelter_lvl3_choice1"]={
		Face="Surprise"; 
		Say="There's a freezer where we keep our food. One person can take one per day.";
		Reply="Oh okay, thanks!"
	};
	["shelter_lvl3_choice2"]={
		Face="Happy"; 
		Say="Hey, what's your job before the apocalypse?";
		Reply="Oh, I was a veterinarian."
	};
	
	
	--== Lvl4
	["shelter_lvl4_init"]={
		Face="Happy"; 
		Reply="$PlayerName, is there anything I could do here?";
		};
	["shelter_lvl4_choice1"]={
		Face="Oops"; 
		Say="Could you be our medic?";
		Reply="Sure!"
	};
	["shelter_lvl4_choice2"]={
		Face="Confident"; 
		Say="How are you feeling?";
		Reply="Much better, thanks for asking."
	};
	
	
	--== Medic
	["shelter_medic"]={
		Face="Confident"; 
		Say="Can you heal me?";
		Reply="Patching you right up.";
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