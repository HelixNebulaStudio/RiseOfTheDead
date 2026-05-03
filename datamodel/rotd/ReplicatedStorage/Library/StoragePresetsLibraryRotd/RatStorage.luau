local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

if RunService:IsServer() then
    modAnalyticsService = shared.require(game.ServerScriptService.ServerLibrary.AnalyticsService);
end

local presetPackage = {
	Id = "RatStorage";
    Name = "Rat Storage";
    Configuration = {
        Persistent = true; 
        Settings = {ScaleByContent=1; Rental=5;};
        Size = 50; 
        MaxSize = 50; 
        MaxPages = 9;
    };
    MissionRequired = {
        Id = 62; 
        Type = {3};
    };
    Permissions = {
        CanInteract = true;
    };
};

function presetPackage.BindInit(storage: Storage)
    storage:BindActionHandler("Rental", function(params, rPacket)
        local storageId = params.StorageId;
        if storageId ~= storage.Id then
            rPacket.FailMsg = `Invalid storage ({storageId} ~= {storage.Id})`;
            return rPacket;
        end

        local player = storage.Player;
        if player == nil then return end;

        local profile: ProfileRotd = shared.modProfile:Get(player) :: ProfileRotd;

        local rentalPrice = storage.Settings.Rental;
        if rentalPrice == nil then
            rPacket.FailMsg = `Not rental ({storageId})`;
            return rPacket;
        end;
        
        local traderProfile = profile and profile.Trader;
        if traderProfile == nil then
            rPacket.FailMsg = `No gold profile ({storageId})`;
            return rPacket;
        end;

        local itemCount = 0;
        for storageItemId, storageItem in pairs(storage.Container) do
            itemCount = itemCount +1;
        end
        local rentCost = itemCount * rentalPrice;
                
        if traderProfile.Gold < rentCost then
            rPacket.FailMsg = `Insufficient gold ({storageId})`;
            return rPacket;
        end;
    
        traderProfile:AddGold(-rentCost);

        modAnalyticsService:Sink{
            Player = player;
            Currency = modAnalyticsService.Currency.Gold;
            Amount = rentCost;
            EndBalance = traderProfile.Gold;
            ItemSKU = `Rental:RatStorage`;
        };

        storage.Values.RentalUnlockTime = workspace:GetServerTimeNow() + shared.Const.OneDaySecs;
        rPacket.Success = true;
        
        if rPacket.Storages == nil then
            rPacket.Storages = {};
        end
        rPacket.Storages[storageId] = storage:Shrink();

        return rPacket;
    end)
end

return presetPackage;