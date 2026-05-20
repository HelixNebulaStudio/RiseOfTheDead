local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local RunService = game:GetService("RunService");

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local statusPackage = {
    Id = "MeleeBleed";
    Icon = "";
    Name = "Melee Bleed";
    Description = "";
    Buff = false;
};
--==

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsClient() then return end;
    if tickData.ms1000 == false then return end;
    
    local entityClass: EntityClass = statusClass.StatusOwner :: EntityClass;
    if entityClass.ClassName == "Destructible" then return end;

    local healthComp: HealthComp? = entityClass.HealthComp;
    if healthComp == nil or healthComp.IsDead then return end;
    
    local applyBy: CharacterClass? = statusClass.ApplyBy;
    if applyBy == nil or not healthComp:CanTakeDamageFrom(applyBy) then return end;

    local bleedDamage = math.ceil(statusClass.Values.Damage * (statusClass.Values.DamagePercent or 0.05));

    local toolHandler: ToolHandlerInstance? = statusClass.Values._ToolHandler;

    local dmgData = DamageData.new{
        DamageBy = applyBy;
        Damage = bleedDamage;
        DamageType = "Bleed";
        ToolHandler = toolHandler;
    };

    healthComp:TakeDamage(dmgData);
end


return modStatusClass.new(statusPackage);