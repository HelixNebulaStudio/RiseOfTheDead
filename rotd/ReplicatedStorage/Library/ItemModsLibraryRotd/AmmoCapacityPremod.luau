local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local modifierPackage = {
	Name = "Premod Ammo Capacity";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	local layerInfo = modItemModifierClass.Library.calculateLayer(modifier, "AC");
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	if tweakVal then
		value = value + tweakVal;
	end

	assert(modifier.EquipmentClass, `Missing equipment class: {modifier}`);
	modItemModifierClass.AddTierDamage(modifier);
	
	local configurations = modifier.EquipmentClass.Configurations;

	local baseMaxAmmoLimit = configurations:GetBase("MaxAmmoLimit");

	modifier.SumValues.MaxAmmoLimit = math.ceil(baseMaxAmmoLimit * value);
end

return modifierPackage;