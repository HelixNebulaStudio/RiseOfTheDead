local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local modifierPackage = {
	Name = "Fire Rate";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	modItemModifierClass.AddTierDamage(modifier);
	
	local layerInfo = modItemModifierClass.Library.calculateLayer(modifier, "FR");
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + math.ceil(tweakVal);
	end

	modifier.SumValues.Rpm = math.ceil(value);
end

return modifierPackage;