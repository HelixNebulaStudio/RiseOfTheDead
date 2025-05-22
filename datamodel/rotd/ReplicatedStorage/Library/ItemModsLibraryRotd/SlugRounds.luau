local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClass);

local modifierPackage = {
	Name = "Flinch Protection";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	local layerInfo = modItemModifierClass.Library.calculateLayer(modifier, "P");
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + tweakVal;
	end

	assert(modifier.EquipmentClass, `Missing equipment class: {modifier}`);
	local configurations = modifier.EquipmentClass.Configurations;
	local baseInaccuracy = configurations.StandInaccuracy;
	local baseMultishot = configurations:GetBase("Multishot");
	local maxShots = baseMultishot and baseMultishot.Max or 1;

	modifier.SetValues.DamageScaler = (maxShots-1)/3;
	modifier.SetValues.Multishot = 3;
	modifier.SetValues.Inaccuracy = baseInaccuracy*0.2;

	if math.floor(value) ~= 0 then
		modifier.MaxValues.Piercing = math.floor(value);
	end
end

return modifierPackage;