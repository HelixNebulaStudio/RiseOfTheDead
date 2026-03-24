local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modTouchHandler = shared.require(game.ReplicatedStorage.Library.TouchHandler);
local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);
local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local TWEENINFO = TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);

local projectilePackage = {
	Id = script.Name;

	ArcTracerConfig = {
		Velocity = 50;
		LifeTime = 10;
		Bounce = 0;
		Acceleration = Vector3.new(0, -workspace.Gravity, 0);
		KeepAcceleration = true;
		IgnoreEntities = true;
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
    local dropletPart = Instance.new("Part");
    local dropletMesh = Instance.new("SpecialMesh");
    dropletMesh.MeshType = Enum.MeshType.Sphere;
    dropletMesh.Scale = Vector3.new(1, 0.1, 1);
    dropletMesh.Parent = dropletPart;
    dropletPart.Size = Vector3.new(0.8, 10, 0.8);
    dropletPart.Material = Enum.Material.Neon;
    dropletPart.CanCollide = false;
    dropletPart.Anchored = true;
    dropletPart.Name = `ToxicPuddle`;
    
    projectilePackage.ProjectilePrefab = dropletPart;

    if RunService:IsServer() then
        local toxicPuddleTouchHandler = modTouchHandler.new("ToxicPuddle", 0.2);

        function toxicPuddleTouchHandler:OnHumanoidTouch(humanoid, hitbox, part)
            local projectile: ProjectileInstance? = projectilePackage.PartList[hitbox];
            if projectile == nil then return end;

            local targetModel = part.Parent;
            if not targetModel then return end;

            local healthComp: HealthComp = modHealthComponent.getByModel(targetModel);
            if not healthComp then return end;
            targetModel = healthComp:GetModel();

            local damageBy: CharacterClass? = projectile.CharacterClass;
            local damageTo: CharacterClass = healthComp.CompOwner :: CharacterClass;

            if not healthComp:CanTakeDamageFrom(damageBy) then return end;
    
            if damageTo.ClassName == "PlayerClass" then
                local player = (damageTo :: PlayerClass):GetInstance();
                shared.modPlayers.cameraShakeAndZoom(player, 5, 0, 0.3, 2, false);
            end

            healthComp:TakeDamage(DamageData.new{
                Damage = 2;
                TargetPart = part;
            });
            modAudio.Play("AcidHit", part).PlaybackSpeed = math.random(90, 110)/100;
        end

        projectilePackage.TouchHandler = toxicPuddleTouchHandler;
    end
end

function projectilePackage.BindInstance(projectile: ProjectileInstance)
    local greenColor = Color3.fromRGB(13, 130, 13);

    local newDroplet = projectilePackage.ProjectilePrefab:Clone();
    local colorOffset = math.random(-500, 500)/10000;
    newDroplet.Color = Color3.new(greenColor.R+colorOffset, greenColor.G+colorOffset, greenColor.B+colorOffset);

	projectile.Part = newDroplet:Clone();
end

function projectilePackage.BindFire(projectile: ProjectileInstance)
    local projectilePart = projectile.Part;
    Debugger.Expire(projectilePart, 15);
end

function projectilePackage.BindArcContact(projectile: ProjectileInstance, arcPoint: ArcPoint)
    local hitPart = arcPoint.Hit;
    local hitPosition = arcPoint.Point;

    local properties = projectile.Properties;
    local projectilePart = projectile.Part;

    local damageBy: CharacterClass? = projectile.CharacterClass;

    if damageBy and damageBy.Character then
        projectilePart:SetAttribute("Owner", damageBy.Character.Name);
    end
    
    if hitPart.Name == "ToxicPuddle" then
        
        local despawnTime = projectilePart:GetAttribute("DespawnTime");
        if despawnTime then
            projectilePart:SetAttribute("DespawnTime", tick()+1);
        end
        
        projectilePart:Destroy();
        return;
    end
    
    projectilePart.Anchored = true;
    
    if projectilePart.Parent == nil then return end;
    
    projectilePart.CFrame = CFrame.new(hitPosition, hitPosition + arcPoint.Normal) * CFrame.Angles(math.rad(-90), 0, 0);
    
    if projectilePart.Parent and projectilePart.Parent.Name ~= "ToxicPuddle" then
        local newModel = Instance.new("Model");
        newModel.Name = "ToxicPuddle";
        newModel.Parent = workspace.Environment;

        projectilePart.Parent = newModel;
        newModel.PrimaryPart = projectilePart;
            
        if math.random(1, 3) == 1 then
            modAudio.Play("AcidSplash", projectilePart).PlaybackSpeed = math.random(90, 110)/100;
        end
    end
    
    local hitWorldSize = hitPart.CFrame:vectorToWorldSpace(hitPart.Size);
    local maxSize = math.clamp(
        math.min(math.abs(hitWorldSize.X), math.abs(hitWorldSize.Z), 10), 
        2, 
        math.random(750, 1100)/100
    );
    
    TweenService:Create(projectilePart, TWEENINFO, {
        Size = Vector3.new(maxSize, 2, maxSize);
    }):Play();

    projectilePackage.PartList[projectilePart] = projectile;
    projectilePackage.TouchHandler:AddObject(projectilePart);
    projectile.Garbage:Tag(function()
        projectilePackage.PartList[projectilePart] = nil;
    end)

    task.spawn(function() 
        if tick() <= projectilePackage.CleanupTick then return end;
        projectilePackage.CleanupTick = tick()+60;

        for part, projectile in pairs(projectilePackage.PartList) do
            if workspace:IsAncestorOf(part) then continue end;
            projectilePackage.PartList[part] = nil;
        end
    end)
end

return projectilePackage;