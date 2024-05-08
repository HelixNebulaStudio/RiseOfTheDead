local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);

local modProjectileRicochet = require(game.ReplicatedStorage.Library.Projectile.Mechanics.Ricochet);

function Mod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = modModsLibrary.GetLayer("R", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + math.ceil(tweakVal);
	end

	module.ArcTracerConfig.MaxBounce = 1;
	module.ArcTracerConfig.LifeTime = 3;
	module.ArcTracerConfig.Velocity = 175;

	function module.ArcTracerConfig.OnStepped(projectile, arcPoint)
		modProjectileRicochet.OnStepped(projectile, arcPoint, value);
	end
end

return Mod;