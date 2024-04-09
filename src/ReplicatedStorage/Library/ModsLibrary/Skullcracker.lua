local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);

function Mod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = modModsLibrary.GetLayer("HSM", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;

	if tweakVal then
		value = value + tweakVal;
	end
	
	local baseHeadshotMultiplier = module.Configurations.BaseHeadshotMultiplier or 0;

	module.Configurations.HeadshotMultiplier = baseHeadshotMultiplier + value;
	
	--local modStorageItem, module = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	--local info = ModsLibrary.Get(modStorageItem.ItemId);
	--local values = modStorageItem.Values;
	
	--local muti = ModsLibrary.NaturalInterpolate(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, values["HSM"], info.Upgrades[1].MaxLevel);
	--local baseHeadshotMultiplier = module.Configurations.BaseHeadshotMultiplier or 0;

	--if paramPacket.TweakStat and info.Upgrades[1].TweakBonus then
	--	local addMulti = info.Upgrades[1].TweakBonus * math.abs(paramPacket.TweakStat/100);

	--	muti = muti + addMulti;
	--end
	
	--module.Configurations.HeadshotMultiplier = baseHeadshotMultiplier + muti;
end

return Mod;
