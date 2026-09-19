local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local modifierPackage = {
	Name = "Grip Resistance";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	local layerInfo = modItemModifierClass.Library.calculateLayer(modifier, "GR");
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + tweakVal;
	end

	modifier.SumValues.AdditionalStamina = math.ceil(value);
end

return modifierPackage;