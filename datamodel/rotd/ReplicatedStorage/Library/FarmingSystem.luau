
local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local FarmingSystem = {};
local FARM_DATA_KEY = "Farming";

if RunService:IsServer() then
    modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
end

function FarmingSystem.onRequire()
    if RunService:IsServer() then
        modEvents.OnFetchRequest:Connect(function(player, eventId, eventData)
            if eventId ~= FARM_DATA_KEY then return end;
            local farmData = FarmingSystem.getFarmingData(player);
            
            for planterId, planterData in pairs(farmData.Planters) do
                FarmingSystem.updatePlanterData(planterData);
            end
        end)
    end
end

function FarmingSystem.updatePlanterData(planterData)
    local curTime = workspace:GetServerTimeNow();

    local lastUpdate = planterData.LastUpdate;
    if lastUpdate == nil then
        planterData.LastUpdate = curTime;
        return;
    end

    local tSinceLastUpdate = curTime - lastUpdate;
    local lastWaterTime = planterData.LastWaterTime;
    local lastWater = planterData.Water or 0;
    local buffer = 60;

    if curTime-lastWaterTime >= buffer and tSinceLastUpdate > 10 then
        local waterPerSec = 100/(shared.Const.OneDaySecs*3);
        local waterCost = waterPerSec * tSinceLastUpdate;

        planterData.Water = math.clamp(lastWater - waterCost, 0, 100);
        planterData.LastUpdate = curTime;
    end
end

function FarmingSystem.getFarmingData(player, fetch)
    local defaultEventData = {
        Id = FARM_DATA_KEY;
        Planters = {};
    };
    local eventData = nil;

    if RunService:IsServer() then
        eventData = modEvents:GetEvent(player, FARM_DATA_KEY);
        if eventData == nil then
            eventData = defaultEventData;
        end
        modEvents:NewEvent(player, eventData);

    elseif RunService:IsClient() then
        local modData = shared.require(localPlayer:WaitForChild("DataModule"));
        eventData = modData:GetEvent(FARM_DATA_KEY, fetch == true);
        if eventData == nil then
            eventData = defaultEventData;
        end

    end

    return eventData;
end

local WATERING_RATE = 22;
function FarmingSystem.waterPlanter(player, planterId)
    if RunService:IsClient() then return end;

    local farmData = FarmingSystem.getFarmingData(player);

    local planterData = farmData.Planters[planterId] or {
        Water = 0;
    };
    farmData.Planters[planterId] = planterData;

    if planterData.Water >= 100 then return end;
    
    local newWater = math.clamp((planterData.Water or 0) + WATERING_RATE, 0, 100);
    local eventPacket: EventPacket = shared.modEventService:ServerInvoke("Farming_BindWaterPlanter", {ReplicateTo={player}}, {
        FarmData = farmData;
        PlanterId = planterId;
        NewWater = newWater;
    });
    if eventPacket.Cancelled then return end;

    planterData.Water = newWater;
    planterData.LastWaterTime = workspace:GetServerTimeNow();

    FarmingSystem.updatePlanterData(planterData);
    modEvents:SyncEvent(player, FARM_DATA_KEY);
end


return FarmingSystem;