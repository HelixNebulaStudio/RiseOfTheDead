local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);

--==
return function(player, dialog, data, mission)
	if modBranchConfigs.IsWorld("SectorE") then
		if mission.Type == 1 then -- Active
			local stage = mission.ProgressionPoint;
			if stage == 15 then
				dialog:SetInitiate("Well?..");

				local profile = shared.modProfile:Get(player);
				local playerSave = profile:GetActiveSave();
				local inventory = playerSave.Inventory;
				local total, itemList = inventory:ListQuantity("nekronparticulatecache", 2);

				if total >= 2 then
					dialog:AddChoice("theRecruit_nekronParticulateCache", function(dialog)
						for a=1, #itemList do
							inventory:Remove(itemList[a].ID, itemList[a].Quantity);
							shared.Notify(player, "2 Nekron Particulate Cache removed from your Inventory.", "Negative");
						end
						
						modMission:CompleteMission(player, 62);
					end)
					
				else
					dialog:AddChoice("theRecruit_help");
					
				end
				
			end
		end
	end
end
