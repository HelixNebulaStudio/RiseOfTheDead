local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);
local modDamageTag = shared.require(game.ReplicatedStorage.Library.DamageTag);
local modExplosionHandler = shared.require(game.ReplicatedStorage.Library.ExplosionHandler);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local projectilePackage = {
	Id = script.Name;

	ArcTracerConfig = {
		Velocity = 100;
		LifeTime = 30;
		Bounce = 0;
		Acceleration = Vector3.new(0, 0, 0);
		IgnoreEntities = true;
		RayRadius = 0.5;
		Delta = 1/3;
	};

	Properties = {
		DetonateTimer = 2;
		ExplosionRadius = 35;
		Damage = 100;
		MinDamage = 100;
		ExplosionStun = 1;
		DamageRatio = 0.05;
	};
};
--==

function projectilePackage.BindInstance(projectile: ProjectileInstance)
	projectile.Part = script:WaitForChild("Grenade"):Clone();
end

function projectilePackage.BindFire(projectile: ProjectileInstance)
    local properties = projectile.Properties;

    local projectilePart = projectile.Part;

    task.delay(properties.DetonateTimer, function()
        modAudio.Play(math.random(1, 2) == 1 and "Explosion" or "Explosion2", projectilePart);
        
        projectilePart.Transparency = 1;
        Debugger.Expire(projectilePart:FindFirstChild("stick"), 0);
        
        if not RunService:IsServer() then return end;
        
        local lastPosition = projectilePart.Position;
        
        local ex = Instance.new("Explosion");
        ex.DestroyJointRadiusPercent = 0;
        ex.BlastRadius = 35;
        ex.BlastPressure = 0;
        ex.Position = lastPosition;
        ex.Parent = workspace;
        Debugger.Expire(ex, 1);
        projectilePart.Transparency = 1;
        

        local hitLayers = modExplosionHandler:Cast(lastPosition, {
            Radius = properties.ExplosionRadius;
        });

        local damage = properties.Damage;
        local minDamage = properties.MinDamage;
        local explosionStun = properties.ExplosionStun;
        local damageRatio = properties.DamageRatio;

        modExplosionHandler:Process(lastPosition, hitLayers, {
            ExplosionBy = projectile.CharacterClass;
            StorageItem = projectile.StorageItem;
            TargetableEntities = projectile.ToolHandler and projectile.ToolHandler.WieldComp.TargetableTags;

            Damage = damage;
            MinDamage = minDamage;
            ExplosionStun = explosionStun;
            DamageRatio = damageRatio;

            DamageOrigin = lastPosition;
            OnPartHit=modExplosionHandler.GenericOnPartHit;
        });
    end)
end

function projectilePackage.BindArcContact(projectile: ProjectileInstance, arcPoint: ArcPoint)
	if arcPoint.Hit == nil or not arcPoint.Hit.Anchored then return end;
    local projectilePart = projectile.Part;
    modAudio.Play("GrenadeBounce", projectilePart);

    projectilePart.Anchored = false;
    if projectilePart:CanSetNetworkOwnership() then
        projectilePart:SetNetworkOwner(nil);
    end;
    
    local hitPart, hitPoint = arcPoint.Hit, arcPoint.Point;
    local weld = Instance.new("Motor6D");
    weld.Name = "stick";
    weld.Parent = projectilePart;
    
    weld.Part0 = projectilePart;
    weld.Part1 = hitPart;
    
    local worldCf = CFrame.new(hitPoint, hitPoint - arcPoint.Direction);
    weld.C1 = hitPart.CFrame:ToObjectSpace(worldCf);

    return true;
end

return projectilePackage;