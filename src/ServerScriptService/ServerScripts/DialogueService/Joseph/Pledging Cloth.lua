local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);

--==
return function(player, dialog, data, mission)
	if modBranchConfigs.IsWorld("TheInvestigation") then return end;
	if mission.Type == 1 then -- Active
		dialog:SetInitiate("Got more cloth?");
		
	elseif mission.Type == 2 then -- Available
		dialog:SetInitiate("Hello friend, do you have some spare cloth?");
		dialog:AddChoice("pledginCloth_start", function(dialog)
			modMission:StartMission(player, 35);
		end)
--		dialog:SetInitiate("Hey, ready for another job?");
--		dialog:AddChoice("aGoodDeal_org");
--		dialog:AddChoice("aGoodDeal_why");
--		dialog:AddChoice("partTime_start", function(dialog)
--			modMission:StartMission(player, 17);
--		end)
		
	end
end
