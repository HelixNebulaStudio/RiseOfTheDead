local RunService = game:GetService("RunService");

local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);
--==
local statusPackage = {
    Id="MaxHeal";
    Icon="rbxassetid://2770153676";
    Name="Healing From Healer";
    Description="Heals 10% of max health per second.";
    Buff=true;
};

function statusPackage.OnTick(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsClient() then return end;
    if tickData.ms500 == false then return end;

    local healthComp: HealthComp? = statusClass.StatusOwner.HealthComp;
    if healthComp == nil then return end;

    local healthPool = healthComp.MaxHealth;
    local armorPool = healthComp.MaxArmor;

    local rate = statusClass.Values.Rate or 0.1;

    local totalHeal = 0;

    if math.ceil(healthComp.CurHealth)+5 <= statusClass.Values.InitHealth then
        statusClass.Expires = workspace:GetServerTimeNow();
        return ;
    end

    local healAmount = (healthComp.MaxHealth * rate);
    healAmount = math.clamp(healAmount, 0, healthComp.MaxHealth-healthComp.CurHealth);

    if healAmount > 0 and healthPool > 0 then
        local dmgData = DamageData.new{
            Damage = healAmount;
            DamageType = "Heal";
        };

        -- Apply healing
        healthComp:TakeDamage(dmgData);

        healthPool = healthPool - healAmount;
        totalHeal = totalHeal + healAmount;
    end;

    if healthComp.CurArmor < healthComp.MaxArmor then
        local regenAmount = (healthComp.MaxArmor * (rate or 0.1));

        regenAmount = math.max(regenAmount, 1);
        regenAmount = math.clamp(regenAmount, 0, healthComp.MaxArmor-healthComp.CurArmor);

        if regenAmount > 0 and armorPool > 0 then
            healthComp:SetArmor(healthComp.CurArmor + regenAmount);

            armorPool = armorPool - regenAmount;
            totalHeal = totalHeal + regenAmount;
        end
    end

    if totalHeal <= 0 then
        statusClass.Expires = workspace:GetServerTimeNow();
        return;
    end

    return;
end

return modStatusClass.new(statusPackage);