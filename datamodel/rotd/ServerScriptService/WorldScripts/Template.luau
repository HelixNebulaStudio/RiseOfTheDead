local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");


local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new();
--==

function WorldCore.onRequire()
    if RunService:IsServer() then
        shared.modEngineCore:ConnectOnPlayerAdded(script, function(player: Player)
            local profile: ProfileRotd = shared.modProfile:WaitForProfile(player) :: ProfileRotd;
            if profile == nil then return end;

        end, 999);

    end
end


return WorldCore;