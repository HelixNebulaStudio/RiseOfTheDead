local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

--==
return function(player, dialog, data, mission)
	if mission.Type == 1 then -- Active
		local stage = mission.ProgressionPoint;
		dialog:SetInitiate("Progress status?");
		if stage == 1 then
			dialog:AddChoice("tickhunting_stillWorking");
		elseif stage == 2 then
			dialog:AddChoice("tickhunting_return", function(dialog)
				modMission:CompleteMission(player, 19);
			end)
		end
		
	elseif mission.Type == 2 then -- Available
		dialog:SetInitiate("You up for another task, solider?");
		dialog:AddChoice("tickhunting_sure", function(dialog)
			dialog:AddChoice("tickhunting_yeah", function(dialog)
				modMission:StartMission(player, 19);
			end)
		end)
		
	end
end