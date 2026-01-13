local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local modifierPackage = {
	Name = "Deadeye";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	local aLayerInfo = modItemModifierClass.Library.calculateLayer(modifier, "A");
	local aValue, aTweakValue = aLayerInfo.Value, aLayerInfo.TweakValue;
	if aTweakValue then
		aValue = aValue + aTweakValue;
	end

	assert(modifier.EquipmentClass, `Missing equipment class: {modifier}`);
	modItemModifierClass.AddTierDamage(modifier);

	modifier.MaxValues.Deadeye = aValue;
end

return modifierPackage;