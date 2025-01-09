local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modItemModProperties = require(game.ReplicatedStorage.Library.ItemModsLibrary.ItemModProperties);
local itemMod = modItemModProperties.new();

local modProjectileRicochet = require(game.ReplicatedStorage.Library.Projectile.Mechanics.Ricochet);

function itemMod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = itemMod.Library.GetLayer("R", packet);
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

return itemMod;