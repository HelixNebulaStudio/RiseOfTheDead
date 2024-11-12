local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modClassItemMod = require(script.Parent:WaitForChild("ClassItemMod"));
local itemMod = modClassItemMod.new();

function itemMod.Activate(packet)
	local module = packet.WeaponModule;
	
	local dmgLayerInfo = itemMod.Library.GetLayer("D", packet);
	local dmglevel, dmgValue, dmgTweak = dmgLayerInfo.Level, dmgLayerInfo.Value, dmgLayerInfo.TweakValue;
	
	if dmgTweak then
		dmgValue = dmgValue + dmgTweak;
	end
	

	local frLayerInfo = itemMod.Library.GetLayer("FR", packet);
	local _frlevel, frValue, frTweak = frLayerInfo.Level, frLayerInfo.Value, frLayerInfo.TweakValue;
	
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

return itemMod;