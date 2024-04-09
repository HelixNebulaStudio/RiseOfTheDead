local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

--== Variables;
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modBlueprints = require(game.ServerScriptService.ServerLibrary.Blueprints);
local modEvents = require(game.ServerScriptService.ServerLibrary.Events);

return function(player, dialog, dialogueData)
	dialog:AddChoice("heal_request", function(dialog)
		if not dialog.InRange() then return end;
		modStatusEffects.FullHeal(player);
		modMission:Progress(player, 2, function(mission)
			if mission.ProgressionPoint < 4 then
				mission.ProgressionPoint = 4;
			end;
		end)
	end)
	
	if modMission:IsComplete(player, 2) then
		dialog:AddChoice("general_cost");
		dialog:AddChoice("general_background");
		dialog:AddChoice("general_teachMe");
	end
end