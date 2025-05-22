local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClass);

local modifierPackage = {
	Name = "Ammo Capacity";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	local layerInfo = modItemModifierClass.Library.calculateLayer(modifier, "AC");
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;

	assert(modifier.EquipmentClass, `Missing equipment class: {modifier}`);
	local configurations = modifier.EquipmentClass.Configurations;
	
	if layerInfo.UpgradeInfo.Scaling == 0 then
		if tweakVal then
			value = value + math.floor(tweakVal);
		end

		modifier.SumValues.AmmoCapacity = value;

	elseif layerInfo.UpgradeInfo.Scaling == 1 then
		if tweakVal then
			value = value + tweakVal;
		end

		local baseMagazineSize = configurations:GetBase("MagazineSize");
		modifier.SumValues.AmmoCapacity = math.ceil(baseMagazineSize * value);

	end
end

return modifierPackage;