local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);
local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local modifierPackage = {
	Name = "DamageDivider";
	
	Tags = {};
	Binds = {};
};
--==
function modifierPackage.onRequire()
	if RunService:IsClient() then return end;

	function modifierPackage.Binds.CharacterClassTakenDamage(modifier: ItemModifierInstance, damageData: DamageData)
		local characterClass: CharacterClass? = modifier.WieldComp and modifier.WieldComp.CompOwner or nil;
		if characterClass == nil then return end;
        if characterClass ~= damageData.DamageTo then return end;

        local healthComp: HealthComp = characterClass.HealthComp;
        if healthComp == nil then return end;
        
		if healthComp.CurArmor <= 0 then return end;

        local reduction = modifier.Values.DamageDividerReduction or 0;
        if reduction <= 0 then return end;

        local damage = damageData.Damage;
		if damage <= 0 then return end;
		
        local newDamage = (damage/2) * (1-reduction);
        damageData.Damage = newDamage;

        healthComp:TakeDamage(DamageData.new{
            Damage = newDamage;
            DamageType = "IgnoreArmor";
            BypassModifierBinds = true;
        });
	end
end

function modifierPackage.Update(modifier: ItemModifierInstance)
	local layerInfo = modItemModifierClass.Library.calculateLayer(modifier, "R");
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + tweakVal;
	end

	modifier.Values.DamageDividerReduction = value;
	modifier.ArrayValues.PassiveModifiers = "Damage Divider";
end


return modifierPackage;