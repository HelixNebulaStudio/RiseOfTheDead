local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modBlueprints = require(game.ServerScriptService.ServerLibrary.Blueprints);

--==
return function(player, dialog, data, mission)
	if modBranchConfigs.IsWorld("TheInvestigation") then return end;
	if mission.Type == 1 then -- Active
		dialog:SetInitiate("You got it done?");
		if mission.ObjectivesCompleted["wateringcan"] == true
		or mission.ObjectivesCompleted["jlLettuce1"] == true
		or mission.ObjectivesCompleted["jlLettuce2"] == true
		or mission.ObjectivesCompleted["jlLettuce3"] == true then
			dialog:AddChoice("josephsLettuce_end", function(dialog)
				modMission:CompleteMission(player, 37);
			end)
		end
		
	elseif mission.Type == 2 then -- Available
		dialog:SetInitiate("Ooh Howdy partner, my old watering can broke, do you mind helping me out?");
		dialog:AddChoice("josephsLettuce_start", function(dialog)
			modMission:StartMission(player, 37, function(successful)
				if successful then
					modBlueprints.UnlockBlueprint(player, "wateringcanbp");
				end
			end);
		end)
		
	end
end
