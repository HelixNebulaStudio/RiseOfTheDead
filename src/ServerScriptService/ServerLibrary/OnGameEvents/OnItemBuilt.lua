local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);


--== When user claims a item built;
return function(player, blueprintLibrary)
	local profile = modProfile:Get(player);
	local activeSave = profile:GetActiveSave();
	local inventory = activeSave.Inventory;
	
	if blueprintLibrary.Product == "medkit" then
		if modMission:Progress(player, 8) then
			modMission:CompleteMission(player, 8);
		end
		
	elseif blueprintLibrary.Product == "incendiarymod" then
		if modMission:Progress(player, 9) then
			modMission:CompleteMission(player, 9);
		end
		
	elseif blueprintLibrary.Product == "electricmod" then
		if modMission:Progress(player, 15) then
			modMission:CompleteMission(player, 15);
		end
		
	elseif blueprintLibrary.Product == "wateringcan" then
		if modMission:Progress(player, 37) then
			modMission:Progress(player, 37, function(mission)
				mission.ObjectivesCompleted.wateringcan = true;
			end)
		end
		
	end
end;
