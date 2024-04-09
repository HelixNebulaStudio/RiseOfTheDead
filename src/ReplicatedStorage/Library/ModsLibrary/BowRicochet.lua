local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Mod = {};
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);
local modWeaponsAttributes = require(game.ReplicatedStorage.Library.WeaponsAttributes);

local modProjectileRicochet = require(game.ReplicatedStorage.Library.Projectile.Mechanics.Ricochet);

function Mod.Activate(packet)
	local module = packet.WeaponModule;

	local layerInfo = modModsLibrary.GetLayer("R", packet);
	local value, tweakVal = layerInfo.Value, layerInfo.TweakValue;
	
	if tweakVal then
		value = value + math.ceil(tweakVal);
	end

	module.ArcTracerConfig.Bounce = 1;
	module.ArcTracerConfig.LifeTime = 3;
	module.ArcTracerConfig.Velocity = 175;

	function module.ArcTracerConfig.OnStepped(projectile, arcPoint)
		modProjectileRicochet.OnStepped(projectile, arcPoint, value);
	end
	
	--local modStorageItem, module = paramPacket.ModStorageItem, paramPacket.WeaponModule;
	
	--local info = ModsLibrary.Get(modStorageItem.ItemId);
	--local values = modStorageItem.Values;

	--local radius = ModsLibrary.NaturalInterpolate(info.Upgrades[1].BaseValue, info.Upgrades[1].MaxValue, values["R"], info.Upgrades[1].MaxLevel);

	--if paramPacket.TweakStat and info.Upgrades[1].TweakBonus then
	--	local addBonus = info.Upgrades[1].TweakBonus * math.abs(paramPacket.TweakStat/100);

	--	radius = radius + math.ceil(addBonus);
	--end
	
	--module.ArcTracerConfig.Bounce = 1;
	--module.ArcTracerConfig.LifeTime = 3;
	--module.ArcTracerConfig.Velocity = 175;
	
	--function module.ArcTracerConfig.OnStepped(projectile, arcPoint)
	--	modProjectileRicochet.OnStepped(projectile, arcPoint, radius);
	--end
end

return Mod;