local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id = "Juggernog";
    Icon = "rbxassetid://118774277308416";
    Name = "Juggernog";

    Description = "Max health +$MaxHealthOverCharge";

    Buff = true;
    PresistUntilExpire = {};
};

function statusPackage.BindApply(statusClass: StatusClassInstance)
    local playerClass = statusClass.StatusOwner :: PlayerClass;
    if playerClass == nil then return end;

    statusClass.Values.MaxHealthOverCharge = statusClass.Values.MaxHealthOverCharge or 100;
end

return modStatusClass.new(statusPackage);