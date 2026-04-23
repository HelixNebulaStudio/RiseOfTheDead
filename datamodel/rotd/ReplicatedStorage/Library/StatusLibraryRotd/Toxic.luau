local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local RunService = game:GetService("RunService");
local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local statusPackage = {
    Id = "Toxic";
    Icon = "rbxassetid://12517601747";
    Name = "Toxic";
    Description = "You are taking toxic damage. Can be nullified by wearing a Gas Mask.";
    Buff = false;
    Tags = {"DOT";};
    Cleansable = true;
    ExpiresOnDeath = true;
};

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsClient() then return end;
    if tickData.ms500 ~= true then return end;

    local entityClass: EntityClass = statusClass.StatusOwner;
    local healthComp: HealthComp? = entityClass.HealthComp;
    if healthComp == nil or healthComp.IsDead then return end;

    local damageRatio = (statusClass.Values.DamageRatio or 0.2)/10;

    local configurations = (entityClass :: CharacterClass).Configurations;
    if configurations then
        local conGasMask = configurations.GasMask;
        if conGasMask then
            damageRatio = 0;
        end
    end

    local damage = healthComp.MaxHealth * damageRatio;
    if damage <= 0 then return end;
    
    local dmgData = DamageData.new{
        Damage = damage;
        DamageType = "IgnoreArmor";
    };
    healthComp:TakeDamage(dmgData);
end

return modStatusClass.new(statusPackage);