local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);

--==
return function(player, dialog, data, mission)
	if mission.Type == 1 then -- Active
		dialog:SetInitiate("Have you found the 2 igniters yet?");
		if mission.ObjectivesCompleted["IgniterSearch"] == true then
			dialog:AddChoice("aGoodDeal_done", function(dialog)
				local profile = modProfile:Get(player);
				local playerSave = profile:GetActiveSave();
				local inventory = playerSave.Inventory;
				
				local total, itemList = inventory:ListQuantity("igniter", 2);
				if itemList then
					for a=1, #itemList do
						local itemLib = modItemsLibrary:Find("igniter");
						inventory:Remove(itemList[a].ID, itemList[a].Quantity);
						shared.Notify(player, ("$Amount$Item removed from your Inventory."):gsub("$Item", itemLib.Name):gsub("$Amount", itemList[a].Quantity > 1 and itemList[a].Quantity.." " or ""), "Negative");
					
					end
					modMission:CompleteMission(player, 16);
					delay(20, function()
						if modMission:GetMission(player, 17) == nil then
							modMission:AddMission(player, 17);
						end
					end)
				else
					shared.Notify(player, ("Unable to find items from inventory."), "Negative");
				end
			end)
		else
			dialog:AddChoice("aGoodDeal_notYet");
		end
		
	elseif mission.Type == 2 then -- Available
		dialog:SetInitiate("Hey, wanna make some quick dough?");
		dialog:AddChoice("aGoodDeal_questions");
		dialog:AddChoice("aGoodDeal_org");
		dialog:AddChoice("aGoodDeal_why");
		dialog:AddChoice("aGoodDeal_start", function(dialog)
			modMission:StartMission(player, 16);
		end)
		
	end
end