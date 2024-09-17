local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);

function Mod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = modModsLibrary.GetLayer("F", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;

	if tweakVal then
		value = value + tweakVal;
	end
	
	local baseRpm = module.Properties.BaseRpm;
	local skullBurstRpm = baseRpm * value;

	if module.Configurations.SkullBurst == nil or skullBurstRpm > module.Configurations.SkullBurst then
		module.Configurations.SkullBurst = skullBurstRpm;
	end
end

return Mod;