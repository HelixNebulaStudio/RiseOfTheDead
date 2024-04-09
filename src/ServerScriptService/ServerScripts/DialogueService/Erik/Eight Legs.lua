local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

--==
return function(player, dialog, data, mission)
	if mission.Type == 1 then -- Active
		local stage = mission.ProgressionPoint;
		dialog:SetInitiate("Is.. is it gone?");
		if stage == 1 then
			dialog:AddChoice("eightlegs_almost");
		elseif stage == 2 then
			dialog:AddChoice("eightlegs_return", function(dialog)
				modMission:CompleteMission(player, 20);
			end)
		end
		
	elseif mission.Type == 2 then -- Available
		dialog:SetInitiate("Hey, can you help me with something?");
		dialog:AddChoice("eightlegs_sure", function(dialog)
			dialog:AddChoice("eightlegs_yeah", function(dialog)
				modMission:StartMission(player, 20);
			end)
		end)
		
	end
end
