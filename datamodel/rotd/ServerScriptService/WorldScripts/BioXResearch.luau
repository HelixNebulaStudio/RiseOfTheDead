local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

if RunService:IsServer() then

end

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new();
--==

function WorldCore.onRequire()
    Debugger:Warn(`BioXResearch core loaded.`);
    if RunService:IsServer() then

        shared.modEngineCore:ConnectOnPlayerAdded(script, function(player: Player)
            local profile: ProfileRotd = shared.modProfile:WaitForProfile(player) :: ProfileRotd;
            if profile == nil then return end;

            WorldCore:SpawnGift(player, "sundaysGift", CFrame.new(-154.096, -18.925, 58.493));
            WorldCore:SpawnGift(player, "underbridgeGift", CFrame.new(-163.023, -18.925, 58.493));
            WorldCore:SpawnGift(player, "mallGift", CFrame.new(-171.089, -18.925, 58.493));
            WorldCore:SpawnGift(player, "clinicGift", CFrame.new(-179.052, -18.925, 58.493));

        end, 999);

    elseif RunService:IsClient() then

    end
end

return WorldCore;