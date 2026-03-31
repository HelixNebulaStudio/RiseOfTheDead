local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new(script);

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

if RunService:IsServer() then
    modNpcs = shared.modNpcs;
end
--==

function WorldCore.onRequire()
    if RunService:IsServer() then
        shared.modEngineCore:ConnectOnPlayerAdded(script, function(player: Player)
            local profile: ProfileRotd = shared.modProfile:WaitForProfile(player) :: ProfileRotd;
            if profile == nil then return end;

        end, 999);

        shared.modEventService:OnInvoked("Destructibles_BindDestroyed",  function(event: EventPacket, ...)
            local destructible: DestructibleInstance = ...;
            local cframe = destructible.Model:GetPivot();

            if destructible.Id == "key2Shelf" then
                modAudio.Play("StorageWoodDrop", cframe);

            elseif destructible.Id == "key3Shelf" then
                modAudio.Play("StorageWoodDrop", cframe);

            elseif destructible.Id == "cellBars" then
                modAudio.Play("StorageMetalPickup", cframe);
                
            end
        end)

    end
end


return WorldCore;