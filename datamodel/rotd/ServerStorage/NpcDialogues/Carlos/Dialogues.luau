local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="Want to hear me play the flute?";
	};
	["init2"]={
		Reply="I really like to play the flute, want to hear?";
	};
	["init3"]={
		Reply="I can play the flute if you want.";
	};
	["init4"]={
		Reply="The noise from that vent up there is really distracting...";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	["heal_request"]={
		Say="Can you heal me please?";
		Reply="Let me heal you with the sound of music!";
	};
};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
		local modOnGameEvents = shared.require(game.ServerScriptService.ServerLibrary.OnGameEvents);
		
		dialog:AddChoice("heal_request", function()
			if not dialog.InRange() then return end;
			modStatusEffects.FullHeal(player);
			modOnGameEvents:Fire("OnMedicHeal", player, dialog.Name);
		end)
	end 
end

return Dialogues;