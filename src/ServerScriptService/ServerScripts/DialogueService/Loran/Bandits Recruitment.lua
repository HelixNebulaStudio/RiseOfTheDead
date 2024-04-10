local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);

--==
return function(player, dialog, data, mission)
	local stage = mission.ProgressionPoint;
	
	if modBranchConfigs.IsWorld("BanditsRecruitment") then
		if mission.Type == 1 then -- Active
			if stage == 5 then
				
				dialog:SetInitiateTag("theRecruit_init");
				dialog:AddChoice("theRecruit_wait", function(dialog)
					modMission:Progress(player, 63, function(mission)
						if mission.ProgressionPoint < 6 then
							mission.ProgressionPoint = 6;
						end;
					end)
				end);

			end
		end
		
	elseif modBranchConfigs.IsWorld("TheMall") then
		if mission.Type == 1 then -- Active
			if stage == 12 then
				dialog:SetInitiate("What took you so long?");

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

						modMission:CompleteMission(player, 63);
						
						shared.Notify(player, "You have unlockabled Bandit's Market. Talk to Loran to check it out.", "Positive");
					end)

				else
					dialog:AddChoice("theRecruit_help");

				end
			end
		end
	end
end
