local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

return function(event: EventPacket, ...)
    local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

    local player = event.Player;
    if player == nil then return end;

    local worldId: string, teleportData: anydict = ...;
    task.spawn(function()
    
    	local profile = shared.modProfile:Get(player);
        
        if worldId == "TheUnderground" then
            modMission:Progress(player, 18, function(mission)
                if mission.ProgressionPoint < 3 then mission.ProgressionPoint = 3; end;
            end)
            
        elseif worldId == "TheMall" then
            modMission:Progress(player, 30, function(mission)
                if mission.ProgressionPoint < 4 then mission.ProgressionPoint = 4; end;
            end)
            modMission:Progress(player, 43, function(mission)
                if mission.ProgressionPoint == 3 then mission.ProgressionPoint = 4; end;
            end)
            
        elseif worldId == "TheResidentials" then
            modMission:Progress(player, 38, function(mission)
                if mission.ProgressionPoint < 5 then mission.ProgressionPoint = 5; end;
            end)
            
        end
    end)
end;