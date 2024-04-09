local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);
local modWeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);

function Mod.Activate(packet)
	local module = packet.WeaponModule;

	local baseCritMulti = module.Configurations.BaseCritMulti;
	if baseCritMulti == nil then return; end
	
	local layerInfo = modModsLibrary.GetLayer("M", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + tweakVal;
	end
	
	local muti = baseCritMulti + value;

	if module.Configurations.CritMulti == nil or module.Configurations.CritMulti < muti then
		module.Configurations.CritMulti = muti;
	end
	
	--local modStorageItem, module = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	--local info = ModsLibrary.Get(modStorageItem.ItemId);
	--local values = modStorageItem.Values;

	--local baseCritMulti = module.Configurations.BaseCritMulti;
	--if baseCritMulti == nil then return; end
		
	--local level = math.clamp((values["M"] or 0), 0, info.Upgrades[1].MaxLevel-paramPacket.TierOffset);
	--local muti = ModsLibrary.NaturalInterpolate(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, level, info.Upgrades[1].MaxLevel);

	--if paramPacket.TweakStat and info.Upgrades[1].TweakBonus then
	--	local addMulti = info.Upgrades[1].TweakBonus * math.abs(paramPacket.TweakStat/100);

	--	muti = muti + addMulti;
	--end

	--muti = baseCritMulti + muti;
	
	--if module.Configurations.CritMulti == nil or module.Configurations.CritMulti < muti then
	--	module.Configurations.CritMulti = muti;
	--end
end

return Mod;