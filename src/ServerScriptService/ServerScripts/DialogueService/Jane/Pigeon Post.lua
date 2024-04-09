local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

--==
return function(player, dialog, data, mission)
	if mission.Type == 1 then -- Active
		dialog:AddChoice("pigeonPost_what", function(dialog)
			dialog:AddChoice("pigeonPost_whosNick", function(dialog)
				dialog:AddChoice("pigeonPost_oh", function(dialog)
					modMission:Progress(player, 14, function(mission)
						if mission.ProgressionPoint < 3 then
							mission.ProgressionPoint = 3;
						end;
					end)
				end)
			end)
		end)
		
	end
end
