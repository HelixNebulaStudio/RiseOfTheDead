local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClass);

local modifierPackage = {
	Name = "Rapid Fire";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	local layerInfo = modItemModifierClass.Library.calculateLayer(modifier, "RFR");
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	if tweakVal then
		value = value + tweakVal;
	end

	assert(modifier.EquipmentClass, `Missing equipment class: {modifier}`);
	local configurations = modifier.EquipmentClass.Configurations;

	local baseAmmoLimit = configurations:GetBase("AmmoLimit");
	local rapidFireValue = (baseAmmoLimit * 60/configurations.Rpm/1.2) * (1-value);

	modifier.MinValues.RapidFire = rapidFireValue;
end

return modifierPackage;