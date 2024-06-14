local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local RunService = game:GetService("RunService");

local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modLZ4 = require(game.ReplicatedStorage.Library.Util.LZ4);

local remoteCustomizationData = modRemotesManager:Get("CustomizationData");

local CustomizationData = {};
CustomizationData.__index = CustomizationData;

function CustomizationData.new(player)
    local meta = {};
    meta.__index = meta;
    meta.Player = player;

    local self = {};

    setmetatable(self, meta);
    setmetatable(meta, CustomizationData);
    return self;
end

function CustomizationData:Load(rawTable)
    for itemId, v in pairs(rawTable) do
        local loadedData = {};
        self[itemId] = loadedData;

    end
    return self;
end

if RunService:IsServer() then
    function remoteCustomizationData.OnServerInvoked(player, action, ...)
        local profile = shared.modProfile:Get(player);
        local customizationData = profile.CustomizationData;

        if action == "get" then
            local siid = ...;
            if siid == nil then return end;
            
		    local storageItem, storage = shared.modStorage.FindIdFromStorages(siid, player);
            if storageItem == nil then return end;

            local itemId = storageItem.ItemId;
            local itemCustomizations = customizationData[itemId];
            if itemCustomizations == nil then return end;


        end
    end
end
--==
local CustomizationSkin = {};
CustomizationSkin.__index = CustomizationSkin;

function CustomizationData.newCustomizationSkin(rawLz4)
    local self = {};

    setmetatable(self, CustomizationSkin);
    return self;
end


return CustomizationData;