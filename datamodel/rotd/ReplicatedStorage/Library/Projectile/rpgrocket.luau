local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modExplosionHandler = shared.require(game.ReplicatedStorage.Library.ExplosionHandler);

local projectilePackage = {
	Id = script.Name;

	ArcTracerConfig = {
		Velocity = 200;
		Bounce = 0;
		LifeTime = 10;
		Acceleration = Vector3.new(0, -workspace.Gravity/32, 0);
		RayRadius = 0.25;
	};

	Properties = {
		Damage = 100;
        ExplosionRadius = 20;
		ExplosionStun = 1;
		DamageRatio = 0.05;
	};
};
--==

function projectilePackage.BindInstance(projectile: ProjectileInstance)
	projectile.Part = script:WaitForChild("Rocket"):Clone();
end

function projectilePackage.BindFire(projectile: ProjectileInstance)
    local projectilePart = projectile.Part;

    modAudio.Play("RocketLoop", projectilePart);
end

function projectilePackage.BindArcContact(projectile: ProjectileInstance, arcPoint: ArcPoint)
    local properties = projectile.Properties;
    local projectilePart = projectile.Part;
    
    if properties.Activated then return end;
    properties.Activated = true;

    projectilePart.Transparency = 1;
    Debugger.Expire(projectilePart, 0.1);

    if not RunService:IsServer() then return end;
    local lastPosition = arcPoint.Point;

    local ex = Instance.new("Explosion");
    ex.DestroyJointRadiusPercent = 0;
    ex.BlastRadius = properties.ExplosionRadius or 20;
    ex.BlastPressure = 0;
    ex.Position = lastPosition;
    ex.Parent = workspace;
    Debugger.Expire(ex, 6);

    local pointAtt = Debugger:Point(lastPosition);

    modAudio.Play(math.random(1,2)==1 and "Explosion" or "Explosion2", pointAtt);
    Debugger.Expire(pointAtt, 6);

    pcall(function()
        local readTerrain = (workspace.Terrain:ReadVoxels(Region3.new(lastPosition, lastPosition):ExpandToGrid(4), 4));
        local terrainMat = readTerrain[1] and readTerrain[1][1] and readTerrain[1][1][1];
        if terrainMat and terrainMat == Enum.Material.Water then
            modAudio.Play("ExplosionUnderwater", pointAtt);
        end
    end)

    local hitLayers = modExplosionHandler:Cast(lastPosition, {
        Radius = properties.ExplosionRadius or 20;
    });

    local damage = properties.Damage;
    local explosionStun = properties.ExplosionStun;
    local damageRatio = properties.DamageRatio;

    modExplosionHandler:Process(lastPosition, hitLayers, {
        ExplosionBy = projectile.CharacterClass;
        StorageItem = projectile.StorageItem;

        Damage = damage;
        SplitDamageMode = "PerLayer";
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