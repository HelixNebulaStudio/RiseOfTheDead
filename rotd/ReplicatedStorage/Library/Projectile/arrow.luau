local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modSfxService = shared.require(game.ReplicatedStorage.Library.SfxService);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local projectilePackage = {
	Id = script.Name;

	ArcTracerConfig = {
		Velocity = 500;
		LifeTime = 10;
		Bounce = 0;
		Acceleration = Vector3.new(0, -workspace.Gravity/16, 0);
		RayRadius = 0.1;
	};

	Properties = {
		Damage = 100;
	};
};
--==

function projectilePackage.BindInstance(projectile: ProjectileInstance)
	projectile.Part = script:WaitForChild("Arrow"):Clone();
end

function projectilePackage.BindArcContact(projectile: ProjectileInstance, arcPoint: ArcPoint)
    if arcPoint.Hit == nil then return end;

    local properties = projectile.Properties;
    local arcTracer = projectile.ArcTracer;
    local projectilePart = projectile.Part;

    if RunService:IsServer() then
        local hitPart = arcPoint.Hit;

        if properties.HitIndex == nil then
            properties.HitIndex = 1;
        end
        local hitOnce = properties.HitOnce or {};
        properties.HitOnce = hitOnce;


		local shotCache = {
			HitPart = hitPart;
			FocusCharge = (properties.FocusCharge or 0);
			Index = properties.HitIndex;

			CritOccured = nil;
		};
		properties.HitIndex = properties.HitIndex +1;


		local targetModel = hitPart.Parent;
		if targetModel == nil then return end;

		local healthComp: HealthComp? = modHealthComponent.getByModel(targetModel);
		if healthComp == nil then return end;
        targetModel = healthComp:GetModel();

		local damage = properties.Damage or 100;
		if damage == 0 then return end;

		if hitOnce[targetModel] then return end
		hitOnce[targetModel] = true;
		task.delay(1, function()
            hitOnce[targetModel] = nil;
        end)

        if healthComp:CanTakeDamageFrom(projectile.CharacterClass) then
            local damageBy: CharacterClass? = projectile.CharacterClass;

            local dmgData = DamageData.new{
                Damage = damage;
                DamageBy = damageBy;
                DamageTo = healthComp.CompOwner;
                
                StorageItem = projectile.StorageItem;
                TargetPart = hitPart;
                TargetModel = targetModel;
                DamageType = shotCache.CritOccured or "";
                DamageCate = DamageData.DamageCategory.Projectile;
            };

            projectile:PreTakeDamageDamageData(dmgData);
            healthComp:TakeDamage(dmgData);
        end
 
        local impactSndTick = properties.ImpactSndTick;
        if impactSndTick == nil or tick()-impactSndTick > 0.2 then
            properties.ImpactSndTick = tick();

            modSfxService.spawnImpactEffect{
                BasePart = arcPoint.Hit;
                Point = arcPoint.Point;
                Normal = arcPoint.Normal;
            };
        end

    else
        local targetModel = arcPoint.Hit.Parent;
        local humanoid = targetModel and targetModel:FindFirstChildWhichIsA("Humanoid");
        if humanoid then
            modAudio.Play(
                math.random(1,2) == 1 and "BulletBodyImpact" or "BulletBodyImpact2", 
                projectilePart.Position
            ).RollOffMaxDistance = 1024;
        end

    end

    local stickArrow = true;

    if arcTracer.BounceCount > 0 then
        stickArrow = false;
    end

    if stickArrow then
        Debugger.Expire(projectilePart);
        if arcPoint.Client then return true end; --Client's arcPoint

        if RunService:IsServer() then
            local arrowDebris: BasePart = projectilePart:Clone();

            Debugger.Expire(arrowDebris, 10);
            arrowDebris.Anchored = false;
            arrowDebris.Massless = true;
            local hitPart, hitPoint = arcPoint.Hit, arcPoint.Point;

            local weld = Instance.new("Weld");
            weld.Name = "arrow";
            weld.Parent = arrowDebris;

            weld.Part0 = arrowDebris;
            weld.Part1 = hitPart;

            local worldCf = CFrame.new(hitPoint, hitPoint + arcPoint.Direction);
            weld.C1 = hitPart.CFrame:ToObjectSpace(worldCf);

            arrowDebris.Parent = workspace.Debris;
        end

        return true;
    end

    return;
end

return projectilePackage;