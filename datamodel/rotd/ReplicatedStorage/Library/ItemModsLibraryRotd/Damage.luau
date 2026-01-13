local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local modifierPackage = {
	Name = "Damage";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	local layerInfo = modItemModifierClass.Library.calculateLayer(modifier, "D");
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	if tweakVal then
		value = value + tweakVal;
	end

	assert(modifier.EquipmentClass, `Missing equipment class: {modifier}`);
	local tierDmg = modItemModifierClass.AddTierDamage(modifier);
	
	local configurations = modifier.EquipmentClass.Configurations;
	local baseDamage = configurations.PreModDamage;
	local additionalDmg = baseDamage * value;

	modifier.SumValues.Damage = additionalDmg + tierDmg;
end

return modifierPackage;