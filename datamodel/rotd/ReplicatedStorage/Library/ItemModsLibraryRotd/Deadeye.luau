local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClass);

local modifierPackage = {
	Name = "Deadeye";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	local dLayerInfo = modItemModifierClass.Library.calculateLayer(modifier, "D");
	local dValue, dTweakValue = dLayerInfo.Value, dLayerInfo.TweakValue;
	if dTweakValue then
		dValue = dValue + dTweakValue;
	end

	local aLayerInfo = modItemModifierClass.Library.calculateLayer(modifier, "A");
	local aValue, aTweakValue = aLayerInfo.Value, aLayerInfo.TweakValue;
	if aTweakValue then
		aValue = aValue + aTweakValue;
	end

	assert(modifier.EquipmentClass, `Missing equipment class: {modifier}`);
	local configurations = modifier.EquipmentClass.Configurations;

	local baseDamage = configurations.PreModDamage;
	local additionalDmg = baseDamage * dValue;

	modifier.SumValues.Damage = additionalDmg;
	modifier.MaxValues.Deadeye = aValue;
end

return modifierPackage;