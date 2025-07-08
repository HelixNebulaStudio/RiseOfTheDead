local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

return function(event: EventPacket, ...)
    local storage: Storage = ...;

    if storage.Id == "thebackupplan" and storage.Player ~= nil then
        local player = storage.Player;
        local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		if modMission:Progress(player, 22) then
			modMission:Progress(player, 22, function(mission)
				if mission.ProgressionPoint == 3 then
					mission.ProgressionPoint = 4;
				end;
			end)
		end
    end
end;