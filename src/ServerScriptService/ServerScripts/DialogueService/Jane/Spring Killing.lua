local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

--==
return function(player, dialog, data, mission)
	if mission.Type == 1 then -- Active
		dialog:SetInitiate("How's the progress, $PlayerName?");
		
		if mission.ObjectivesCompleted["The Prisoner"] == true
		and mission.ObjectivesCompleted["Tanker"] == true
		and mission.ObjectivesCompleted["Fumes"] == true then
			dialog:AddChoice("springkill_done", function(dialog)
				modMission:CompleteMission(player, 21);
			end)
		else
			dialog:AddChoice("springkill_notYet");
		end
		
	elseif mission.Type == 2 then -- Available
		dialog:SetInitiate("Hey, you up for some killing?");
		dialog:AddChoice("springkill_yes", function(dialog)
			modMission:StartMission(player, 21);
		end)
		
	end
end
