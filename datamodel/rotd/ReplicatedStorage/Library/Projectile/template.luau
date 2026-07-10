local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);
local modDamageTag = shared.require(game.ReplicatedStorage.Library.DamageTag);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local projectilePackage = {
	Id = script.Name;

	ArcTracerConfig = {
		Velocity = 50;
		Bounce = 0.9;
		MaxBounce = 32;
		LifeTime = 10;
		RayRadius = 1.5;
		Delta = 1/60;
	};

	Properties = {
		Damage = 100;
	};
};
--==

function projectilePackage.BindInstance(projectile: ProjectileInstance)
	projectile.Part = script:WaitForChild("Beachball"):Clone();
end

function projectilePackage.BindFire(projectile: ProjectileInstance)
end

function projectilePackage.BindArcContact(projectile: ProjectileInstance, arcPoint: ArcPoint)
    local hitPart = arcPoint.Hit;
    local hitPosition = arcPoint.Point;

    local projectilePart = projectile.Part;
    local properties = projectile.Properties;
end

function projectilePackage.BindArcStepped(projectile: ProjectileInstance, arcPoint: ArcPoint)
    local properties = projectile.Properties;
end

function projectilePackage.BindArcComplete(projectile: ProjectileInstance)
    local properties = projectile.Properties;
end

function projectilePackage.BindDestroy(projectile: ProjectileInstance)
    local properties = projectile.Properties;
end

return projectilePackage;