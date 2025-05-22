local RunService = game:GetService("RunService");

local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local statusPackage = {
    Id="BloxyRush";
    Icon="rbxassetid://5094119246";
    Name="Bloxy Rush";
    Description="Speed and Melee Stamina bonus for a temporary duration.";
    Buff=true;
    Cleansable=true;
    ExpiresOnDeath = true;
};

if RunService:IsServer() then
    local modifierId = statusPackage.Id;

    function statusPackage.OnApply(statusClass: StatusClassInstance)
        local characterClass: CharacterClass = statusClass.StatusOwner;
        local configurations = characterClass.Configurations;

        local statusModifier: ConfigModifier = configurations:GetModifier(modifierId);
        if statusModifier == nil then
            statusModifier = configurations.newModifier(modifierId);
            statusModifier.MaxValues.SprintSpeed = 26.4;
            statusModifier.Tags.StatusMod = true;
        end

        configurations:AddModifier(statusModifier);
    end

    function statusPackage.OnExpire(statusClass: StatusClassInstance)
        local characterClass: CharacterClass = statusClass.StatusOwner;
        local configurations = characterClass.Configurations;

        configurations:RemoveModifier(modifierId);
    end
end

return modStatusClass.new(statusPackage);