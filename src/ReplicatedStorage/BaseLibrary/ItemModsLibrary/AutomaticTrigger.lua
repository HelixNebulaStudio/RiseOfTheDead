
local modItemModProperties = require(game.ReplicatedStorage.Library.ItemModsLibrary.ItemModProperties);
local itemMod = modItemModProperties.new();

local modWeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);

function itemMod.Activate(packet)
	local module = packet.WeaponModule;

	module.Configurations.TriggerMode = modWeaponsAttributes.TriggerModes.Automatic;
end

return itemMod;