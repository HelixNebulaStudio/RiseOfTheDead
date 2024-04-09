local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);


--== When OnModEquipped;
return function(player, mod, item)
	local profile = modProfile:Get(player);
	local activeSave = profile:GetActiveSave();
	local inventory = activeSave.Inventory;
	
	if mod.ItemId == "pistoldamagemod" then
		if modMission:Progress(player, 5) then
			modMission:Progress(player, 5, function(mission)
				if mission.ProgressionPoint == 7 then
					mission.ProgressionPoint = 8;
				end;
			end)
		end
	end
end;
