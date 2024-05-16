local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);

function Mod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = modModsLibrary.GetLayer("D", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + tweakVal;
	end
	
	local baseKnockoutDuration = module.Configurations.BaseKnockoutDuration or 0;
	local new = baseKnockoutDuration + value;

	if module.Configurations.KnockoutDuration == nil or module.Configurations.KnockoutDuration < new then
		module.Configurations.KnockoutDuration = new;
	end
end

return Mod;