local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modEvents = require(game.ServerScriptService.ServerLibrary.Events);

--==
return function(player, dialog, data, mission)
	if mission.Type == 1 then -- Active
		if mission.ProgressionPoint == 3 then
			dialog:AddChoice("warmup_done", function(dialog)
				modMission:CompleteMission(player, 46);
				local profile = modProfile:Get(player);
				profile:Unlock("SkinsPacks", "FestiveWrapping", true);
			end)
		end
	
	elseif mission.Type == 2 then -- Available

		dialog:SetInitiate("Welp, looks like I'm stuck here for a while with the outside being so dum cold. I notice you guys do not have a fireplace before, so I created one, but I need your help igniting it.", "Surprise");
		dialog:AddChoice("warmup_init", function(dialog)
			dialog:AddChoice("warmup_start", function(dialog)
				modMission:StartMission(player, 46);
			end);
		end);
		
	end
end