local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local modifierPackage = {
	Name = "Crit Multipler";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	modItemModifierClass.AddTierDamage(modifier);
	
	local layerInfo = modItemModifierClass.Library.calculateLayer(modifier, "M");
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	if tweakVal then
		value = value + tweakVal;
	end

	modifier.MaxValues.CritMulti = value;
end

return modifierPackage;