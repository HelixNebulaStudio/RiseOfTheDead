local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);

function Mod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = modModsLibrary.GetLayer("AC", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;

	if layerInfo.UpgradeInfo.Scaling == 0 then
		if tweakVal then
			value = value + math.floor(tweakVal);
		end
		
		module.Configurations.MaxAmmoLimit = module.Configurations.MaxAmmoLimit + value;
		
	elseif layerInfo.UpgradeInfo.Scaling == 1 then
		if tweakVal then
			value = value + tweakVal;
		end

		local ammoLimit = module.Configurations.AmmoLimit;
		module.Configurations.MaxAmmoLimit = module.Configurations.MaxAmmoLimit + math.ceil(ammoLimit * value);
		
	end
	
	
	--local modStorageItem, module = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	--local info = ModsLibrary.Get(modStorageItem.ItemId);
	--local values = modStorageItem.Values;
	
	--if info.Upgrades[1].Scaling == 0 then
	--	local add = ModsLibrary.Linear(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, values["AC"], info.Upgrades[1].MaxLevel);

	--	if paramPacket.TweakStat and info.Upgrades[1].TweakBonus then
	--		add = add + math.floor(info.Upgrades[1].TweakBonus * math.abs(paramPacket.TweakStat/100));
	--	end
		
	--	module.Configurations.MaxAmmoLimit = module.Configurations.MaxAmmoLimit + add;
		
	--else
	--	local multi = ModsLibrary.NaturalInterpolate(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, values["AC"], info.Upgrades[1].MaxLevel, info.Upgrades[1].Rate);

	--	if paramPacket.TweakStat and info.Upgrades[1].TweakBonus then
	--		multi = multi + (info.Upgrades[1].TweakBonus * math.abs(paramPacket.TweakStat/100));
	--	end
		
	--	local ammoLimit = module.Configurations.AmmoLimit;
	--	module.Configurations.MaxAmmoLimit = module.Configurations.MaxAmmoLimit + math.ceil(ammoLimit * multi);
		
	--end
end

return Mod;
