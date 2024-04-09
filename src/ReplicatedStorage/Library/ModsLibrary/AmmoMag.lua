local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);

function Mod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = modModsLibrary.GetLayer("M", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + tweakVal;
	end

	local baseAmmoMag = module.Configurations.BaseAmmoLimit;

	module.Configurations.AmmoLimit = module.Configurations.AmmoLimit + math.ceil(value);
	
	--local modStorageItem, module = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	--local info = ModsLibrary.Get(modStorageItem.ItemId);
	--local values = modStorageItem.Values;
	
	--local add = ModsLibrary.Linear(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, values["M"], info.Upgrades[1].MaxLevel);

	--if paramPacket.TweakStat and info.Upgrades[1].TweakBonus then
	--	local addBonus = math.floor(info.Upgrades[1].TweakBonus * math.abs(paramPacket.TweakStat/100));

	--	add = add + addBonus;
	--end
	
	--local baseAmmoMag = module.Configurations.BaseAmmoLimit;
	
	--module.Configurations.AmmoLimit = module.Configurations.AmmoLimit + math.ceil(add);
end

return Mod;
