local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id = "StrongRoot";
    Icon = "rbxassetid://10368377851";
    Name = "StrongRoot";
    Description = "";
    Buff = true;
};

function statusPackage.BindApply(statusClass: StatusClassInstance)
    statusClass.Values.StrongRoot = statusClass.Duration;
end

return modStatusClass.new(statusPackage);