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

	local frLayerInfo = modModsLibrary.GetLayer("FR", packet);
	local frValue, frTweakVal = frLayerInfo.Value, frLayerInfo.TweakValue;

	if frTweakVal then
		frValue = frValue + frTweakVal;
	end
	
	
	local preModDmg = module.Configurations.PreModDamage;
	local additionalDmg = preModDmg * dValue;
	module.Configurations.Damage = module.Configurations.Damage + additionalDmg;
	module.Properties.Rpm = module.Properties.Rpm + frValue;
	
	
	--local modStorageItem, module = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	--local info = ModsLibrary.Get(modStorageItem.ItemId);
	--local values = modStorageItem.Values;
	
	--local dmgMulti = ModsLibrary.NaturalInterpolate(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, values["D"], info.Upgrades[1].MaxLevel);
	--local addRpm = ModsLibrary.NaturalInterpolate(info.Upgrades[2].BaseValue, info.Upgrades[2].MaxValue, values["FR"], info.Upgrades[2].MaxLevel, info.Upgrades[2].Rate);
	
	--local preModDmg = module.Configurations.PreModDamage;

	--if paramPacket.TweakStat and info.Upgrades[1].TweakBonus then
	--	local addMulti = info.Upgrades[1].TweakBonus * math.abs(paramPacket.TweakStat/100);

	--	dmgMulti = dmgMulti + addMulti;
	--end
	
	--local additionalDmg = preModDmg*dmgMulti;
	--module.Configurations.Damage = module.Configurations.Damage + additionalDmg;

	--if paramPacket.TweakStat and info.Upgrades[2].TweakBonus then
	--	local bonusRpm = info.Upgrades[2].TweakBonus * math.abs(paramPacket.TweakStat/100);

	--	addRpm = addRpm + bonusRpm;
	--end
	
	--module.Properties.Rpm = module.Properties.Rpm + addRpm;
end

return Mod;