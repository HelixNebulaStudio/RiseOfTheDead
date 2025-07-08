local modStatusClass = shared.require(game.ReplicatedStorage.Library.StatusLibrary.StatusClass);
--==
local RunService = game:GetService("RunService");
local modDamageTag = shared.require(game.ReplicatedStorage.Library.DamageTag);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local statusPackage = {
    Id="MeleeBleed";
    Icon="";
    Name="Melee Bleed";
    Description="";
    Buff=false;
};
--==

function statusPackage.BindTickUpdate(statusClass: StatusClassInstance, tickData: TickData)
    if RunService:IsClient() then return end;
    if tickData.ms1000 == false then return end;
    
    local characterClass: CharacterClass = statusClass.StatusOwner;
    local healthComp: HealthComp? = characterClass.HealthComp;
    if healthComp == nil or healthComp.IsDead then return end;
    
    local applyBy: CharacterClass = statusClass.Values.ApplyBy;
    if not healthComp:CanTakeDamageFrom(applyBy) then return end;

    modDamageTag.Tag(characterClass.Character, applyBy.Character, {
        WeaponItemId = statusClass.Values.WeaponSiid;
        IsHeadshot = false;
    });

    local bleedDamage = math.ceil(statusClass.Values.Damage * (statusClass.Values.DamagePercent or 0.05));

    local dmgData = DamageData.new{
        Damage = bleedDamage;
        DamageType = "Bleed";
    };

    healthComp:TakeDamage(dmgData);
end


return modStatusClass.new(statusPackage);