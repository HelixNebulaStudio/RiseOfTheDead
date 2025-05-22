local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClass);

local modifierPackage = {
	Name = "Bow Deadweight";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	local wLayerInfo = modItemModifierClass.Library.calculateLayer(modifier, "W");
	local wValue, wTweakVal = wLayerInfo.Value, wLayerInfo.TweakValue;
	if wTweakVal then
		wValue = wValue + wTweakVal;
	end


	local dLayerInfo = modItemModifierClass.Library.calculateLayer(modifier, "D");
	local dValue, dTweakVal = dLayerInfo.Value, dLayerInfo.TweakValue;
	if dTweakVal then
		dValue = dValue + dTweakVal;
	end
	
	assert(modifier.EquipmentClass, `Missing equipment class: {modifier}`);
	local configurations = modifier.EquipmentClass.Configurations;

	modifier.SetValues.ProjectileConfig = {
		Velocity = 100;
		MaxBounce = wValue;
		KeepAcceleration = true;
	};

	local baseDamage = configurations.PreModDamage;
	local additionalDmg = baseDamage * dValue;

	modifier.SumValues.Damage = additionalDmg; --MARK: TODO stacking check.
end

return modifierPackage;