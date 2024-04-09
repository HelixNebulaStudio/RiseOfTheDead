local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

--==
return function(player, dialog, data, mission)
	if mission.Type == 1 then -- Active
		dialog:SetInitiate("Errr, were you suppose to be doing something for me? I forgot..");
		local mission = modMission:Progress(player, 23);
		if mission.Type == 1 then
			if mission.ProgressionPoint == 2 then
				if modMission:CanCompleteMission(player, 23) then
					dialog:AddChoice("snipernest_done", function(dialog)
						modMission:CompleteMission(player, 23);
					end);
				else
					dialog:AddChoice("fail_invFull");
				end
			end
		end
		
	elseif mission.Type == 2 then -- Available
		dialog:SetInitiate("Kiddddo, ehhh can you help me out?", "Confident");
		dialog:AddChoice("snipernest_help", function(dialog)
			dialog:AddChoice("snipernest_many", function(dialog)
				modMission:StartMission(player, 23);
			end)
			dialog:AddChoice("snipernest_yes", function(dialog)
				modMission:StartMission(player, 23);
			end)
			dialog:AddChoice("snipernest_no");
		end)
		
	end
end