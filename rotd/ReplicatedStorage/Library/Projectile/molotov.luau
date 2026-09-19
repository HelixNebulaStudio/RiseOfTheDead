local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");
local CollectionService = game:GetService("CollectionService");

local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modTouchHandler = shared.require(game.ReplicatedStorage.Library.TouchHandler);

local tweenInfo = TweenInfo.new(5);

local projectilePackage = {
	Id = script.Name;

	ArcTracerConfig = {
		LifeTime = 30;
		Bounce = 0;

		IgnoreEntities = false;
		IgnoreWater = false;
		Delta = 1/60;
	};

	Properties = {
		Damage = 5;
	};

    TouchHandler = nil;
    PartList = {};

    CleanupTick = tick()+60;
};
--==

function projectilePackage.onRequire()
    if RunService:IsClient() then return end;
    
    local touchHandler = modTouchHandler.new(`Molotov`, 0.5);
    touchHandler.ScanType = modTouchHandler.ScanTypes.Sphere;
    projectilePackage.TouchHandler = touchHandler;

    function touchHandler:OnPlayerTouch(player, hitbox, part)
        local projectile: ProjectileInstance = projectilePackage.PartList[hitbox];
        if projectile == nil then return end;
        projectilePackage.molotovTouch(projectile, part);
    end
    
    function touchHandler:OnHumanoidTouch(humanoid, hitbox, part)
        local projectile: ProjectileInstance = projectilePackage.PartList[hitbox];
        if projectile == nil then return end;
        projectilePackage.molotovTouch(projectile, part);
    end

    function touchHandler:OnPartTouch(hitbox, part)
        if not CollectionService:HasTag(part, "Flammable") then return end;
        local modFlammable = shared.require(game.ServerScriptService.ServerLibrary.Flammable);
        modFlammable:Ignite(part);
    end
end

function projectilePackage.BindInstance(projectile: ProjectileInstance)
	projectile.Part = script:WaitForChild("molotov"):Clone();
end

function projectilePackage.BindFire(projectile: ProjectileInstance)
    local projectilePart = projectile.Part;
    local arcTracerConfig = projectile.ArcTracerConfig;

    Debugger.Expire(projectilePart, arcTracerConfig.LifeTime);
    modAudio.Play("Fire", projectilePart, true);
end

function projectilePackage.molotovTouch(projectile: ProjectileInstance, hitPart)
    local targetModel = hitPart.Parent;
    if not targetModel then return end;

    local healthComp: HealthComp = modHealthComponent.getByModel(targetModel);
    if not healthComp then return end;
    targetModel = healthComp:GetModel();

    local damageBy: CharacterClass? = projectile.CharacterClass;
    
    local damageTo: CharacterClass = healthComp.CompOwner :: CharacterClass;
    if healthComp:CanTakeDamageFrom(damageBy) == false then return end;

    local properties = projectile.Properties;
    local damage = properties.Damage or 1;
    
    if damageTo.ClassName == "NpcClass" then
        damage = math.clamp(healthComp.MaxHealth * 0.01, 25, 5000);
    end

    damageTo.StatusComp:Apply("Burn", {
        Expires = workspace:GetServerTimeNow() + 5;
        Duration = 5;
        ApplyBy = damageBy;
        Values = {
            Amount = damage;
        };
    });
end

function projectilePackage.BindArcContact(projectile: ProjectileInstance, arcPoint: ArcPoint)
    local properties = projectile.Properties;
    local projectilePart = projectile.Part;

    local hitPart, hitPoint, hitNormal, hitMaterial = arcPoint.Hit, arcPoint.Point, arcPoint.Normal, arcPoint.Material;
    
    local isInWater = hitPart.Name == "_Water" and hitPart:IsDescendantOf(workspace.Debris) or hitMaterial == Enum.Material.Water;
    if isInWater ~= true then
        local regionPos = hitPoint + hitNormal*0.1;
        pcall(function() 
            local region = Region3.new(regionPos, regionPos):ExpandToGrid(4);
            local mats, _occs = workspace.Terrain:ReadVoxels(region, 4);
            isInWater = mats and mats[1][1][1] or nil;
            isInWater = isInWater == Enum.Material.Water;
        end)
    end

    if isInWater then
        Debugger.Expire(projectilePart, 0);

        local snd = modAudio.Play("Extinguish", hitPoint);
        local att = snd.Parent;
        local steam: ParticleEmitter = game.ReplicatedStorage.Particles.Steam:Clone();
        steam.Parent = att;
        steam:Emit(3);

        return true;
    end;

    if properties.Impacted then return end;
    properties.Impacted = true;

    projectilePart.Transparency = 1;
    modAudio.Play("GlassSmash", projectilePart);
    Debugger.Expire(projectilePart, 2);

    if RunService:IsClient() then return end;

    local humanoid = hitPart.Parent:FindFirstChildWhichIsA("Humanoid");
    local rootPart = humanoid and humanoid.RootPart;

    if rootPart then
        local ray = Ray.new(rootPart.Position, Vector3.new(0, -64, 0));
        hitPart, hitPoint, hitNormal, hitMaterial = workspace:FindPartOnRayWithWhitelist(ray, {workspace.Environment}, true);
    end

    local newRegion = script:WaitForChild("fireRegion"):Clone();
    newRegion.CFrame = CFrame.lookAlong(hitPoint, hitNormal) * CFrame.Angles(math.rad(90), 0, 0);
    newRegion.Size = Vector3.new();
    newRegion.Parent = workspace.Entities;

    modAudio.Play("Fire", newRegion, true);

    Debugger.Expire(newRegion, 15);

    projectilePackage.PartList[newRegion] = projectile;
    projectile.Garbage:Tag(function()
        projectilePackage.PartList[newRegion] = nil;
    end)
    projectilePackage.TouchHandler:AddObject(newRegion);

    task.spawn(function() 
        if tick() <= projectilePackage.CleanupTick then return end;
        projectilePackage.CleanupTick = tick()+60;

        for part, projectile in pairs(projectilePackage.PartList) do
            if workspace:IsAncestorOf(part) then continue end;
            projectilePackage.PartList[part] = nil;
        end
    end)

    local tween: Tween = TweenService:Create(newRegion, tweenInfo, {Size=Vector3.new(23, 2, 23)});
    tween.Completed:Connect(function(playbackState)
        if playbackState ~= Enum.PlaybackState.Completed then return end;
        TweenService:Create(
            newRegion,
            TweenInfo.new(15, Enum.EasingStyle.Exponential, Enum.EasingDirection.In),
            {Size=Vector3.new(16, 1.8, 16)}
        ):Play();
    end)
    tween:Play();

    return true;
end

return projectilePackage;