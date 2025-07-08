local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="A can of beans a day, keeps the doctor away..";
	};
	["init2"]={
		Reply="Needda patch up?";
	};
	["init3"]={
		Reply="I was a veterinarian, I guess it's not too different from an actual doctor right..?";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	["heal_request"]={
		Say="Can you heal me please?";
		Reply="Patching you right up!";
	};
	
};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
		local modOnGameEvents = shared.require(game.ServerScriptService.ServerLibrary.OnGameEvents);

		dialog:AddChoice("heal_request", function()
			if not dialog.InRange() then return end;
			modStatusEffects.FullHeal(player, 0.2);
			shared.modEventService:ServerInvoke("Dialogue_BindMedicHeal", {}, player, dialog);
		end)
	end 
end

return Dialogues;