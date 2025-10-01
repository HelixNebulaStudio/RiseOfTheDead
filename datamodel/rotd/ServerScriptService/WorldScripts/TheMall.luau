local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

if RunService:IsServer() then

end

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new();
--==

function WorldCore.onRequire()
    if RunService:IsServer() then

        shared.modEngineCore:ConnectOnPlayerAdded(script, function(player: Player)
            local profile: ProfileRotd = shared.modProfile:WaitForProfile(player) :: ProfileRotd;
            if profile == nil then return end;

            local giftSpawn = CFrame.new(458.299988, 74.8267899, -1165.52124, 0, 0, 1, 0, 1, 0, -1, 0, 0);
            WorldCore:SpawnGift(player, "clinicGift", giftSpawn);
            
            local mollyNpcClass = shared.modNpcs.getPlayerNpc(player, "Molly");
            if mollyNpcClass == nil then
                mollyNpcClass = shared.modNpcs.spawn2{
                    Name = "Molly";
                    Player = player;
                    ReplicateOut = true;
                };
            end
        end, 999);

        shared.modNpcs.spawn2{Name="Maverick";};
        shared.modNpcs.spawn2{Name="Danny";};

        -- Bandit Camp
        shared.modNpcs.spawn2{Name = "Patrick";};
        shared.modNpcs.spawn2{
            Name = "Loran";
            CFrame = CFrame.new(795.21051, 162.605835, -668.609192, 1, 0, 0, 0, 1, 0, 0, 0, 1);
        };

        -- Safehouse 6
        shared.modNpcs.spawn2{Name="Alice";};
        shared.modNpcs.spawn2{Name="Mike";};

    elseif RunService:IsClient() then

    end
end

return WorldCore;