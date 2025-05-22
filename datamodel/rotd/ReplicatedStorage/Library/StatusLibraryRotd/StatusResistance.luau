local RunService = game:GetService("RunService");
local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
local modTables = shared.require(game.ReplicatedStorage.Library.Util.Tables);
--==
local statusPackage = {
    Id="StatusResistance";
    Icon="rbxassetid://6469142255";
    Name="Status Resistance";
    Description="Reduced negative effects duration by $Percent%.";
    Buff=true;
    Cleansable=true;
    ExpiresOnDeath=true;
};

function statusPackage.init()
    if RunService:IsClient() then return end;

    local modOnGameEvents = shared.require(game.ServerScriptService.ServerLibrary.OnGameEvents);
    modOnGameEvents:ConnectEvent("OnStatusSet", function(statusClass: StatusClassInstance)
        local modStatusLibrary = shared.require(game.ReplicatedStorage.Library.StatusLibrary);

        local playerClass: PlayerClass = statusClass.StatusOwner;
        if playerClass == nil then return end;

        local resistanceStatusClass = playerClass.StatusComp:GetOrDefault(statusPackage.Id);
        if resistanceStatusClass == nil then return end;

        if statusClass.Buff ~= false or statusClass.Duration == nil or statusClass.Expires == nil or statusClass.Tags == nil then return end;
        if modTables.ContainsList(statusClass.Tags, modStatusLibrary.DebuffTags) == false then return end;

        local resistValue = (1-(resistanceStatusClass.Percent/100));

        local newDuration = statusClass.Duration * resistValue;
        local durDiff = statusClass.Duration - newDuration;
        
        statusClass.Duration = statusClass.Duration - durDiff;
        statusClass.Expires = statusClass.Expires - durDiff;

        statusClass:Sync();
    end)
end

return modStatusClass.new(statusPackage);