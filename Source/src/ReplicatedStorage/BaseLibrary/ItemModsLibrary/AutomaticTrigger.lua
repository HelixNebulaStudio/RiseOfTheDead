
local modItemModProperties = require(game.ReplicatedStorage.Library.ItemModsLibrary.ItemModProperties);
local itemMod = modItemModProperties.new();

local modWeaponAttributes = require(game.ReplicatedStorage.Library.Weapons.WeaponAttributes);

function itemMod.Activate(packet)
	local module = packet.WeaponModule;

	module.Configurations.TriggerMode = modWeaponAttributes.TriggerModes.Automatic;
end

return itemMod;