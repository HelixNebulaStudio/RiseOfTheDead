local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modSfxService = shared.require(game.ReplicatedStorage.Library.SfxService);
local modProjectileRicochet = shared.require(game.ReplicatedStorage.Library.Projectile.Mechanics.Ricochet);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local projectilePackage = {
	Id = script.Name;

	ArcTracerConfig = {
		Velocity = 10;
		LifeTime = 10;
		AirSpin = math.rad(24);
		RayRadius = 0.5;

		Bounce = 1;
		MaxBounce = 9;
		KeepAcceleration = true;

		Delta = 1/60;
	};

	Properties = {
		Damage = 100;
	};
};
--==

function projectilePackage.BindInstance(projectile: ProjectileInstance)
	projectile.Part = script:WaitForChild("boomerang"):Clone();
end

function projectilePackage.BindArcStepped(projectile: ProjectileInstance, arcPoint: ArcPoint)
    modProjectileRicochet.BindStepped(projectile, arcPoint, 32);
end

function projectilePackage.BindArcContact(projectile: ProjectileInstance, arcPoint: ArcPoint)
    if arcPoint.Hit == nil then return end;

    local properties = projectile.Properties;
    local arcTracer = projectile.ArcTracer;
    local projectilePart = projectile.Part;

    arcTracer.Bounce = arcTracer.Bounce -0.1;

    local damageBy: CharacterClass? = projectile.CharacterClass;

    if RunService:IsServer() then
        local hitCache = properties.HitCache or {};
        properties.HitCache = hitCache;

        local targetModel = arcPoint.Hit.Parent;
        if targetModel == nil then return end;

        local healthComp: HealthComp? = modHealthComponent.getByModel(targetModel);
        targetModel = healthComp and healthComp:GetModel() or nil;

        if healthComp and not healthComp.IsDead and hitCache[targetModel] == nil then
            hitCache[targetModel] = true;
            task.delay(5, function()
                table.clear(hitCache);
            end)

            local damageTo = healthComp.CompOwner;

            -- Calculate damage based on target's max health
            local damage = math.clamp(
                (properties.ThrowDamagePercent or 0.01) * healthComp.MaxHealth,
                math.ceil(properties.Damage * 0.5),
                50000
            );

            -- Apply damage multiplier based on target type
            if damageTo.ClassName == "NpcClass" then
                
                local dmgMulti = 1;
                if dmgMulti then
                    damage = damage * dmgMulti;
                else
                    damage = 0;
                end
            end

            if damage > 0 then
                arcTracer.Bounce = arcTracer.Bounce -0.2;

                -- Check if target can be damaged by owner
                if healthComp:CanTakeDamageFrom(damageBy) then
                    local dmgData = DamageData.new{
                        Damage = damage;
                        DamageBy = damageBy;
                        DamageTo = healthComp.CompOwner;
                        
                        ToolHandler = projectile.ToolHandler;
                        StorageItem = projectile.StorageItem;
                        TargetModel = targetModel;
                        TargetPart = arcPoint.Hit;
                        DamageCate = DamageData.DamageCategory.Projectile;
                    };

                    projectile:PreTakeDamageDamageData(dmgData);
                    healthComp:TakeDamage(dmgData);
                end
            end

            modAudio.Play(math.random(1,2)==1 and "BulletBodyImpact" or "BulletBodyImpact2", projectilePart.Position).RollOffMaxDistance = 1024;
        end;

        modSfxService.spawnImpactEffect{
            BasePart = arcPoint.Hit;
            Point = arcPoint.Point;
            Normal = arcPoint.Normal;
        };
    end

    if arcTracer.MaxBounce > 0 and arcTracer.Bounce > 0 then return end;

    Debugger.Expire(projectilePart);
    local debriProjectile: BasePart = projectilePart:Clone();

    Debugger.Expire(debriProjectile, 30);
    debriProjectile.Anchored = false;
    debriProjectile.Massless = true;
    local hitPart, hitPoint = arcPoint.Hit, arcPoint.Point;

    local weld = Instance.new("Weld");
    weld.Name = "projectileDebrisWeld";
    weld.Parent = debriProjectile;

    weld.Part0 = debriProjectile;
    weld.Part1 = hitPart;

    local worldCf = CFrame.new(hitPoint, hitPoint + arcPoint.Direction);
    weld.C1 = hitPart.CFrame:ToObjectSpace(worldCf);

    debriProjectile.Parent = workspace.Debris;

    return true;
end

return projectilePackage;