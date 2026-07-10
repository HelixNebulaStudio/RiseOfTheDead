local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local projectilePackage = {
	Id = script.Name;

	ArcTracerConfig = {
		LifeTime = 30;
		Bounce = 0;
		RayRadius = 0.5;
		Delta = 1/60;
        Acceleration = Vector3.new(0, -workspace.Gravity/4, 0);
	};

	Properties = {
		Damage = 100;
		ThrowDamagePercent = 0.01;
	};
};
--==

function projectilePackage.BindInstance(projectile: ProjectileInstance)
	projectile.Part = script:WaitForChild("spear"):Clone();
end

function projectilePackage.damage(projectile: ProjectileInstance, hitObj: BasePart)
    local properties = projectile.Properties;
    if properties.Activated then return end;

    local targetModel = hitObj.Parent;
    local healthComp: HealthComp? = modHealthComponent.getByModel(targetModel);
    if healthComp == nil then return end;

    local damageTo: CharacterClass = healthComp.CompOwner :: CharacterClass;
    local maxHealth = healthComp.MaxHealth;

    local damage = math.clamp(
        (properties.ThrowDamagePercent or 0.01) * maxHealth,
        math.ceil(properties.Damage * 0.5),
        50000
    );

    if damageTo.ClassName == "NpcClass" then
        local dmgMulti = 1;
        if dmgMulti then
            damage = damage * dmgMulti;
        else
            damage = 0;
        end
    end

    if damage <= 0 then return end;

    local damageBy: CharacterClass? = projectile.CharacterClass;
    if not healthComp:CanTakeDamageFrom(damageBy) then return end;

    local dmgData = DamageData.new{
        ToolHandler = projectile.ToolHandler;
        Damage = damage;
        DamageBy = damageBy;
        DamageTo = healthComp.CompOwner;
        
        StorageItem = projectile.StorageItem;
        TargetModel = targetModel;
        TargetPart = hitObj;
        DamageCate = DamageData.DamageCategory.Projectile;
    };

    projectile:PreTakeDamageDamageData(dmgData);
    healthComp:TakeDamage(dmgData);

    modAudio.Play(math.random(1,2)==1 and "BulletBodyImpact" or "BulletBodyImpact2", projectile.Part);
end

function projectilePackage.BindArcContact(projectile: ProjectileInstance, arcPoint: ArcPoint)
    if arcPoint.Hit == nil then return end;

    local projectilePart = projectile.Part;

    if RunService:IsServer() then
        projectilePackage.damage(projectile, arcPoint.Hit);

    else
        local targetModel = arcPoint.Hit.Parent;
        local humanoid = targetModel and targetModel:FindFirstChildWhichIsA("Humanoid");
        if humanoid then
            modAudio.Play(
                math.random(1,2)==1 and "BulletBodyImpact" or "BulletBodyImpact2", 
                projectilePart
            ).RollOffMaxDistance = 1024;
        end

    end

    Debugger.Expire(projectilePart);
    if arcPoint.Client then return true end;

    if RunService:IsServer() then
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
    end

    return true;
end

return projectilePackage;