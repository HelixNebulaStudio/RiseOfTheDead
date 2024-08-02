local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

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
		local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
		local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
		local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
		
		dialog:AddChoice("heal_request", function(dialog)
			if not dialog.InRange() then return end;
			modStatusEffects.FullHeal(player);
			modOnGameEvents:Fire("OnMedicHeal", player, dialog.Name);
	
		end)
		
		if modMission:IsComplete(player, 2) then
			dialog:AddChoice("general_cost");
			dialog:AddChoice("general_background");
			dialog:AddChoice("general_teachMe");
		end
	end 
end

return Dialogues;