local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modWeaponAttributes = shared.require(game.ReplicatedStorage.Library.WeaponsLibrary.WeaponAttributes);
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

local modifierPackage = {
	Name = "Flinch Protection";
	
	Tags = {};
	Binds = {};
};
--==

function modifierPackage.Update(modifier: ItemModifierInstance)
	local layerInfo = modItemModifierClass.Library.calculateLayer(modifier, "AC");
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	assert(modifier.EquipmentClass, `Missing equipment class: {modifier}`);
	modItemModifierClass.AddTierDamage(modifier);
	local configurations = modifier.EquipmentClass.Configurations;
	
	if layerInfo.UpgradeInfo.Scaling == 0 then
		if tweakVal then
			value = value + math.floor(tweakVal);
		end

		modifier.SumValues.AmmoCapacity = value;

	elseif layerInfo.UpgradeInfo.Scaling == 1 then
		if tweakVal then
			value = value + tweakVal;
		end

		local baseMagazineSize = configurations:GetBase("MagazineSize");
		modifier.SumValues.AmmoCapacity = math.ceil(baseMagazineSize * value);

	end

	modifier.SetValues.TriggerMode = modWeaponAttributes.TriggerModes.Automatic;
end

return modifierPackage;