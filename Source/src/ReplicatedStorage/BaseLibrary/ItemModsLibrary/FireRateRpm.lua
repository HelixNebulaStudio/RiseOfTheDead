local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModifierClass = require(game.ReplicatedStorage.Library.ItemModifierClass);

local ItemModifier = modItemModifierClass.new(script);

function ItemModifier:Update()
	local layerInfo = ItemModifier.Library.calculateLayer(self, "FR");
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + math.ceil(tweakVal);
	end

	self.AddValues.Rpm = value;
end

return ItemModifier;
