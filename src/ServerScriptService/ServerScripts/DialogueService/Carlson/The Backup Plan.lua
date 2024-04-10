local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);

--==
return function(player, dialog, data, mission)
	if mission.Type == 1 then -- Active
		if mission.Type == 1 then
			if mission.ProgressionPoint == 1 then
				dialog:SetInitiate("The key's somewhere in the break room.");
				
			elseif mission.ProgressionPoint == 4 then
				dialog:SetInitiate("$PlayerName, did you get the 1000 metal?");
				
				local profile = modProfile:Get(player);
				local playerSave = profile:GetActiveSave();
				local inventory = playerSave.Inventory;
				local total, itemList = inventory:ListQuantity("metal", 1000);
				if total >= 1000 then
					dialog:AddChoice("thebackup_gotit", function(dialog)
						if itemList then
							for a=1, #itemList do
								inventory:Remove(itemList[a].ID, itemList[a].Quantity);
							end
							shared.Notify(player, "Removed 1000 Metal Scraps from your inventory.", "Negative");
							
							data:Set("thebackup_gaveMetal", true);
							modMission:CompleteMission(player, 22);
						else
							shared.Notify(player, ("Unable to find items from inventory."), "Negative");
						end
					end);
				end
				dialog:AddChoice("thebackup_wait");
				dialog:AddChoice("thebackup_stolen", function(dialog)
					data:Set("thebackup_gaveMetal", false);
					modMission:CompleteMission(player, 22);
				end);
				
			else
				dialog:SetInitiate("Gotta forify this place as soon as possible.");
			end
			
		end
		
	elseif mission.Type == 2 then -- Available
		dialog:SetInitiate("Hey, err.. $PlayerName was it?");
		dialog:AddChoice("thebackup_help", function(dialog)
			dialog:AddChoice("thebackup_thekey", function(dialog)
				modMission:StartMission(player, 22);
			end)
		end)
		
	end
end
