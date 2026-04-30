local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local RunService = game:GetService("RunService");

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local statusPackage = {
    Id = "TooCold";
    Icon = "rbxassetid://3564119613";
    Name = "Too Cold";
    Description = "It's too cold. (Below 10°C) Put on more clothes! If you take damage, you might freeze.";
    Buff = false;
};

function statusPackage.BindApply(statusClass: StatusClassInstance)
    if RunService:IsClient() then return end;
    local characterClass = statusClass.StatusOwner :: CharacterClass;
	if characterClass == nil then return end;

    local statusComp: StatusComp = characterClass.StatusComp;
    local healthComp: HealthComp = characterClass.HealthComp;

    local function tryFreeze(newV, oldV, damageData)
        if healthComp.IsDead then return end;
        if damageData == nil or damageData.DamageType == "Ice" then return end;
        if newV >= oldV then return end;
        if math.random(1, 3) ~= 1 then return end;

        local duration = 5;
            
        statusComp:Apply("Freezing", {
            Expires = workspace:GetServerTimeNow() + duration;
            Duration = duration;
        });
    end

    statusClass.Garbage:Tag(healthComp.OnArmorChanged:Connect(tryFreeze));
    statusClass.Garbage:Tag(healthComp.OnHealthChanged:Connect(tryFreeze));
end

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsClient() then return end;
    if tickData.ms1000 == false then return end;

    local characterClass: CharacterClass = statusClass.StatusOwner :: CharacterClass;
    local healthComp: HealthComp = characterClass.HealthComp;
    local playerWarmth = characterClass.Properties.Warmth;

    if playerWarmth < 0 then
        healthComp:TakeDamage(DamageData.new{
            Damage = healthComp.MaxHealth * 0.025;
            DamageType = "IgnoreArmor";
            TargetPart = characterClass.RootPart;
        });
    end
end

return modStatusClass.new(statusPackage);