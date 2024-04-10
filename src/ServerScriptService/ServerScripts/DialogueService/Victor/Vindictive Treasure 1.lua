local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modGameModeManager = require(game.ServerScriptService.ServerLibrary.GameModeManager);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

--==
return function(player, dialog, data, mission)
	if mission.Type == 2 then -- Available	
		dialog:SetInitiate("Hey dude, I need help with something.", "Bored");
		dialog:AddChoice("vt1_init", function(dialog)
			dialog:AddChoice("vt1_beast", function(dialog)
				dialog:AddChoice("vt1_sure", function(dialog)
					modMission:StartMission(player, 40);
				end)
			end)
		end)
		
	elseif mission.Type == 1 then -- Active;
		if mission.ProgressionPoint == 1 then
			dialog:SetInitiate("What's taking so long, you scared..?", "Bored");
			
		elseif mission.ProgressionPoint >= 3 and mission.ProgressionPoint <= 4 then
			dialog:SetInitiate("You need to kill the beast in the park.", "Bored");
			modMission:Progress(player, 40, function(mission)
				mission.ProgressionPoint = 2;
			end)
			
		elseif mission.ProgressionPoint == 7 then
			dialog:SetInitiate("Well, what did you find?", "Bored");
			
			local profile = modProfile:Get(player);
			local playerSave = profile:GetActiveSave();
			local inventory = playerSave.Inventory;
			local _, itemList = inventory:ListQuantity("nekronmask", 1);
			
			if itemList and #itemList > 0 then
				dialog:AddChoice("vt1_find", function(dialog)
					data:Set("gaveMask", true);
					for a=1, #itemList do
						inventory:Remove(itemList[a].ID, itemList[a].Quantity);
					end
					shared.Notify(player, "Removed Nekron Mask from your inventory.", "Negative");
					modMission:CompleteMission(player, 40);
				end)
			end
			
			dialog:AddChoice("vt1_notfind", function(dialog)
				data:Set("gaveMask", false);
				modMission:CompleteMission(player, 40);
			end)
		end
		
	end
	
	local mission42 = modMission:GetMission(player, 42);
	if mission.ProgressionPoint >= 5 and (mission42 == nil or mission42.ProgressionPoint ~= 1) and not modBranchConfigs.IsWorld("VindictiveTreasure") then
		dialog:AddChoice("vt1_tombs", function(dialog)
			modGameModeManager:Assign(player, "Raid", "Tombs");
		end)
	end
end
