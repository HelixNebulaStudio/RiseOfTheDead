local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);

function Mod.Activate(packet)
	local module = packet.WeaponModule;
	
	local layerInfo = modModsLibrary.GetLayer("AC", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + tweakVal;
	end

	if module.Configurations.BaseMaxAmmo == nil then
		module.Configurations.BaseMaxAmmo = module.Configurations.MaxAmmoLimit;
	end
	local baseMaxAmmo = module.Configurations.BaseMaxAmmo;

	module.Configurations.MaxAmmoLimit = module.Configurations.MaxAmmoLimit + math.ceil(baseMaxAmmo * value);
	
	
	--local modStorageItem, module = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	--local info = ModsLibrary.Get(modStorageItem.ItemId);
	--local values = modStorageItem.Values;
	
	--local multi = ModsLibrary.NaturalInterpolate(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, values["AC"], info.Upgrades[1].MaxLevel, info.Upgrades[1].Rate);

	--if paramPacket.TweakStat and info.Upgrades[1].TweakBonus then
	--	multi = multi + (info.Upgrades[1].TweakBonus * math.abs(paramPacket.TweakStat/100));
	--end
	
	--if module.Configurations.BaseMaxAmmo == nil then
	--	module.Configurations.BaseMaxAmmo = module.Configurations.MaxAmmoLimit;
	--end
	--local baseMaxAmmo = module.Configurations.BaseMaxAmmo;
	
	--module.Configurations.MaxAmmoLimit = module.Configurations.MaxAmmoLimit + math.ceil(baseMaxAmmo * multi);
end

return Mod;
