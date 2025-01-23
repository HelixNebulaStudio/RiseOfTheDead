local modStatusClass = require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="CritBoost";
    Icon="rbxassetid://10368377851";
    Name="Crit Boost";
    Description="Boost crit chance by +$Amount%";
    Buff=true;
};

function statusPackage:OnApply()
    local playerClass = self.PlayerClass;
    if playerClass == nil then return end;
    
    local modifier = playerClass.Configurations:GetModifier(statusPackage.Id);
    if modifier == nil then
        modifier = playerClass.Configurations.newModifier(statusPackage.Id);

        modifier.IsEquipmentModifier = true; 
        modifier.AddValues.CritBoost = self.Amount;
    end

    playerClass.Configurations:AddModifier(modifier);
end

function statusPackage:OnExpire()
    local playerClass = self.PlayerClass;
    if playerClass == nil then return end;

    playerClass.Configurations:RemoveModifier(statusPackage.Id);
end

return modStatusClass.new(statusPackage);