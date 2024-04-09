local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);

function Mod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = modModsLibrary.GetLayer("D", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;

	if tweakVal then
		value = value + tweakVal;
	end

	module.Configurations.Damage = module.Configurations.Damage + value;
	
	
	
	--local modStorageItem, module = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	--local info = ModsLibrary.Get(modStorageItem.ItemId);
	--local values = modStorageItem.Values;
	
	--local add = ModsLibrary.Linear(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, values["D"], info.Upgrades[1].MaxLevel);
	
	--module.Configurations.Damage = module.Configurations.Damage + add;
end

return Mod;