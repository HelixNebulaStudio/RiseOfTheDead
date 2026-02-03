local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local modifierPackage = {
	Name = "Melee Knockback";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	if modifier.EquipmentClass == nil then return end;

	local layerInfo = modItemModifierClass.Library.calculateLayer(modifier, "KB");
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + tweakVal;
	end

    local configurations = modifier.EquipmentClass.Configurations;
    local baseKnockback = configurations:GetBase("Knockback");

	modifier.SumValues.Knockback = baseKnockback * value;
end

return modifierPackage;