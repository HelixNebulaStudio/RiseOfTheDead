local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local RunService = game:GetService("RunService");

if RunService:IsServer() then
    modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
end
--==
return function(event: EventPacket, action: string, packet: anydict)
    if action == "BuyAmmo" then
        local storageItem = packet.StorageItem;
        local cost = packet.Cost;


    end
end
 