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

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsClient() then return end;
    if tickData.ms1000 == false then return end;

    local healthComp: HealthComp? = statusClass.StatusOwner.HealthComp;
    if healthComp == nil then return end;

    local rate = statusClass.Values.Rate or 0.1;

    if math.ceil(healthComp.CurHealth) < statusClass.Values.LastHealth then
        statusClass.Expires = workspace:GetServerTimeNow();
        return ;
    end

    local healAmount = (healthComp.MaxHealth * rate);

    local healPool = statusClass.Values.HealPool;
    if healPool == nil then
        healPool = healthComp.MaxHealth - healthComp.CurHealth;
    else
        healPool = math.max(healPool - healAmount, 0);
    end
    statusClass.Values.HealPool = healPool;
    
    
    local dmgData = DamageData.new{
        Damage = healAmount;
        DamageType = "Heal";
    };
    healthComp:TakeDamage(dmgData);
    statusClass.Values.LastHealth = healthComp.CurHealth;

    if healthComp.CurArmor < healthComp.MaxArmor then
        local regenAmount = (healthComp.MaxArmor * (rate or 0.1));

        regenAmount = math.max(regenAmount, 1);
        regenAmount = math.clamp(regenAmount, 0, healthComp.MaxArmor-healthComp.CurArmor);

        if regenAmount > 0 then
            healthComp:SetArmor(healthComp.CurArmor + regenAmount);
        end
    end

    
    if healPool <= 0 then
        statusClass.Expires = workspace:GetServerTimeNow();
        return;
    end

    return;
end

return modStatusClass.new(statusPackage);