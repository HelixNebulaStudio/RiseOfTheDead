local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModProperties = require(game.ReplicatedStorage.Library.ItemModsLibrary.ItemModProperties);
local itemMod = modItemModProperties.new();

local modWeaponAttributes = require(game.ReplicatedStorage.Library.Weapons.WeaponAttributes);

function itemMod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = itemMod.Library.GetLayer("AC", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + tweakVal;
	end
	
	local ammoLimit = module.Configurations.AmmoLimit;

	module.Configurations.MaxAmmoLimit = module.Configurations.MaxAmmoLimit + math.ceil(ammoLimit * value);
	module.Configurations.TriggerMode = modWeaponAttributes.TriggerModes.Automatic;
end

return itemMod;