local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);


--==
return function(player, dialog, data, mission)
	if mission.Type == 1 then -- Active
		local profile = modProfile:Get(player);
		local playerSave = profile:GetActiveSave();
		local inventory = playerSave.Inventory;
		
		dialog:SetInitiate("Did you find the music box yet?");
		if mission.ObjectivesCompleted["Musicbox"] == true then
			dialog:AddChoice("calmingtunes_give", function(dialog)
				local itemId = "musicbox";
				local total, itemList = inventory:ListQuantity(itemId, 1);
				if itemList then
					for a=1, #itemList do
						local itemLib = modItemsLibrary:Find(itemId);
						inventory:Remove(itemList[a].ID, itemList[a].Quantity);
						shared.Notify(player, "Music box removed from your Inventory.", "Negative");
					
					end
					modMission:CompleteMission(player, 36);
				else
					shared.Notify(player, ("Unable to find items from inventory."), "Negative");
				end
			end)
			
			--
		else
			local total, itemList = inventory:ListQuantity("boombox", 1);
			if total > 0 then
				dialog:AddChoice("calmingtunes_giveBoombox");
			else
				dialog:AddChoice("calmingtunes_wait");
			end
		end
		
	elseif mission.Type == 2 then -- Available
		dialog:SetInitiate("Ahh, I can't stand the noise. The growling, I can't stop panicing when I hear it..");
		dialog:AddChoice("calmingtunes_start", function(dialog)
			dialog:AddChoice("calmingtunes_musicbox", function(dialog)
				modMission:StartMission(player, 36);
			end)
		end)
		
	end
end
