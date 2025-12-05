local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modExplosionHandler = shared.require(game.ReplicatedStorage.Library.ExplosionHandler);
local modArcParticles = shared.require(game.ReplicatedStorage.Particles.ArcParticles);
local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);

local projectilePackage = {
	Id = script.Name;

	ArcTracerConfig = {
		Velocity = 0;
		LifeTime = 5;
		Bounce = 0;
		Acceleration = Vector3.new(0, -workspace.Gravity, 0);
		KeepAcceleration = true;
		IgnoreEntities = true;
	};

	Properties = {
		Damage = 50;
	};
};
--==

function projectilePackage.onRequire()
    local explosion = Instance.new("Part");
    explosion.Name = `ArcBomb`;
    explosion.Color = Color3.fromRGB(255, 0, 0);
    explosion.Anchored = true;
    explosion.CastShadow = false;
    explosion.CanCollide = false;
    explosion.CanQuery = false;
    explosion.Shape = Enum.PartType.Ball;
    explosion.Size = Vector3.zero;
    explosion.Material = Enum.Material.ForceField;
    
    projectilePackage.ProjectilePrefab = explosion;
end

function projectilePackage.BindInstance(projectile: ProjectileInstance)
	projectile.Part = projectilePackage.ProjectilePrefab:Clone();
end

function projectilePackage.BindFire(projectile: ProjectileInstance)
    local projectilePart = projectile.Part;
    local properties = projectile.Properties;
    local damageBy: CharacterClass? = projectile.CharacterClass;

    projectilePart.Anchored = true;

    local arcCount = math.random(3, 5);
    for a=1, arcCount do
        local attA = Instance.new("Attachment");
        attA.Name = `Att{a}+`;
        attA.Parent = projectilePart;
        local attB = Instance.new("Attachment");
        attB.Name = `Att{a}-`;
        attB.Parent = projectilePart;

        local rngDir = modVector.RandomUnitVector(3);
        task.spawn(function()
            task.wait(1/30);

            for a=0, 1, 1/30 do
                attA.Position = rngDir * (projectilePart.Size.Y/2);
                attB.Position = -rngDir * (projectilePart.Size.Y/2);
                task.wait(1/30);
            end
        end)

        modArcParticles.broadcast(attA, attB, {
            Color = Color3.fromRGB(255, 0, 4);
            Color2 = Color3.fromRGB(8, 0, 255);
            Amount = properties.ArcAmount or 4;
            Thickness = properties.ArcThickness or 0.3;
        });
    end


    local explosionPoint = projectilePart.Position;
    local explosionRadius = properties.Radius;
    local explosionDamage = properties.Damage;

    local sphereSize = Vector3.one * explosionRadius * 1.5;

    local explosionTweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
    TweenService:Create(projectilePart, explosionTweenInfo, {
        Size = sphereSize;
    }):Play();

    local arcSound = Debugger:Point(explosionPoint);
    projectile.Garbage:Tag(arcSound);

    modAudio.Play("ElectricExplosion", arcSound);
    modAudio.Play("Explosion4", arcSound).PlaybackSpeed = 1.5;

    task.wait(0.2);

    local hitLayers = modExplosionHandler:Cast(explosionPoint, {
        Radius = explosionRadius;
    });

    local targetableTags = damageBy and damageBy.WieldComp.TargetableTags or nil;
    modExplosionHandler:Process(explosionPoint, hitLayers, {
        ExplosionBy = damageBy;
        TargetableTags = targetableTags;

        Damage = explosionDamage;
        MinDamage = 5;
        ExplosionStun = 1;

        DamageOrigin = explosionPoint;
        OnPartHit = modExplosionHandler.GenericOnPartHit;
    });

    task.wait(0.2);
    projectilePart:Destroy();
end


return projectilePackage;