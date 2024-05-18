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
	local frlevel, frValue, frTweak = frLayerInfo.Level, frLayerInfo.Value, frLayerInfo.TweakValue;
	
	if frTweak then
		frValue = frValue + math.floor(frTweak*10)/10;
	end
	
	module.Properties.Rpm = module.Properties.Rpm + frValue;

	if module.Configurations.ShotSplitter == nil or dmglevel > module.Configurations.ShotSplitter then
		module.Configurations.ShotSplitter = dmglevel;
		module.Properties.Multishot = 2;

		module.Configurations.Damage = module.Configurations.Damage * dmgValue;
	end
	
end

return Mod;