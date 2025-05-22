local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="tickre";
    Icon="rbxassetid://4978159755";
    Name="Tick Protection";
    Description="You recently got damaged by a tick, thus will not take damage from another one until this expires.";
    Buff=true;
    Cleansable=true;
};

function statusPackage.init()
    -- This function is called once when the status package is loaded
end

function statusPackage.OnApply(statusClass: StatusClassInstance)
    -- This function is called when the status is applied to a character
    local playerClass = statusClass.StatusOwner :: PlayerClass;
    if playerClass == nil then return end;

    -- Apply tick protection logic here
end

function statusPackage.OnExpire(statusClass: StatusClassInstance)
    -- This function is called when the status expires or is removed
    local playerClass = statusClass.StatusOwner :: PlayerClass;
    if playerClass == nil then return end;

    -- Clean up any tick protection effects
end

function statusPackage.OnTick(statusClass: StatusClassInstance, tickData: TickData)
    -- This function is called periodically while the status is active
    -- No tick processing needed for this status
end

function statusPackage.OnRelay(statusClass: StatusClassInstance, ...)
    -- This function is called when data is relayed to this status
    -- No relay processing needed for this status
end

return modStatusClass.new(statusPackage);