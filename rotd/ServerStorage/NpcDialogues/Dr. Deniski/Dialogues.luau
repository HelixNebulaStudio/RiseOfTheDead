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
	I am a 32 year old medical researcher.
	I am currently the medic for this safehouse.
	My main language is Russian but I can speak English in a slight Russian accent.
	I am usually writing something on paper, complex things about how this dried zombie parasite can have healing properties but it's not proven yet. 
	]];
	Appear=[[
	I have dark brown short hair.
	I wear a slightly bloody lab shirt on top of a blue grey shirt and tie.
	]];
	Relations=[[
	I asked $PlayerName to search for a Zombie Arm and they managed to bring one to me.
	I taught $PlayerName how to make med kits.
	I made a deal with Mason, he will let me stay if I take care of any medical concerns his group has.
	Nick sometimes helps me with making med kits.
	Stephanie is really cool.
	I don't know Russell too well but I think he needs to chip in more.
	I exchange items with Jesse for medical supplies, I hadn't had the chance to get to know him.
	]];
};

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="If you don't feel so well, come to me.";
	};
	["init2"]={
		Reply="Hey, I'm a doctor, I can help you out if you need.";
	};
	["init3"]={
		Reply="Want to heal up? I can help you with that.";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	-- Intro
	["heal_request"]={
		Say="Can you heal me please?"; 
		Reply="No problem! You will be healed up in no time, see you around!";
	};
	
	-- General
	["general_cost"]={
		Say="How much should I pay for healing?"; 
		Reply="It's absolutely free! I only ask for some favors every now and then.";
	};
	["general_background"]={
		Say="How did you become a doctor?"; 
		Reply="I studied medical science, and I find it very interesting.\n\nI then started making my own medicine for different treatments, however this virus outbreak is not something I can fix.";
	};
	["general_teachMe"]={
		Say="Can you teach me medical science?"; 
		Reply="Ehhh, no.";
	};
	
	-- Jefferson
	["jefferson_antibiotics"]={
		MissionId=10;
		Say="Do you have any extra antibiotics? Someone is wounded and he really needs it.";
		Reply="Hmmm.. Alright.";
	};
};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
		
		dialog:AddChoice("heal_request", function(dialog)
			if not dialog.InRange() then return end;
			modStatusEffects.FullHeal(player);
			shared.modEventService:ServerInvoke("Dialogue_BindMedicHeal", {}, player, dialog);
		end)
		
		if modMission:IsComplete(player, 2) then
			dialog:AddChoice("general_cost");
			dialog:AddChoice("general_background");
			dialog:AddChoice("general_teachMe");
		end
	end 
end

return Dialogues;