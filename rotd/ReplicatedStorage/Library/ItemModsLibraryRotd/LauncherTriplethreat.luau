local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local modifierPackage = {
	Name = "Launcher Triple Threat";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	local layerInfo = modItemModifierClass.Library.calculateLayer(modifier, "RT");
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	if tweakVal then
		value = value + tweakVal;
	end

	assert(modifier.EquipmentClass, `Missing equipment class: {modifier}`);
	modItemModifierClass.AddTierDamage(modifier);
	
	local configurations = modifier.EquipmentClass.Configurations;

	local baseReloadTime = configurations:GetBase("ReloadTime");
	local reloadtimeReduction = baseReloadTime * value;
	local newReloadTime = math.clamp(baseReloadTime-reloadtimeReduction, 0.0333, 100);

	modifier.MinValues.ReloadTime = newReloadTime;
	
	modifier.SetValues.Triplethreat = true;
end

return modifierPackage;