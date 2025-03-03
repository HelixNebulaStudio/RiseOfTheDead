local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModifierClass = require(game.ReplicatedStorage.Library.ItemModifierClass);

local ItemModifier: ItemModifier = modItemModifierClass.new(script);

function ItemModifier:Update()
	local layerInfo = ItemModifier.Library.calculateLayer(self, "HP");
	local value = layerInfo.Value;

	self.SumValues.HealthPoints = value;
end

return ItemModifier;
