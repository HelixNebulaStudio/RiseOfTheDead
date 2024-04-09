local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);


--== When OnCheckBlueprintCost
return function(player, eventData)
	local profile = modProfile:Get(player);
	local activeSave = profile:GetActiveSave();
	local inventory = activeSave.Inventory;
	
	if modMission:Progress(player, 5) then
		local fulfilled = true;
		for a=1, #eventData do
			if not eventData[a].Fulfilled then fulfilled = false; end;
		end
		modMission:Progress(player, 5, function(mission)
			if mission.ProgressionPoint == 2 or mission.ProgressionPoint == 3 then
				if fulfilled then
					mission.ProgressionPoint = 4;
				else
					mission.ProgressionPoint = 3;
				end
			end;
		end)
	end
end;
