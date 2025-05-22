local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClass);

local modifierPackage = {
	Name = "Hyper Damage";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	local dLayerInfo = modItemModifierClass.Library.calculateLayer(modifier, "D");
	local dValue, dTweakVal = dLayerInfo.Value, dLayerInfo.TweakValue;
	if dTweakVal then
		dValue = dValue + dTweakVal;
	end

	local frLayerInfo = modItemModifierClass.Library.calculateLayer(modifier, "FR");
	local frValue, frTweakVal = frLayerInfo.Value, frLayerInfo.TweakValue;
	
	if frTweakVal then
		frValue = frValue + math.ceil(frTweakVal);
	end

	assert(modifier.EquipmentClass, `Missing equipment class: {modifier}`);
	local configurations = modifier.EquipmentClass.Configurations;

	local baseDamage = configurations.PreModDamage;
	local additionalDmg = baseDamage * dValue;

	modifier.SumValues.Damage = additionalDmg;
	modifier.SumValues.Rpm = frValue;
end

return modifierPackage;