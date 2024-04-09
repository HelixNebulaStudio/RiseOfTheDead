local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);

function Mod.Activate(packet)
	local module = packet.WeaponModule;

	local dLayerInfo = modModsLibrary.GetLayer("D", packet);
	local dValue, dTweakVal = dLayerInfo.Value, dLayerInfo.TweakValue;
	
	if dTweakVal then
		dValue = dValue + dTweakVal;
	end

	local aLayerInfo = modModsLibrary.GetLayer("A", packet);
	local aValue, aTweakVal = aLayerInfo.Value, aLayerInfo.TweakValue;
	
	if aTweakVal then
		aValue = aValue + aTweakVal;
	end
	
	
	local preModDamage = module.Configurations.PreModDamage;
	local additionalDmg = preModDamage * dValue;
	module.Configurations.Damage = module.Configurations.Damage + additionalDmg;

	if module.Configurations.Deadeye == nil or aValue > module.Configurations.Deadeye then
		module.Configurations.Deadeye = aValue;
		
	end
	
	
	--local modStorageItem, module = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	--local info = ModsLibrary.Get(modStorageItem.ItemId);
	--local values = modStorageItem.Values;
	
	--local dmgMulti = ModsLibrary.NaturalInterpolate(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, values["D"], info.Upgrades[1].MaxLevel);
	--local accMulti = ModsLibrary.NaturalInterpolate(info.Upgrades[2].BaseValue, info.Upgrades[2].MaxValue, values["A"], info.Upgrades[2].MaxLevel);
	
	--local preModDamage = module.Configurations.PreModDamage;
	
	--if paramPacket.TweakStat and info.Upgrades[1].TweakBonus then
	--	local addMulti = info.Upgrades[1].TweakBonus * math.abs(paramPacket.TweakStat/100);

	--	dmgMulti = dmgMulti + addMulti;
	--end
	
	--local additionalDmg = preModDamage*dmgMulti;
	--module.Configurations.Damage = module.Configurations.Damage + additionalDmg;
	
	--if module.Configurations.Deadeye == nil or accMulti > module.Configurations.Deadeye then

	--	if paramPacket.TweakStat and info.Upgrades[2].TweakBonus then
	--		local bonusAcc = info.Upgrades[2].TweakBonus * math.abs(paramPacket.TweakStat/100);

	--		accMulti = accMulti + bonusAcc;
	--	end
		
	--	module.Configurations.Deadeye = accMulti;
	--end
end

return Mod;