local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);

function Mod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = modModsLibrary.GetLayer("BD", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;

	if tweakVal then
		value = value + math.ceil(tweakVal);
	end
	
	module.Configurations.EverlastDuration = (module.Configurations.EverlastDuration or 0) + value;
	module.Configurations.AmmoCost = 2;
	
	
	--local modStorageItem, module = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	--local info = ModsLibrary.Get(modStorageItem.ItemId);
	--local values = modStorageItem.Values;
	
	--local count = ModsLibrary.Linear(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, values["BD"], info.Upgrades[1].MaxLevel);
	--count = math.ceil(count);

	--if paramPacket.TweakStat and info.Upgrades[1].TweakBonus then
	--	local addBonus = info.Upgrades[1].TweakBonus * math.abs(paramPacket.TweakStat/100);

	--	count = count + math.ceil(addBonus);
	--end
	
	--module.Configurations.EverlastDuration = (module.Configurations.EverlastDuration or 0) + count;
	--module.Configurations.AmmoCost = 2;
	
end

return Mod;
