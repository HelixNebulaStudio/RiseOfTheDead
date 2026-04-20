local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id = "Leashed";
    Icon = "";
    Name = "Leashed";
    Description = "";
    Buff = false;
};

function statusPackage.BindApply(statusClass: StatusClassInstance)
    --statusClass.Values.StrongRoot = statusClass.Duration;
end

return modStatusClass.new(statusPackage);