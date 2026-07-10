local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");
local TweenService = game:GetService("TweenService");

local TWEENINFO = TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);

local projectilePackage = {
	Id = script.Name;

	ArcTracerConfig = {
		Velocity = 50;
		LifeTime = 120;
		Bounce = 0;
		Acceleration = Vector3.new(0, -workspace.Gravity, 0);
		KeepAcceleration = true;
		IgnoreEntities = true;
	};

	Properties = {
		Damage = 100;
	};
};
--==

function projectilePackage.BindInstance(projectile: ProjectileInstance)
	projectile.Part = script:WaitForChild("flammable"):Clone();
end

function projectilePackage.BindFire(projectile: ProjectileInstance)
    local projectilePart = projectile.Part;

    CollectionService:AddTag(projectilePart, "Flammable");
end

function projectilePackage.BindArcContact(projectile: ProjectileInstance, arcPoint: ArcPoint)
    local hitPosition = arcPoint.Point;

    local properties = projectile.Properties;
    local projectilePart = projectile.Part;

    local hitPart, hitPoint, hitNormal, hitMaterial = arcPoint.Hit, arcPoint.Point, arcPoint.Normal, arcPoint.Material;
    if hitPart.Name == "_Water" and hitPart:IsDescendantOf(workspace.Debris) or hitMaterial == Enum.Material.Water then 
        Debugger.Expire(projectilePart, 0);
        
        return true;
    end;

    local damageBy: CharacterClass? = projectile.CharacterClass;

    if damageBy then
        projectilePart:SetAttribute("Owner", damageBy.Name);
    end
    
    if hitPart.Name == "flammable" or CollectionService:HasTag(hitPart, "Flammable") then
        
        local despawnTime = projectilePart:GetAttribute("DespawnTime");
        if despawnTime then
            projectilePart:SetAttribute("DespawnTime", tick()+60);
        end
        
        projectilePart:Destroy();
        return true;
    end
    
    projectilePart.Anchored = true;
    
    if projectilePart.Parent == nil then return end;
    
    projectilePart.CFrame = CFrame.lookAlong(hitPosition, arcPoint.Normal) * CFrame.Angles(math.rad(-90), 0, 0);
    
    if projectilePart.Parent and projectilePart.Parent.Name ~= "flammable" then
        local newModel = Instance.new("Model");
        newModel.Name = "flammable";
        newModel.Parent = workspace.Environment;

        local newDestructible = Instance.new("Configuration");
        newDestructible.Name = `Destructible`;
        newDestructible:SetAttribute("_Name", "Flammable");
        newDestructible.Parent = newModel;

        projectilePart.Parent = newModel;
        newModel.PrimaryPart = projectilePart;
    end
    
    local hitWorldSize = hitPart.CFrame:vectorToWorldSpace(hitPart.Size);
    local maxSize = math.clamp(
        math.min(math.abs(hitWorldSize.X), math.abs(hitWorldSize.Z), 10), 
        0.6, 
        math.random(750, 1100)/100
    );
    
    TweenService:Create(projectilePart, TWEENINFO, {
        Size = Vector3.new(maxSize, 0.6, maxSize);
    }):Play();

    return true;
end

return projectilePackage;