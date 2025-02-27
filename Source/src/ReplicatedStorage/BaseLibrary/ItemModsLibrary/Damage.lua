local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModifierClass = require(game.ReplicatedStorage.Library.ItemModifierClass);

local ItemModifier = modItemModifierClass.new(script);

function ItemModifier:Update()
	local layerInfo = ItemModifier.Library.calculateLayer(self, "D");
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	if tweakVal then
		value = value + tweakVal;
	end

	local configurations = self.EquipmentClass.Configurations;

	local baseDamage = configurations.PreModDamage;
	local additionalDmg = baseDamage * value;

	self.AddValues.Damage = additionalDmg;
end

return ItemModifier;
