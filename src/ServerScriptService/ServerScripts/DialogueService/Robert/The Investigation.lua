local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

--==
return function(player, dialog, data, mission)
	if mission.Type == 2 then -- Available

	elseif mission.Type == 1 then -- Active
		local stage = mission.ProgressionPoint;
		if stage == 1 then
			dialog:SetInitiate("Oh hey, $PlayerName..");
			dialog:AddChoice("investigation_sus");
			
		elseif stage == 2 then
			dialog:SetInitiate("Oh hey, $PlayerName..");
			dialog:AddChoice("investigation_lure", function(dialog)
				modMission:Progress(player, 52, function(mission)
					if mission.ProgressionPoint == 2 then
						mission.ProgressionPoint = 3;
					end
				end)
			end)
			
		elseif stage == 3 then
			dialog:SetInitiate("Following right behind you.");
			
		end
	end
end
