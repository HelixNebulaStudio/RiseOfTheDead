local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClass);

local modifierPackage = {
	Name = "Belt Slots";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	local layerInfo = modItemModifierClass.Library.calculateLayer(modifier, "S");
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	modifier.SumValues.HotEquipSlots = value;
end

return modifierPackage;