local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modEvents = require(game.ServerScriptService.ServerLibrary.Events);

--==
return function(player, dialog, data, mission)
	if mission.Type == 1 then -- Active
		if mission.ProgressionPoint == 2 then
			dialog:AddChoice("xmasramp_done", function(dialog)
				dialog:AddChoice("xmasramp_almost", function(dialog)
					modMission:CompleteMission(player, 25);
					local profile = modProfile:Get(player);
					profile:Unlock("SkinsPacks", "Xmas", true);
				end);
			end)
		end
	
	elseif mission.Type == 2 then -- Available

		dialog:SetInitiate("Heyhey, $PlayerName. You are a few point short from being on the nice list. Do you want to be on the nice list?", "Happy");
		dialog:AddChoice("xmasramp_yes", function(dialog)
			dialog:AddChoice("xmasramp_start", function(dialog)
				modMission:StartMission(player, 25);
			end);
		end);
		
	end
end
