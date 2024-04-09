local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);


--== When a player enters a door;
return function(player, packet)
	local profile = modProfile:Get(player);
	local activeSave = profile:GetActiveSave();
	
	if packet.WorldId == "TheUnderground" then
		modMission:Progress(player, 18, function(mission)
			if mission.ProgressionPoint < 3 then mission.ProgressionPoint = 3; end;
		end)
		
	elseif packet.WorldId == "TheMall" then
		modMission:Progress(player, 30, function(mission)
			if mission.ProgressionPoint < 4 then mission.ProgressionPoint = 4; end;
		end)
		modMission:Progress(player, 43, function(mission)
			if mission.ProgressionPoint == 3 then mission.ProgressionPoint = 4; end;
		end)
		
	elseif packet.WorldId == "TheResidentials" then
		modMission:Progress(player, 38, function(mission)
			if mission.ProgressionPoint < 5 then mission.ProgressionPoint = 5; end;
		end)
		
	end
end;
