local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local projectilePackage = {
	Id = script.Name;

	ArcTracerConfig = {
		LifeTime = 10;
		Bounce = 0;
		AirSpin = math.rad(40);
		RayRadius = 1;
		Delta = 1/60;
        Acceleration = Vector3.new(0, -workspace.Gravity/3, 0);
	};

	Properties = {
		Damage = 100;
	};
};
--==

function projectilePackage.BindInstance(projectile: ProjectileInstance)
	projectile.Part = script:WaitForChild("pickaxe"):Clone();
end

function projectilePackage.damage(projectile: ProjectileInstance, hitObj: BasePart)
    local properties = projectile.Properties;
    if properties.Activated then return end;

    local targetModel = hitObj.Parent;
    if targetModel == nil then return end;

    local healthComp: HealthComp? = modHealthComponent.getByModel(targetModel);
    if healthComp == nil or healthComp.IsDead then return end;
    targetModel = healthComp:GetModel();

    local damageTo: CharacterClass = healthComp.CompOwner :: CharacterClass;

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
        local damageBy: CharacterClass? = projectile.CharacterClass;

        if healthComp:CanTakeDamageFrom(damageBy) then
            local dmgData = DamageData.new{
                Damage = damage;
                DamageBy = damageBy;
                DamageTo = damageTo;
                
                ToolHandler = projectile.ToolHandler;
                StorageItem = projectile.StorageItem;
                TargetModel = targetModel;
                TargetPart = hitObj;
                DamageCate = DamageData.DamageCategory.Projectile;
            };

            projectile:PreTakeDamageDamageData(dmgData);
            healthComp:TakeDamage(dmgData);
        end
    end

    modAudio.Play(math.random(1,2)==1 and "BulletBodyImpact" or "BulletBodyImpact2", projectile.Part);
end

function projectilePackage.BindArcContact(projectile: ProjectileInstance, arcPoint: ArcPoint)
    if arcPoint.Hit == nil then return end;

    local projectilePart = projectile.Part;
    local hitPart = arcPoint.Hit;

    if RunService:IsServer() then
        projectilePackage.damage(projectile, hitPart);

    else
        local targetModel = hitPart.Parent;
        local humanoid = targetModel and targetModel:FindFirstChildWhichIsA("Humanoid");
        if humanoid then
            modAudio.Play(
                math.random(1,2)==1 and "BulletBodyImpact" or "BulletBodyImpact2", 
                projectilePart
            ).RollOffMaxDistance = 1024;
        end
    end

    Debugger.Expire(projectilePart);
    if arcPoint.Client then return true end; --Client's arcPoint

    if RunService:IsServer() then
        local debriProjectile: BasePart = projectilePart:Clone();

        Debugger.Expire(debriProjectile, 30);
        debriProjectile.Anchored = false;
        debriProjectile.Massless = true;

        local hitPoint = arcPoint.Point;

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