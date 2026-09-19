local RunService = game:GetService("RunService");

local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id = "BloxyRush";
    Icon = "rbxassetid://5094119246";
    Name = "Bloxy Rush";
    Description = "Speed and Melee Stamina bonus for a temporary duration.";
    Buff = true;
    Cleansable = true;
    ExpiresOnDeath = true;
};

local modifierId = statusPackage.Id;

function statusPackage.BindApply(statusClass: StatusClassInstance)
    local characterClass: CharacterClass = statusClass.StatusOwner :: CharacterClass;
    local configurations = characterClass.Configurations;

    local statusModifier: ConfigModifier = configurations:GetModifier(modifierId);
    if statusModifier == nil then
        statusModifier = configurations.newModifier(modifierId);
        statusModifier.Name = statusPackage.Name;

        statusModifier.MaxValues.MeleeStaminaRecoveryRate = 30;
        statusModifier.MaxValues.MeleeStaminaRecoveryDelay = 1;
        statusModifier.MaxValues.SprintSpeed = 26.4;
        statusModifier.ArrayValues.PassiveModifiers = "Bloxy Rush";

        statusModifier.Tags.StatusMod = true;
    end

    configurations:AddModifier(statusModifier);
    characterClass.WieldComp:RefreshCharacterModifiers();
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
    local characterClass: CharacterClass = statusClass.StatusOwner :: CharacterClass;
    local configurations = characterClass.Configurations;

    configurations:RemoveModifier(modifierId);
    characterClass.WieldComp:RefreshCharacterModifiers();
end

return modStatusClass.new(statusPackage);