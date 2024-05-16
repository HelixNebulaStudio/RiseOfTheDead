local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);

function Mod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = modModsLibrary.GetLayer("KB", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + tweakVal;
	end
	
	local baseKnockback = module.Configurations.BaseKnockback or 0;
	local additional = baseKnockback * value;

	module.Configurations.Knockback = (module.Configurations.Knockback or baseKnockback) + additional;
end

return Mod;