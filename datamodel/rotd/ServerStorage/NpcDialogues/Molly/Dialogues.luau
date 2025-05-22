local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local Dialogues = {};
--==

-- MARK: InitStrings
Dialogues.InitStrings = {
	["init1"]={
		Reply="This is sooo not cool.";
	};
	["init2"]={
		Reply="You got to be kidding me, where's the government?!";
	};
	["init3"]={
		Reply="Ugh, I just want to go home, this better be over soon.";
	};
};

-- MARK: DialogueStrings
Dialogues.DialogueStrings = {
	["heal_request"]={
		Say="Can you heal me please?";
		Reply="Sure~ Like I got anything better to do in this situation...";
	};
};

if RunService:IsServer() then
	-- MARK: DialogueHandler
	Dialogues.DialogueHandler = function(player, dialog, data)
		local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
		local modOnGameEvents = shared.require(game.ServerScriptService.ServerLibrary.OnGameEvents);

		dialog:AddChoice("heal_request", function()
			if not dialog.InRange() then return end;
			modStatusEffects.FullHeal(player, 0.3);
			modOnGameEvents:Fire("OnMedicHeal", player, dialog.Name);
		end)
	end 
end

return Dialogues;