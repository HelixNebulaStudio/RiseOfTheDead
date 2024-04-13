local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modMission = require(game.ServerScriptService.ServerLibrary.Mission);


--== When something happens;
return function(player, modeType, modeStage, roomData)
	Debugger:Warn("Mode:",modeType,"Stage:",modeStage);

	if modeType == "Raid" then
		if modeStage == "Factory" then
            if modMission:Progress(player, 12) then
                modMission:Progress(player, 12, function(mission)
                    if mission.ProgressionPoint < 4 then
                        mission.ProgressionPoint = 4;
                    end;
                end)
            end
        end

    end
end;
