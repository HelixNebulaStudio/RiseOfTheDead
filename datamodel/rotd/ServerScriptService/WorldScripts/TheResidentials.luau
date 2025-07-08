local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local GIFT_SPAWNCF = CFrame.new(1071.313, 55.012, -162.888) * CFrame.Angles(0, math.rad(90), 0);

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new();
--==

function WorldCore.onRequire()
    if RunService:IsServer() then
        shared.modEngineCore:ConnectOnPlayerAdded(script, function(player: Player)
            local profile: ProfileRotd = shared.modProfile:WaitForProfile(player) :: ProfileRotd;
            if profile == nil then return end;

            WorldCore:SpawnGift(player, "residentialGift", GIFT_SPAWNCF);

        end, 999);

        -- Community Safehouse
        shared.modNpcs.spawn2{Name="Larry";};

        shared.modNpcs.spawn2{Name="Dallas";};
        shared.modNpcs.spawn2{Name="Kelly";};
        shared.modNpcs.spawn2{Name="Zep";};
        shared.modNpcs.spawn2{Name="Joseph";};
        shared.modNpcs.spawn2{Name="Nate";};

    end
end


return WorldCore;