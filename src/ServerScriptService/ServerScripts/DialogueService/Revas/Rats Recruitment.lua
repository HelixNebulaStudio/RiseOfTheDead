local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);

--==
return function(player, dialog, data, mission)
	if modBranchConfigs.IsWorld("TheHarbor") then
		if mission.Type == 1 then -- Active
			local stage = mission.ProgressionPoint;
			if stage == 1 then
				dialog:SetInitiateTag("theRecruit_revasInit");
				dialog:AddChoice("theRecruit_revas1", function(dialog)
					dialog:AddChoice("theRecruit_revas2", function(dialog)
						dialog:AddChoice("theRecruit_revas3", function(dialog)
							modMission:Progress(player, 62, function(mission)
								if mission.ProgressionPoint < 2 then
									mission.ProgressionPoint = 2;
								end;
							end)
						end)
					end)
				end);

			elseif stage == 2 then
				dialog:SetInitiate("Are you ready?");
				dialog:AddChoice("theRecruit_revasTravel", function(dialog)
					--modServerManager:Travel(player, "SectorE");
					modServerManager:TeleportToPrivateServer("SectorE", modServerManager:CreatePrivateServer("SectorE"), {player});
				end)

			end
		end
		
	elseif modBranchConfigs.IsWorld("SectorE") then
		if mission.Type == 1 then -- Active
			local stage = mission.ProgressionPoint;
			if stage == 3 then
				dialog:SetInitiate("Here we are.");
				dialog:AddChoice("theRecruit_secE", function(dialog)
					modMission:Progress(player, 62, function(mission)
						if mission.ProgressionPoint <= 4 then
							mission.ProgressionPoint = 4;
						end
					end)
				end)
				
			elseif stage == 11 then
				dialog:SetInitiate("Eugene requires some items. Maybe you can be of service.");

				dialog:AddChoice("theRecruit_retrieve1", function(dialog)
					modMission:Progress(player, 62, function(mission)
						if mission.ProgressionPoint <= 11 then
							mission.ProgressionPoint = 12;
						end
					end)
				end)
				
			end
		end

	elseif modBranchConfigs.IsWorld("SectorF") then

		if mission.Type == 1 then -- Active
			local stage = mission.ProgressionPoint;
			if stage == 13 then
				dialog:SetInitiate("Have you found it?");
				dialog:AddChoice("theRecruit_cantFind");
				
			elseif stage == 14 then
				dialog:SetInitiate("Have you found it?");

				local profile = shared.modProfile:Get(player);
				local playerSave = profile:GetActiveSave();
				local inventory = playerSave.Inventory;
				local total, itemList = inventory:ListQuantity("researchpapers", 1);
				
				if total >= 1 then
					dialog:AddChoice("theRecruit_found", function(dialog)
						for a=1, #itemList do
							inventory:Remove(itemList[a].ID, itemList[a].Quantity);
							shared.Notify(player, "Research papers removed from your Inventory.", "Negative");
						end

						modMission:Progress(player, 62, function(mission)
							mission.ProgressionPoint = 15;
						end)
					end)
					
				else
					dialog:AddChoice("theRecruit_cantFind");
					
				end
				
			end
		end
	end
end
