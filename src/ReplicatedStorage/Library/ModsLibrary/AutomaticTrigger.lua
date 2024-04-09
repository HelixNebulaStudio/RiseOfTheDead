local Mod = {};
local ModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);
local modWeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);

function Mod.Activate(packet)
	local module = packet.WeaponModule;

	module.Configurations.TriggerMode = modWeaponsAttributes.TriggerModes.Automatic;
end

return Mod;
