local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local RunService = game:GetService("RunService");

local statusPackage = {
    Id = "nigowl";
    Icon = "rbxassetid://4492141104";
    Name = "Skill: Night Owl";
    Description = "-$Percent% enemy detection during night times.";
    Buff = true;
};

local modifierId = statusPackage.Id;
function statusPackage.BindApply(statusClass: StatusClassInstance)
    local characterClass: CharacterClass = statusClass.StatusOwner;
    local configurations = characterClass.Configurations;

    local skillStats = statusClass.Values.SkillData.Stats;

    local baseEnemyDetectionRange = configurations:GetBase("EnemyDetectionRange");
    local enemyDetectionReduction = baseEnemyDetectionRange * (100-skillStats.Percent.Value)/100;

    statusClass.Values.Percent = skillStats.Percent.Value;
    statusClass.Alpha = 1;

    local statusModifier: ConfigModifier = configurations:GetModifier(modifierId);
    if statusModifier == nil then
        statusModifier = configurations.newModifier(modifierId);
        statusModifier.Name = statusPackage.Name;

        statusModifier.MinValues.EnemyDetectionRange = enemyDetectionReduction;
        statusModifier.ArrayValues = {
            PassiveModifiers = statusPackage.Name;
        };
        
        statusModifier.Tags.StatusMod = true;
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
        if tickData.ms1000 == false then return end;

        local isDayTime = game.Lighting:GetAttribute("IsDayTime") == true;
        if isDayTime then
            statusClass.IsExpired = true;
            return;
        end
    end
end

return modStatusClass.new(statusPackage);