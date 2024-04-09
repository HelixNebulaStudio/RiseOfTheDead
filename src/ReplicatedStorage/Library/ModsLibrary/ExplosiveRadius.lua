local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);

function Mod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = modModsLibrary.GetLayer("R", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + math.floor(tweakVal);
	end

	module.Configurations.ExplosionRadius = module.Configurations.ExplosionRadius + value;
	
	--local modStorageItem, module = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	--local info = ModsLibrary.Get(modStorageItem.ItemId);
	--local values = modStorageItem.Values;

	--local add = ModsLibrary.Linear(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, values["R"], info.Upgrades[1].MaxLevel);

	--if paramPacket.TweakStat and info.Upgrades[1].TweakBonus then
	--	local addBonus = info.Upgrades[1].TweakBonus * math.abs(paramPacket.TweakStat/100);

	--	add = add + math.floor(addBonus);
	--end
	
	--module.Configurations.ExplosionRadius = module.Configurations.ExplosionRadius + add;
end

return Mod;