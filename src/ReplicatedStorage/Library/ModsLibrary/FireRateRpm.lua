local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);

function Mod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = modModsLibrary.GetLayer("FR", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + math.ceil(tweakVal);
	end

	module.Properties.Rpm = module.Properties.Rpm + value;
	
	
	--local modStorageItem, module = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	--local info = ModsLibrary.Get(modStorageItem.ItemId);
	--local values = modStorageItem.Values;
	
	--local addRpm = ModsLibrary.NaturalInterpolate(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, values["FR"], info.Upgrades[1].MaxLevel, info.Upgrades[1].Rate);

	--if paramPacket.TweakStat and info.Upgrades[1].TweakBonus then
	--	local addBonus = info.Upgrades[1].TweakBonus * math.abs(paramPacket.TweakStat/100);

	--	addRpm = addRpm + math.ceil(addBonus);
	--end
	
	--module.Properties.Rpm = module.Properties.Rpm + addRpm;
end

return Mod;
