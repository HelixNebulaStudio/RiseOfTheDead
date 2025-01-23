local RunService = game:GetService("RunService");
local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local modTables = require(game.ReplicatedStorage.Library.Util.Tables);
--==
local statusPackage = {
    Id="StatusResistance";
    Icon="rbxassetid://6469142255";
    Name="Status Resistance";
    Description="Reduced negative effects duration by $Percent%.";
    Buff=true;
    Cleansable=true;
};

function statusPackage.init()
    if RunService:IsServer() then
        local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
        modOnGameEvents:ConnectEvent("OnStatusSet", function(statusClass)
            local modStatusLibrary = require(game.ReplicatedStorage.Library.StatusLibrary);

            local playerClass = statusClass.PlayerClass;
            if playerClass == nil then return end;

            local resistanceStatusClass = playerClass:GetStatus(statusPackage.Id);
            if resistanceStatusClass == nil then return end;

            if statusClass.Buff ~= false or statusClass.Duration == nil or statusClass.Expires == nil or statusClass.Tags == nil then return end;
            if modTables.ContainsList(statusClass.Tags, modStatusLibrary.DebuffTags) == false then return end;

            local resistValue = (1-(resistanceStatusClass.Percent/100));

            local newDuration = statusClass.Duration * resistValue;
            local durDiff = statusClass.Duration - newDuration;
            
            statusClass.Duration = statusClass.Duration - durDiff;
            statusClass.Expires = statusClass.Expires - durDiff;

            playerClass:SyncStatus(statusClass.Id);
        end)
    end
end

return modStatusClass.new(statusPackage);