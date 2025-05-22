local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="Template";
    Icon="rbxassetid://10368377851";
    Name="Template";
    Description="";
    Buff=true;
};

function statusPackage.init()
    -- This function is called once when the status package is loaded
    -- Use this for setting up event connections or other initialization tasks
end

function statusPackage.OnApply(statusClass: StatusClassInstance)
    -- This is called when the StatusClassInstance is first applied on the character. (statusClass.StatusOwner :: CharacterClass)
    -- For player-specific logic, cast the owner: local playerClass = statusClass.StatusOwner :: PlayerClass
end

function statusPackage.OnUpdate(statusClass: StatusClassInstance)
    -- This is called when this StatusClassInstance is updated.
end

function statusPackage.OnExpire(statusClass: StatusClassInstance)
    -- This function is called when the status expires or is removed
    -- Clean up any resources or effects created in OnApply
end

function statusPackage.OnTick(statusClass: StatusClassInstance, tickData: TickData)
    -- This function is called periodically while the status is active
    -- tickData contains timing information (ms100, ms500, ms1000, etc.)
end

function statusPackage.OnRelay(statusClass: StatusClassInstance, ...)
    -- This if a server callback for when the server receives data from the client.
end

return modStatusClass.new(statusPackage);