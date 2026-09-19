local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="Hello, how may I help you?";
	};
	["init2"]={
		Reply="Hey, how are you?";
	};
	["init3"]={
		Reply="Yes? Do you need some help?";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	["heal_request"]={
		Say="Can you heal me please?";
		Reply="Sure, hold still...";
	};

};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		local mission18 = modMission:GetMission(player, 18);
		if mission18 == nil or mission18.Type ~= 1 or mission18.ProgressionPoint >= 9 then
			dialog:AddChoice("heal_request", function()
				if not dialog.InRange() then return end;
				modStatusEffects.FullHeal(player);
				shared.modEventService:ServerInvoke("Dialogue_BindMedicHeal", {}, player, dialog);
			end)
		end
	end 
end

return Dialogues;