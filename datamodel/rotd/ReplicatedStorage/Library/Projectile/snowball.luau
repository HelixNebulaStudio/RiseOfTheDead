local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local projectilePackage = {
	Id = script.Name;

	ArcTracerConfig = {
		KeepAcceleration = true;
		Velocity = 250;
		LifeTime = 20;
		Bounce = 0;
		IgnoreWater = false;
		RayRadius = 0.6;
		Delta = 1/60;
	};

	Properties = {
		Damage = 100;
	};
};
--==

function projectilePackage.BindInstance(projectile: ProjectileInstance)
	projectile.Part = script:WaitForChild("Snowball"):Clone();
end

function projectilePackage.BindArcContact(projectile: ProjectileInstance, arcPoint: ArcPoint)
    if RunService:IsClient() then return end;

    local projectilePart = projectile.Part;

    local hitPart = arcPoint.Hit;
    local hitPosition = arcPoint.Point;
    local hitMaterial = arcPoint.Material;

    if hitMaterial == Enum.Material.Water then
        local snd = modAudio.Play("HeavySplash", hitPosition);
        snd.Volume = 1;
        snd.PlaybackSpeed = math.random(270, 310)/100;

        Debugger.Expire(projectilePart, 0);
        return true; -- break arctrace
    end
    if not hitPart then return end;

    local snd = modAudio.Play("SnowballImpact", hitPosition);
    snd.Volume = 2;
    snd.PlaybackSpeed = math.random(70, 85)/100;

    Debugger.Expire(projectilePart, 0);

    local pt = Debugger:PointPart(hitPosition);
    pt.Transparency = 1;
    Debugger.Expire(pt, 1.5);

    local templateSnowSplash = game.ReplicatedStorage.Particles.SnowSplash;
    local snowSplash = templateSnowSplash:Clone();
    snowSplash.Parent = pt;
    snowSplash:Emit(math.random(8, 10));

    local healthComp: HealthComp? = modHealthComponent.getByModel(hitPart.Parent);
    if healthComp == nil then return true; end

    local damageTo: CharacterClass = healthComp.CompOwner :: CharacterClass;
    local damageBy: CharacterClass? = projectile.CharacterClass;

    if not healthComp:CanTakeDamageFrom(damageBy) then return end;

    local damage = 45;
    if damageTo.ClassName == "NpcClass" then        
        if damageTo.Name == "Winter Treelum" then
            damage = math.clamp(damageTo.HealthComp.CurHealth * 0.01, 45, 50000);
        end
    end

    local dmgData = DamageData.new{
        ToolHandler = projectile.ToolHandler;
        Damage = damage;
        DamageBy = damageBy;
        DamageTo = damageTo;
        
        StorageItem = projectile.StorageItem;
        TargetPart = hitPart;
        DamageType = "Frost";
        DamageCate = DamageData.DamageCategory.Projectile;
    };
    projectile:PreTakeDamageDamageData(dmgData);
    healthComp:TakeDamage(dmgData);

    return true; -- break arctrace
end

return projectilePackage;