local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

--== Variables;
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);

local generic = require(script.Parent.Survivor);
--==
if modBranchConfigs.IsWorld("Safehome") then
	return generic;
	
else
	return function(player, dialog, dialogueData)
		dialog:AddChoice("heal_request", function()
			if not dialog.InRange() then return end;
			modStatusEffects.FullHeal(player, 0.15);

			modOnGameEvents:Fire("OnMedicHeal", player, dialog.Name);
		end)
	end

end
