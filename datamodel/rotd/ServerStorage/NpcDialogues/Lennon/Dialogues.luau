local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="People say nothing is impossible, but I do nothing every day.";
	};
	["init2"]={
		Reply="To be sure of hitting the target, shoot first, and call whatever you hit the target.";
	};
	["init3"]={
		Reply="If you’re going to tell people the truth, be funny or they’ll kill you.";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	["heal_request"]={
		Face="Joyful";
		Say="I'm hurt, can you help me?";
		Reply="Why, of course!";
	};
	
};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
		local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
		local modOnGameEvents = shared.require(game.ServerScriptService.ServerLibrary.OnGameEvents);

		if not modBranchConfigs.IsWorld("TheUnderground") then return end;
	
		dialog:AddChoice("heal_request", function()
			if not dialog.InRange() then return end;
			modStatusEffects.FullHeal(player);
			modOnGameEvents:Fire("OnMedicHeal", player, dialog.Name);
		end)
		
	end 
end

return Dialogues;