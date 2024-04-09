local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);
local modWeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);

function Mod.Activate(packet)
	local module = packet.WeaponModule;
	
	if module.Configurations.Flameburst == nil then
		module.Configurations.Flameburst = true;

		module.Properties.Multishot = 3;
		module.Configurations.ModInaccuracy = 16;
		module.Configurations.ProjectileId = "gasFlame";
	end
	
	--local modStorageItem, module = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	--local info = ModsLibrary.Get(modStorageItem.ItemId);
	--local values = modStorageItem.Values;
	
	--if module.Configurations.Flameburst == nil then
	--	module.Configurations.Flameburst = true;

	--	module.Properties.Multishot = 3;
	--	module.Configurations.ModInaccuracy = 16;
	--	module.Configurations.ProjectileId = "gasFlame";
	--end
end

return Mod;