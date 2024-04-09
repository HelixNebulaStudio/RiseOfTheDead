local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);
local modWeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);

function Mod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = modModsLibrary.GetLayer("AC", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + tweakVal;
	end
	
	local ammoLimit = module.Configurations.AmmoLimit;

	module.Configurations.MaxAmmoLimit = module.Configurations.MaxAmmoLimit + math.ceil(ammoLimit * value);
	module.Configurations.TriggerMode = modWeaponsAttributes.TriggerModes.Automatic;
	
	--local modStorageItem, module = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	--local info = ModsLibrary.Get(modStorageItem.ItemId);
	--local values = modStorageItem.Values;
	

	--local multi = ModsLibrary.NaturalInterpolate(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, values["AC"], info.Upgrades[1].MaxLevel, info.Upgrades[1].Rate);
	--local ammoLimit = module.Configurations.AmmoLimit;

	--if paramPacket.TweakStat and info.Upgrades[1].TweakBonus then
	--	multi = multi + (info.Upgrades[1].TweakBonus * math.abs(paramPacket.TweakStat/100));
	--end
	
	--module.Configurations.MaxAmmoLimit = module.Configurations.MaxAmmoLimit + math.ceil(ammoLimit * multi);
	--module.Configurations.TriggerMode = modWeaponsAttributes.TriggerModes.Automatic;
end

return Mod;