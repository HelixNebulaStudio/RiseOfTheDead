local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);

--==
return function(player, dialog, data, mission)
	local profile = modProfile:Get(player);
	
	if mission.Type == 2 then --Available
		dialog:SetInitiate("Ahh god.. Can't believe I left it.");
		dialog:AddChoice("mlc_init", function(dialog)
			dialog:AddChoice("mlc_start", function(dialog)
				modMission:StartMission(player, 45);
			end)
		end);
		
	elseif mission.Type == 1 then -- Active
		dialog:SetInitiate("Found it yet?", "Worried");
		
		if mission.ProgressionPoint == 4 or profile.Collectibles.mlc then
			dialog:AddChoice("mlc_found", function(dialog)
				modMission:CompleteMission(player, 45);
			end)
		end
		
	end
end
