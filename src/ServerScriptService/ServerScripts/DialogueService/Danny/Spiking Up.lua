local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);

--==
return function(player, dialog, data, mission)
	if mission.Type == 1 then -- Active
		dialog:SetInitiate("How's it going?", "Confident");
		
		local mission = modMission:Progress(player, 39);
		if mission.ObjectivesCompleted["addWall1"]
		and mission.ObjectivesCompleted["addWall2"]
		and mission.ObjectivesCompleted["addWall3"]
		and mission.ObjectivesCompleted["addWall4"]
		and mission.ObjectivesCompleted["addWall5"] then
			dialog:AddChoice("spikingUp_complete", function(dialog)
				modMission:CompleteMission(player, 39);
			end)
		end
		
	elseif mission.Type == 2 then -- Available
		dialog:SetInitiate("Hey, could you do me a favor?");
		
		dialog:AddChoice("spikingUp_start", function(dialog)
			dialog:AddChoice("spikingUp_sure", function(dialog)
				modMission:StartMission(player, 39);
			end)
		end)
	
	elseif mission.Type == 3 then -- Complete
		
	end
end
