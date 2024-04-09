local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};
local ModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);

function Mod.Activate(packet)
	local module = packet.WeaponModule;
	
	local dmgLayerInfo = ModsLibrary.GetLayer("D", packet);
	local dmglevel, dmgValue, dmgTweak = dmgLayerInfo.Level, dmgLayerInfo.Value, dmgLayerInfo.TweakValue;
	
	if dmgTweak then
		dmgValue = dmgValue + dmgTweak;
	end
	

	local frLayerInfo = ModsLibrary.GetLayer("FR", packet);
	local frlevel, frValue, frTweak = dmgLayerInfo.Level, dmgLayerInfo.Value, dmgLayerInfo.TweakValue;
	
	if frTweak then
		frValue = frValue + math.floor(frTweak*10)/10;
	end
	
	module.Properties.Rpm = module.Properties.Rpm + frValue;

	if module.Configurations.ShotSplitter == nil or dmglevel > module.Configurations.ShotSplitter then
		module.Configurations.ShotSplitter = dmglevel;
		module.Properties.Multishot = 2;

		module.Configurations.Damage = module.Configurations.Damage * dmgValue;
	end
	
	
	--local dmglevel = math.clamp((values["D"] or 0), 0, info.Upgrades[1].MaxLevel-paramPacket.TierOffset);
	--local dmgRatio = ModsLibrary.NaturalInterpolate(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, dmglevel, info.Upgrades[1].MaxLevel);

	--if paramPacket.TweakStat and info.Upgrades[1].TweakBonus then
	--	local addMulti = info.Upgrades[1].TweakBonus * math.abs(paramPacket.TweakStat/100);

	--	dmgRatio = dmgRatio + addMulti;
	--end
	
	--local baseDamage = module.Configurations.BaseDamage;
	--local baseFireRate = module.Properties.BaseFireRate;
	--local baseMultishot = module.Properties.BaseMultishot;
	
	---- FireRate
	--local frlevel = math.clamp((values["FR"] or 0), 0, info.Upgrades[2].MaxLevel-paramPacket.TierOffset);
	--local addRpm = ModsLibrary.NaturalInterpolate(info.Upgrades[2].BaseValue, info.Upgrades[2].MaxValue, frlevel, info.Upgrades[2].MaxLevel, info.Upgrades[2].Rate);

	--if paramPacket.TweakStat and info.Upgrades[2].TweakBonus then
	--	local bonusRpm = info.Upgrades[2].TweakBonus * math.abs(paramPacket.TweakStat/100);

	--	addRpm = addRpm + math.floor(bonusRpm*10)/10;
	--end
	
	--module.Properties.Rpm = module.Properties.Rpm + addRpm;
	
	--if module.Configurations.ShotSplitter == nil or dmglevel > module.Configurations.ShotSplitter then
	--	module.Configurations.ShotSplitter = dmglevel;
	--	module.Properties.Multishot = 2;
		
	--	module.Configurations.Damage = module.Configurations.Damage * dmgRatio;
	--end
end

return Mod;