local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local GIFT_SPAWNCF = CFrame.new(-59.9, 36.3, 286.4, 0, 0, -1, 0, 1, 0, 1, 0, 0);

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new(script);
--==

function WorldCore.onRequire()
    if RunService:IsServer() then
        shared.modEngineCore:ConnectOnPlayerAdded(script, function(player: Player)
            local profile: ProfileRotd = shared.modProfile:WaitForProfile(player) :: ProfileRotd;
            if profile == nil then return end;

            WorldCore:SpawnGift(player, "underbridgeGift", GIFT_SPAWNCF);

        end, 999);

        -- 
        shared.modNpcs.spawn2{Name="Lennon";};

        -- Safehouse 4
        shared.modNpcs.spawn2{Name="Vladimir";};
        shared.modNpcs.spawn2{Name="Rachel";};

    end

end


return WorldCore;