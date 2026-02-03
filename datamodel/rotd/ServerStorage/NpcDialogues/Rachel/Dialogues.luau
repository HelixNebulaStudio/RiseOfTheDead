local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="Got any medical issues?";
	};
	["init2"]={
		Reply="Try not to injure yourself out there..";
	};
	["init3"]={
		Reply="If injured, consult me immediately to prevent an infection!";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	["heal_request"]={
		Say="Can you heal me please?"; 
		Reply="Absolutely!.. Feeling much better now?";
	};
	
	
	--== Lvl0
	["shelter_new"]={
		Face="Worried"; 
		Reply="This place is not bad.";
	};
	
	--== Lvl1 
	["shelter_lvl1_init"]={
		Face="Worried"; 
		Reply="This pain is almost unbearable..";
	};
	
	["shelter_lvl1_choice1"]={
		Face="Worried"; 
		Say="What do you need for your injuries?";
		Reply="I will just need 2 medkits. That should be enough.";
	};
	["shelter_lvl1_a"]={
		Face="Joyful"; 
		Say="Here you go. *give 2 medkits*.";
		Reply="Thank you, that should help it.";
	};
	["shelter_lvl1_b"]={
		Face="Worried"; 
		Say="Ok, wait here.";
		Reply="Alright.";
	};
	
	
	--== Lvl2
	["shelter_lvl2_init"]={
		Face="Welp"; 
		Reply="Alright, same procedure.. *healing*";
	};
	["shelter_lvl2_choice1"]={
		Face="Happy"; 
		Say="How are you feeling?";
		Reply="Better, I think I will be better in a couple days.";
	};
	
	
	--== Lvl3
	["shelter_lvl3_init"]={
		Face="Smile"; 
		Reply="$PlayerName, how does the food supply work here?";
	};
	["shelter_lvl3_choice1"]={
		Face="Surprise"; 
		Say="There's a freezer where we keep our food. One person can take one per day.";
		Reply="I see, well planned!";
	};
	["shelter_lvl3_choice2"]={
		Face="Happy"; 
		Say="Hey, what's your job before the apocalypse?";
		Reply="Silly, you know I'm a nurse..";
	};
	
	
	--== Lvl4
	["shelter_lvl4_init"]={
		Face="Happy"; 
		Reply="$PlayerName, do you need any roles to be filled?";
	};
	["shelter_lvl4_choice1"]={
		Face="Excited"; 
		Say="Could you be our medic?";
		Reply="Definitely.";
	};
	["shelter_lvl4_choice2"]={
		Face="Confident"; 
		Say="How are you feeling?";
		Reply="Definitely better.";
	};
	
	
	--== Medic
	["shelter_medic"]={
		Face="Happy"; 
		Say="Can you heal me?";
		Reply="Here you go..";
	};
};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
		local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

		if modBranchConfigs.IsWorld("Safehome") then
			local survivorDialogueHandler = shared.require(script.Parent.Parent.Survivor);
			survivorDialogueHandler(player, dialog, data);
			
		else
			dialog:AddChoice("heal_request", function()
				if not dialog.InRange() then return end;
				modStatusEffects.FullHeal(player, 0.15);
	
				shared.modEventService:ServerInvoke("Dialogue_BindMedicHeal", {}, player, dialog);
			end)
		
		end
		
	end
end

return Dialogues;