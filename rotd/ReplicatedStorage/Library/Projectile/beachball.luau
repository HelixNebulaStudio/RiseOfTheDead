local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);

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
	projectile.Part = script:WaitForChild("beachball"):Clone();
end

function projectilePackage.BindArcContact(projectile: ProjectileInstance, arcPoint: ArcPoint)
    local hitPart = arcPoint.Hit;
    local hitPosition = arcPoint.Point;

    local projectilePart = projectile.Part;
    local properties = projectile.Properties;

    modAudio.Play("Beachball", projectilePart).RollOffMaxDistance = 256;

    local targetModel = hitPart.Parent;
    if targetModel == nil then return end;

    local healthComp: HealthComp? = modHealthComponent.getByModel(targetModel);
    if healthComp == nil or healthComp.IsDead or not healthComp:CanTakeDamageFrom(projectile.CharacterClass) then 
        return 
    end;

    local snd = modAudio.Play("Beachball", hitPosition);
    snd.PlaybackSpeed = math.random(90, 110)/100;

    local minDmg = properties.Damage;
    local maxDmg = math.max(healthComp.MaxHealth * 0.05, 110);
    local damage = math.clamp(math.random(minDmg, maxDmg), minDmg, maxDmg);

    local dmgData = DamageData.new{
        Damage = damage;
        DamageBy = projectile.CharacterClass;
        DamageTo = healthComp.CompOwner;

        StorageItem = projectile.StorageItem;
        TargetPart = hitPart;
        DamageCate = DamageData.DamageCategory.Projectile;
    };
    projectile:PreTakeDamageDamageData(dmgData);
    healthComp:TakeDamage(dmgData);
end

return projectilePackage;