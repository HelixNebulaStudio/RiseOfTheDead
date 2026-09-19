local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");
local TweenService = game:GetService("TweenService");

local TWEENINFO = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);

local modFarmingSystem = shared.require(game.ReplicatedStorage.Library.FarmingSystem);

local projectilePackage = {
	Id = script.Name;

	ArcTracerConfig = {
		Velocity = 50;
		LifeTime = 3;
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
	projectile.Part = script:WaitForChild("water"):Clone();
end

function projectilePackage.BindFire(projectile: ProjectileInstance)
end

function projectilePackage.BindArcContact(projectile: ProjectileInstance, arcPoint: ArcPoint)
    local hitPart = arcPoint.Hit;
    local hitPosition = arcPoint.Point;

    local properties = projectile.Properties;
    local projectilePart = projectile.Part;

    local characterClass: CharacterClass? = projectile.CharacterClass;

    if characterClass and characterClass.Character then
        projectilePart:SetAttribute("Owner", characterClass.Character.Name);
    end
    
    if hitPart.Name == "flammable" or CollectionService:HasTag(hitPart, "Flammable") then
        hitPart:Destroy();
        return true;

    elseif hitPart.Name == "water"then
        local despawnTime = projectilePart:GetAttribute("DespawnTime");
        if despawnTime then
            projectilePart:SetAttribute("DespawnTime", tick()+1);
        end
        
        projectilePart:Destroy();
        return true;

    elseif hitPart.Parent and hitPart.Parent:FindFirstChild("Interactable") and hitPart.Parent.Interactable:IsA("Configuration") then
        local interactConfig = hitPart.Parent.Interactable;
        if interactConfig:GetAttribute("_Name") == "Planter" and characterClass and characterClass.ClassName == "PlayerClass" then
            local id = interactConfig:GetAttribute("_Id");

            local player = (characterClass :: PlayerClass):GetInstance();
            task.spawn(function()
                modFarmingSystem.waterPlanter(player, id);
            end)

            return true;
        end
    end
    
    projectilePart.Anchored = true;
    if projectilePart.Parent == nil then return end;
    
    projectilePart.CFrame = CFrame.new(hitPosition, hitPosition + arcPoint.Normal) * CFrame.Angles(math.rad(-90), 0, 0);
    
    local hitWorldSize = hitPart.CFrame:vectorToWorldSpace(hitPart.Size);
    local maxSize = math.clamp(
        math.min(math.abs(hitWorldSize.X), math.abs(hitWorldSize.Z), 10), 
        0.6, 
        math.random(550, 900)/100
    );
    
    TweenService:Create(projectilePart, TWEENINFO, {
        Size = Vector3.new(maxSize, 0.6, maxSize);
    }):Play();

    return;
end

return projectilePackage;