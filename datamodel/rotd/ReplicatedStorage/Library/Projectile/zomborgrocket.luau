local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modExplosionHandler = shared.require(game.ReplicatedStorage.Library.ExplosionHandler);

local projectilePackage = {
	Id = script.Name;

	ArcTracerConfig = {
		LifeTime = 5;
		Velocity = 30;
		Bounce = 0;
		Acceleration = Vector3.new(0, -150, 0);
		IgnoreEntities = true;
	};

	Properties = {
        Activated = false;
		Damage = 15;
        ExplosionRadius = 16;
	};
};
--==

function projectilePackage.BindInstance(projectile: ProjectileInstance)
	projectile.Part = script:WaitForChild("Rocket"):Clone();
end

function projectilePackage.BindFire(projectile: ProjectileInstance)
    local projectilePart = projectile.Part;

    Debugger.Expire(projectilePart, projectile.ArcTracerConfig.LifeTime);
    modAudio.Play("RocketLoop", projectilePart);
end

function projectilePackage.BindArcContact(projectile: ProjectileInstance, arcPoint: ArcPoint)
    local properties = projectile.Properties;

    if properties.Activated then return end;
    properties.Activated = true;

    local projectilePart = projectile.Part;

    projectilePart.Transparency = 1;
    if RunService:IsServer() then
        local lastPosition = arcPoint.Point;
        
        local pointAtt = Debugger:Point(lastPosition);
        modAudio.Play(math.random(1, 2)==1 and "Explosion" or "Explosion2", pointAtt);

        local ex = Instance.new("Explosion");
        ex.DestroyJointRadiusPercent = 0;
        ex.BlastRadius = properties.ExplosionRadius or 16;
        ex.BlastPressure = 0;
        ex.Position = lastPosition;
        ex.Parent = workspace;
        
        Debugger.Expire(pointAtt, 6);
        Debugger.Expire(ex, 6);
        
        local hitLayers = modExplosionHandler:Cast(lastPosition, {
            Radius = properties.ExplosionRadius;
        });

        local damage = properties.Damage;

        modExplosionHandler:Process(lastPosition, hitLayers, {
            Damage = damage;
            ExplosionBy = projectile.CharacterClass;
            ExplosionForce = 0;

            DamageOrigin = lastPosition;
            OnPartHit = modExplosionHandler.GenericOnPartHit;
        });
    else
        task.wait();
    end
    Debugger.Expire(projectilePart, 0);
end

return projectilePackage;