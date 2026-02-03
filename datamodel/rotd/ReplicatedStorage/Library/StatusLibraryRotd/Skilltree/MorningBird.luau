local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local RunService = game:GetService("RunService");

local statusPackage = {
    Id = "morbir";
    Icon = "rbxassetid://4488388895";
    Name = "Skill: Morning Bird";
    Description = "+$MaxHealthOverCharge max health during the day.";
    Buff = true;
};

function statusPackage.BindApply(statusClass: StatusClassInstance)
    local characterClass: CharacterClass = statusClass.StatusOwner;

    local skillStats = statusClass.Values.SkillData.Stats;
    statusClass.Values.MaxHealthOverCharge = skillStats.MaxHealth.Value;
end

if RunService:IsServer() then
    function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
        if tickData.ms1000 == false then return end;

        local isDayTime = game.Lighting:GetAttribute("IsDayTime") == true;
        if not isDayTime then
            statusClass.IsExpired = true;
            return;
        end
    end
end

return modStatusClass.new(statusPackage);