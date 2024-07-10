local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

--== Variables;
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);

return function(player, dialog, dialogueData)
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
