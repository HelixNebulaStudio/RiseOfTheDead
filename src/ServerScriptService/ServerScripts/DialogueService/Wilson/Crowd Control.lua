local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

--==
return function(player, dialog, data, mission)
	if mission.Type == 1 then -- Active
		local stage = mission.ProgressionPoint;
		dialog:SetInitiate("How's the progress?");
		if stage == 1 then
			dialog:AddChoice("crowdcontrol_stillWorking");
		elseif stage == 2 then
			dialog:AddChoice("crowdcontrol_return", function(dialog)
				modMission:CompleteMission(player, 13);
			end)
		end
		
	elseif mission.Type == 2 then -- Available
		dialog:SetInitiate("Hey, you! I need your help.");
		dialog:AddChoice("crowdcontrol_what", function(dialog)
			dialog:AddChoice("crowdcontrol_yeah", function(dialog)
				modMission:StartMission(player, 13);
			end)
		end)
		
	end
end