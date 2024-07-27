local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);


--== When something happens;
return function(player, modeType, modeStage, roomData)
	local profile = modProfile:Get(player);
	local activeSave = profile:GetActiveSave();
	local inventory = activeSave.Inventory;
	
	Debugger:Warn("Mode:",modeType,"Stage:",modeStage);

	if modeType == "Raid" then
		if modeStage == "Office" then
			modMission:Progress(player, 43, function(mission)
				if mission.ProgressionPoint < 2 then mission.ProgressionPoint = 2; end;
			end)
			
		elseif modeStage == "Factory" then
			if modMission:Progress(player, 12) then
				modMission:Progress(player, 12, function(mission)
					if mission.ProgressionPoint < 5 then
						mission.ProgressionPoint = 5;
					end;
				end)
			end	

		end
		
	end
end;
