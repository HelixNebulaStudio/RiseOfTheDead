local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modExplosionHandler = shared.require(game.ReplicatedStorage.Library.ExplosionHandler);

local projectilePackage = {
	Id = script.Name;

	ArcTracerConfig = {
		Velocity = 300;
		LifeTime = 20;
		Bounce = 0;
		Delta = 1/60;
        Acceleration = Vector3.new(0, -workspace.Gravity, 0);
	};

	Properties = {
		Damage = 100;
	};
};
--==

function projectilePackage.BindInstance(projectile: ProjectileInstance)
	projectile.Part = script:WaitForChild("Grenade"):Clone();
end

function projectilePackage.BindArcContact(projectile: ProjectileInstance, arcPoint: ArcPoint)
    local properties = projectile.Properties;
    if properties.TriggerOnce then return end;
    properties.TriggerOnce = true;

    local projectilePart = projectile.Part;
    
    modAudio.Play(math.random(1,2)==1 and "Explosion" or "Explosion2", projectilePart);
    projectilePart.Transparency = 1;
    
    if not RunService:IsServer() then return end;

    local damage = properties.Damage;
    local minDamage = properties.MinDamage or 50;
    local damageRatio = properties.DamageRatio or 0.1;
    local explosionRadius = properties.ExplosionRadius or 25;
    local explosionStun = properties.ExplosionStun;
    
    
    local lastPosition = arcPoint.Point;
    
    local ex = Instance.new("Explosion");
    ex.DestroyJointRadiusPercent = 0;
    ex.BlastRadius = explosionRadius;
    ex.BlastPressure = 0;
    ex.Position = lastPosition;
    ex.Parent = workspace;
    Debugger.Expire(ex, 1);
    projectilePart.Transparency = 1;
    
    
    local hitLayers = modExplosionHandler:Cast(lastPosition, {
        Radius = explosionRadius;
    });
    
    modExplosionHandler:Process(lastPosition, hitLayers, {
        ExplosionBy = projectile.CharacterClass;
        StorageItem = projectile.StorageItem;

        Damage = damage;
        MinDamage = minDamage;
        ExplosionStun = explosionStun;
        DamageRatio = damageRatio;

        DamageOrigin = lastPosition;
        OnPartHit = modExplosionHandler.GenericOnPartHit;

        BindDamageDataNew = function(dmgData: DamageData)
            projectile:PreTakeDamageDamageData(dmgData);
        end;
    });
end

return projectilePackage;