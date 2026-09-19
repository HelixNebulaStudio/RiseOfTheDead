local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local statusPackage = {
    Id = "CritBoost";
    Icon = "rbxassetid://10368377851";
    Name = "Crit Boost";

    Description = "Boost crit chance by +$Amount%";
    DescProcess = {
        ["Amount"]=function(v) 
            return math.round(v*1000)/10;
        end
    };

    Buff = true;
    PresistUntilExpire = {"Amount";};
};

function statusPackage.BindApply(statusClass: StatusClassInstance)
    local playerClass = statusClass.StatusOwner :: PlayerClass;
    if playerClass == nil then return end;

    local statusModifier: ItemModifierInstance = playerClass.Configurations:GetModifier(statusPackage.Id);
    if statusModifier == nil then
        local criticalHitModule = game.ReplicatedStorage.Library.ItemModifierClass.CriticalHit;
        statusModifier = playerClass.WieldComp:InstanceItemModifierClass(statusPackage.Id, criticalHitModule);
        statusModifier.Priority = 2;
        statusModifier.Name = `Crit Boost`;

        statusModifier.SumValues.CritChance = statusClass.Values.Amount;
        statusModifier.ArrayValues.PassiveModifiers = "Crit Boost";

        statusModifier.Tags.GunModifier = true;
        statusModifier.Tags.MeleeModifier = true;
        statusModifier.Tags.StatusMod = true;
    end

    playerClass.Configurations:AddModifier(statusModifier);
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
    local playerClass = statusClass.StatusOwner :: PlayerClass;
    if playerClass == nil then return end;

    playerClass.Configurations:RemoveModifier(statusPackage.Id);
end

return modStatusClass.new(statusPackage);