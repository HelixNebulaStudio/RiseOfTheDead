local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClass);

local modifierPackage = {
	Name = "Ammo Magazine";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	local layerInfo = modItemModifierClass.Library.calculateLayer(modifier, "M");
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	if tweakVal then
		value = value + tweakVal;
	end

	modifier.SumValues.MagazineSize = math.ceil(value);
end

return modifierPackage;