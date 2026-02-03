local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local RunService = game:GetService("RunService");

local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);

local statusPackage = {
    Id = "theswo";
    Icon = "rbxassetid://4572998907";
    Name = "Skill: The Swordsman";
    Description = "Melee weapon damage increased by $Percent%.";
    Buff = true;
};

local modifierId = statusPackage.Id;
function statusPackage.BindApply(statusClass: StatusClassInstance)
    local characterClass: CharacterClass = statusClass.StatusOwner;
    local configurations = characterClass.Configurations;

    local skillData = statusClass.Values.SkillData;
    local skillStats = skillData.Stats;

    statusClass.Values.Percent = skillStats.Percent.Value;
    statusClass.Alpha = 1;

    local statusModifier: ConfigModifier = configurations:GetModifier(modifierId);
    if statusModifier == nil then
        statusModifier = configurations.newModifier(modifierId);
        statusModifier.Name = statusPackage.Name;
            
        statusModifier.ProductValues.Damage = 1 + (skillStats.Percent.Value/100);
        statusModifier.Priority = 98;

        statusModifier.ArrayValues = {
            PassiveModifiers = statusPackage.Name;
        };

        statusModifier.Tags.StatusMod = true;
        statusModifier.Tags.MeleeModifier = true;
        statusModifier:SetEnabled(true);
    end

    configurations:AddModifier(statusModifier);
end

function statusPackage.BindExpire(statusClass: StatusClassInstance)
    local characterClass: CharacterClass = statusClass.StatusOwner;
    local configurations = characterClass.Configurations;

    configurations:RemoveModifier(modifierId);
end

if RunService:IsServer() then
    function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
        if tickData.ms100 == false then return end;

        local characterClass: CharacterClass = statusClass.StatusOwner;
        local wieldComp: WieldComp = characterClass and characterClass.WieldComp;
        if wieldComp == nil then return end;

        if wieldComp.ItemId == nil or not modItemsLibrary:HasTag(characterClass.WieldComp.ItemId, "Melee") then
            statusClass.IsExpired = true;
            return;
        end;
    end
end

return modStatusClass.new(statusPackage);