local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);

--==
return function(player, dialog, data, mission)
	if mission.Type == 2 then -- Available

	elseif mission.Type == 1 then -- Active
		local stage = mission.ProgressionPoint;
		if stage == 16 then
			dialog:SetInitiate("Oh great.. Another survivor..", "Ugh");
			dialog:AddChoice("investigation_convince", function(dialog)
				dialog:AddChoice("investigation_convince2", function(dialog)
					dialog:AddChoice("investigation_convince3", function(dialog)
						modMission:Progress(player, 52, function(mission)
							if mission.ProgressionPoint == 16 then
								mission.ProgressionPoint = 17;
							end
						end)
					end)
				end)
			end)
			
		elseif stage == 17 then
			local profile = modProfile:Get(player);
			local playerSave = profile:GetActiveSave();
			local inventory = playerSave.Inventory;
			local total, itemList = inventory:ListQuantity("advmedkit", 1);
			
			if total > 0 then
				dialog:AddChoice("investigation_medkit", function(dialog)
					for a=1, #itemList do
						inventory:Remove(itemList[a].ID, itemList[a].Quantity);
						shared.Notify(player, "Advance Medkit removed from your Inventory.", "Negative");
					
					end
					
					modMission:Progress(player, 52, function(mission)
						if mission.ProgressionPoint == 17 then
							mission.ProgressionPoint = 18;
						end
					end)
				end)
			else
				dialog:AddChoice("investigation_needAdvmedkit");
			end
		end
	end
end
