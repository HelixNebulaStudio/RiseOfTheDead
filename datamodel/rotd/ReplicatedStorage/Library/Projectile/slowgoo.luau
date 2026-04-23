local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
local modTouchHandler = shared.require(game.ReplicatedStorage.Library.TouchHandler);

local raycastParams = RaycastParams.new();
raycastParams.FilterType = Enum.RaycastFilterType.Include;
raycastParams.IgnoreWater = true;
raycastParams.FilterDescendantsInstances = {workspace.Environment};
raycastParams.CollisionGroup = "Raycast";

local projectilePackage = {
	Id = script.Name;

	ArcTracerConfig = {
		LifeTime = 10;
		Velocity = 50;
		Bounce = 0;
		Acceleration = Vector3.new(0, -workspace.Gravity/8, 0);
	};

	Properties = {
		Damage = 100;
	};
    
    TouchHandler = nil;
};
--==

function projectilePackage.BindInstance(projectile: ProjectileInstance)
    if RunService:IsServer() then
        if projectilePackage.TouchHandler == nil then            
            local touchHandler = modTouchHandler.new("SlowGoo", 0.5);
            function touchHandler:OnPlayerTouch(player, basePart, part)
                modStatusEffects.Slowness(player, 14, 1);
            end

            projectilePackage.TouchHandler = touchHandler;
        end
    end

	projectile.Part = script:WaitForChild("slowGoo"):Clone();
end

function projectilePackage.BindArcContact(projectile: ProjectileInstance, arcPoint: ArcPoint)
    local projectilePart = projectile.Part;
    local properties = projectile.Properties;

    if properties.Popped then return end;
    properties.Popped = true;

    projectilePart.Transparency = 1;
    projectilePart:Destroy();

    if RunService:IsClient() then return end;
    local hitPoint = arcPoint.Point;
    
    local raycastResult = workspace:Raycast(hitPoint + Vector3.new(0, 4, 0), Vector3.new(0, -20, 0), raycastParams);
    if raycastResult then
        local rayPoint = raycastResult.Position;

        local explosionEffectPrefab = script:WaitForChild("ExplosionEffect");
        local newEffect = explosionEffectPrefab:Clone();
        newEffect.CFrame = CFrame.new(rayPoint) * CFrame.Angles(0, math.random(-math.pi*1000, math.pi*1000)/1000, 0);
        local effectMesh = newEffect:WaitForChild("Mesh");
        newEffect.Parent = workspace.Entities;

        local size = 40
        local speed = 0.5;
        TweenService:Create(effectMesh, TweenInfo.new(speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{
            Scale = Vector3.new(size, size, size)
        }):Play();
        TweenService:Create(newEffect, TweenInfo.new(speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Transparency = 1
        }):Play();
        Debugger.Expire(newEffect, speed+0.1);
        
        local floorGoop = {script:WaitForChild("goop1"); script:WaitForChild("goop2");};
        local newGoop = floorGoop[math.random(1, #floorGoop)]:Clone();
        modAudio.Play("TicksZombieExplode", newGoop).PlaybackSpeed = math.random(80, 100)/100;


        local sizeX = math.random(2000, 2500)/100;
        newGoop.Size = Vector3.new(12, 1.6, 12);

        TweenService:Create(newGoop, TweenInfo.new(10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = Vector3.new(sizeX, 1.6, sizeX)
        }):Play();

        newGoop.Position = rayPoint;
        newGoop.Parent = workspace.Entities;

        projectilePackage.TouchHandler:AddObject(newGoop);

        Debugger.Expire(newGoop, math.random(600, 1200)/10);
    end
end

return projectilePackage;