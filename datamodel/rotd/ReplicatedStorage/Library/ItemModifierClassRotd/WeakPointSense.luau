local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modifierPackage = {
	Name = "Weak Point Sense";

	Tags = {};
	Binds = {};
};

function modifierPackage.Binds.Update(modifier: ItemModifierInstance)
	local skillData = modifier.Properties.SkillData;
	local percent = skillData.Stats.Percent;
	
    local wpMulti = percent.Value/100;
    modifier.SumValues.WeakPointMultiplier = wpMulti;
end

if RunService:IsServer() then
    function modifierPackage.Binds.WeaponShotDamageDataNew(modifier: ItemModifierInstance, ...)
        local damageData: DamageData = ...;
        if damageData == nil then return end;
        
        local damageTo: NpcClass = damageData.DamageTo :: NpcClass;
        if damageTo.ClassName ~= "NpcClass" then return end;

        local wieldComp: WieldComp? = modifier.WieldComp;
        if wieldComp == nil then return end;
        if wieldComp.EquipmentClass == nil then return end;
        
        local weaponConfigurations = wieldComp.EquipmentClass.Configurations;
        local preModDamage = weaponConfigurations.PreModDamage;
        if preModDamage == nil then return end;

        local damageBy: PlayerClass = wieldComp.CompOwner :: PlayerClass;
        if damageBy == nil then return end;

        local targetPart: BasePart = damageData.TargetPart;
        if targetPart == nil then return end;

        local weakPointComp = damageTo:AddComponent("WeakPoint");
        if weakPointComp == nil then return end;
        
        weakPointComp(targetPart, function()
            -- if targetPart is weak point part.
            local damage = damageData.Damage;
            local wpMulti = 0;

            if weaponConfigurations.WeakPointMultiplier then -- From Weapon
                wpMulti += weaponConfigurations.WeakPointMultiplier;
            end
            if damageBy.Configurations.WeakPointMultiplier then -- From Skilltree
                wpMulti += damageBy.Configurations.WeakPointMultiplier;
            end
            if wpMulti <= 0 then return end;
            
            damage += preModDamage * wpMulti;

            damageData.Damage = damage;
            damageData.DamageType = "Crit";
        end);
    end
end

return modifierPackage;