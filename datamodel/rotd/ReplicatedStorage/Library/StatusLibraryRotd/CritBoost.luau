local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="CritBoost";
    Icon="rbxassetid://10368377851";
    Name="Crit Boost";
    Description="Boost crit chance by +$Amount%";
    Buff=true;
    PresistUntilExpire={"Duration";};
};

function statusPackage.BindApply(statusClass: StatusClassInstance)
    local playerClass = statusClass.StatusOwner :: PlayerClass;
    if playerClass == nil then return end;

    local modifier: ItemModifierInstance = playerClass.Configurations:GetModifier(statusPackage.Id);
    if modifier == nil then
        modifier = playerClass.Configurations.newModifier(statusPackage.Id);

        modifier.Tags.Gun = true;
        modifier.SumValues.CritBoost = statusClass.Values.Amount;
    end

    playerClass.Configurations:AddModifier(modifier);
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
    local playerClass = statusClass.StatusOwner :: PlayerClass;
    if playerClass == nil then return end;

    playerClass.Configurations:RemoveModifier(statusPackage.Id);
end

return modStatusClass.new(statusPackage);