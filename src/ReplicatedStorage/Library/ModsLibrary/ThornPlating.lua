local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);

function Mod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = modModsLibrary.GetLayer("R", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;

	if tweakVal then
		value = value + tweakVal;
	end
	
	if module.DamageReflection == nil or value > module.DamageReflection then
		module.DamageReflection = value;
	end
end

return Mod;