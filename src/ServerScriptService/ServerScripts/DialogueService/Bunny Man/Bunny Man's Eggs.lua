local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modEvents = require(game.ServerScriptService.ServerLibrary.Events);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);

--==
return function(player, dialog, data, mission)
	if mission.Type == 1 then -- Active
		if mission.ObjectivesCompleted["EggHunt"] == true then
			if modMission:CanCompleteMission(player, 31) then
				dialog:AddChoice("egghunt_end", function(dialog)
					local profile = modProfile:Get(player);
					local playerSave = profile:GetActiveSave();
					local inventory = playerSave.Inventory;
					
					local total, itemList = inventory:ListQuantity("easteregg2023", 3);
					if itemList then
						local itemLib = modItemsLibrary:Find("easteregg2023");
						for a=1, #itemList do
							inventory:Remove(itemList[a].ID, itemList[a].Quantity);
							shared.Notify(player, ("$Amount$Item removed from your Inventory."):gsub("$Item", itemLib.Name):gsub("$Amount", itemList[a].Quantity > 1 and itemList[a].Quantity.." " or ""), "Negative");
						end
						modMission:CompleteMission(player, 31);
					else
						shared.Notify(player, ("Unable to find items from inventory."), "Negative");
					end
				end)
			else
				dialog:AddChoice("egghunt_invfull");
			end
		else
			dialog:AddChoice("egghunt_where");
		end
	end
end