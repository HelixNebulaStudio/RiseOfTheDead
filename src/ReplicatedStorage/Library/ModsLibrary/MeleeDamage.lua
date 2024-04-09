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
	
	local baseDamage = module.Configurations.BaseDamage;
	local additionalDmg = baseDamage * value;

	module.Configurations.Damage = module.Configurations.Damage + additionalDmg;
	
	--local modStorageItem, module = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	--local info = ModsLibrary.Get(modStorageItem.ItemId);
	--local values = modStorageItem.Values;
	
	--local muti = ModsLibrary.NaturalInterpolate(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, values["D"], info.Upgrades[1].MaxLevel);
	--local baseDamage = module.Configurations.BaseDamage;
	--local additionalDmg = baseDamage*muti;
	
	--module.Configurations.Damage = module.Configurations.Damage + additionalDmg;
end

return Mod;
