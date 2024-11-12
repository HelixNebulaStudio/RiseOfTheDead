
local modClassItemMod = require(script.Parent:WaitForChild("ClassItemMod"));
local itemMod = modClassItemMod.new();

local modWeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);

function itemMod.Activate(packet)
	local module = packet.WeaponModule;

	module.Configurations.TriggerMode = modWeaponsAttributes.TriggerModes.Automatic;
end

return itemMod;