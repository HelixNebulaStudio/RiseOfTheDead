local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);
local modDamageTag = shared.require(game.ReplicatedStorage.Library.DamageTag);
local modRope = shared.require(game.ReplicatedStorage.Library.Rope);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local LINK_SIZE = 10;

local projectilePackage = {
	Id = script.Name;

	ArcTracerConfig = {
		Velocity = 100;
		LifeTime = 30;
		Bounce = 0;
		Acceleration = Vector3.new(0, 0, 0);
		IgnoreEntities = true;
		RayRadius = 0.5;
		Delta = 1/4;
	};

	Properties = {
		Damage = 100;

        DistanceLapsed = 0;
        LinkObjects = {};
	};
};
--==
function projectilePackage.onRequire()
    VEINLINK_PREFAB = script:WaitForChild("VeinLink");
end

function projectilePackage.BindInstance(projectile: ProjectileInstance)
	projectile.Part = script:WaitForChild("Projectile"):Clone();
end

function projectilePackage.BindFire(projectile: ProjectileInstance)
    if not RunService:IsServer() then return end;
    if projectile.IsDestroyed then return end;
    
    local properties = projectile.Properties;
    local projectilePart = projectile.Part;

    -- On Launch;
    local origin = projectile.OriginCFrame.Position;
    
    local rope = modRope.new();
    rope.Cycles = 3;
    rope.GravitationalForce = Vector3.new(0, -workspace.Gravity/5, 0) * 1/900;
    rope:Run();
    properties.Rope = rope;
    
    local originPoint = rope:NewPoint(origin, true);
    properties.OriginPoint = originPoint;
    
    local projRopePoint = rope:NewPoint(projectilePart.Position, true);
    projRopePoint.Object = projectilePart;
    properties.ProjRopePoint = projRopePoint;
    
    local prevStick = rope:NewStick(projRopePoint, originPoint, 9);
    local newLinkPart = VEINLINK_PREFAB:Clone();
    properties.PrevStick = prevStick;
        
    prevStick.Update = function(stick)
        if projectile.IsDestroyed then return end;
        local center = (stick.PointA.Position + stick.PointB.Position)/2;
        newLinkPart.CFrame = CFrame.lookAt(center, stick.PointB.Position) * CFrame.Angles(math.rad(90), 0, 0);
    end
    prevStick:Update();
    
    local linkObjects = properties.LinkObjects;

    newLinkPart.Parent = projectilePart;
    table.insert(linkObjects, newLinkPart);
    
    local rawProperties = properties.Values;
    projectile.Garbage:Tag(function()
        rawProperties.Rope:Destroy();
        rawProperties.Rope = nil;
    end)
    projectile.Garbage:Tag(function() 
        local linkObjects = rawProperties.LinkObjects;
        
        for a=1, #linkObjects do
            local linkObj = linkObjects[a];
            
            Debugger.Expire(linkObj, 5);
            linkObj.Color = Color3.fromRGB(48, 30, 30);
            linkObj.Anchored = false;

            if linkObj:FindFirstChild("CollisionShape") then
                linkObj.CollisionShape.CanCollide = true;
                linkObj.CollisionShape.Size = Vector3.new(1, 12, 1);
                linkObj.CanCollide = false;
            end
        end

        table.clear(linkObjects);
    end)
end

function projectilePackage.BindArcContact(projectile: ProjectileInstance, arcPoint: ArcPoint)
    if not RunService:IsServer() then return end;

    local hitPart = arcPoint.Hit;
    local hitPosition = arcPoint.Point;
    local projectilePart = projectile.Part;

    projectilePart.CFrame = CFrame.lookAlong(arcPoint.Point, arcPoint.Direction);

    if arcPoint.Hit == nil then return end;
    if projectile.IsDestroyed then return end;

    local properties = projectile.Properties;
    local projRopePoint = properties.ProjRopePoint;
    if projRopePoint then
        projRopePoint.Object = nil;
        projRopePoint.Position = arcPoint.Point;
    end

    local damageBy: CharacterClass? = projectile.CharacterClass;
    
    properties.ArcContacted = true;
    Debugger.Expire(projectilePart, 0);
    
    if projectilePart:CanSetNetworkOwnership() then projectilePart:SetNetworkOwner(nil) end;
    if properties.Activated then return end;
    properties.Activated = true;
    
    local linkObjects = properties.LinkObjects;
    local rope = properties.Rope;

    local healthComp: HealthComp? = modHealthComponent.getByModel(hitPart.Parent);
    if healthComp == nil or not healthComp:CanTakeDamageFrom(damageBy) then 
        if hitPart.Anchored then
            task.delay(1.5, function()
                if rope == nil then return end;
                rope.Locked = true;
                for a=1, #linkObjects do
                    if linkObjects[a]:IsA("BasePart") then
                        linkObjects[a].Color = Color3.fromRGB(64, 40, 40);
                    end
                end
            end)
            
            if properties.NekronVeinSpread then
                task.spawn(function()
                    properties.NekronVeinSpread(hitPart);
                end)
            end

        else
            projectile:Destroy();
        end

        return true; 
    end;

    local targetModel = healthComp:GetModel();
        
    local damage = math.clamp(properties.Damage, 1, math.huge);
    if damage ~= 0 then
        if healthComp.CompOwner.ClassName == "PlayerClass" then
            local player: Player = healthComp.CompOwner:GetInstance();
            
            if properties.OnPlayerStrike then
                local trapPlayer = properties.OnPlayerStrike(player);
                if trapPlayer then
                    rope.Locked = false;
                    projRopePoint.Object = targetModel.HumanoidRootPart;

                    for a=1, #linkObjects do
                        if linkObjects[a]:IsA("BasePart") then
                            linkObjects[a].Color = Color3.fromRGB(64, 40, 40);
                        end
                        if linkObjects[a]:FindFirstChild("CollisionShape") then
                            linkObjects[a].CollisionShape.CanCollide = false;
                        end
                    end
                end

            else
                projectile:Destroy();
                if damageBy and damageBy.ClassName == "NpcClass" then
                    --
                else
                    healthComp:TakeDamage(DamageData.new{
                        Damage = damage;
                        DamageBy = damageBy;
                        TargetPart = hitPart;
                        ToolStorageItem = projectile.StorageItem;
                    });
                end;
                
            end
        end
    end

    modAudio.Play(math.random(1,2)==1 and "BulletBodyImpact" or "BulletBodyImpact2", projectilePart);
    
    return true;
end

function projectilePackage.BindArcStepped(projectile: ProjectileInstance, arcPoint: ArcPoint)
    if projectile.IsDestroyed then return end;

    local properties = projectile.Properties;
    local projectilePart = projectile.Part;

    local rope = properties.Rope;
    local prevStick = properties.PrevStick;

    if prevStick == nil then return end;
    if properties.ArcContacted then return end

    local linkObjects = properties.LinkObjects;
    if #linkObjects > 16 then
        projectile:Destroy();
        return
    end;
    
    properties.DistanceLapsed = properties.DistanceLapsed + arcPoint.Displacement;
    
    local segments = math.ceil(properties.DistanceLapsed / LINK_SIZE);
    if segments < 1 then return; end
    
    properties.DistanceLapsed = properties.DistanceLapsed - segments * LINK_SIZE;
    
    local origin = projectile.OriginCFrame.Position;

    -- new segments needed;
    for a=1, segments do
        local newStick = rope:NewStick(rope:NewPoint(origin), properties.OriginPoint, 9);
        if newStick == nil then return end;
        
        prevStick.Length = 9;
        prevStick.PointB = newStick.PointA;
            
        local newLinkPart = VEINLINK_PREFAB:Clone();
        newLinkPart.Name = `VeinLink{#linkObjects+1}`;

        newStick.Update = function(stick)
            if projectile.IsDestroyed then return end;
            
            local center = (stick.PointA.Position + stick.PointB.Position)/2;
            newLinkPart.CFrame = CFrame.lookAt(center, stick.PointB.Position) * CFrame.Angles(math.rad(90), 0, 0);
        end
        
        newStick:Update();
        newLinkPart.Parent = projectile.Part.Parent;
        table.insert(linkObjects, newLinkPart);
        
        prevStick = newStick;
        properties.PrevStick = prevStick;
    end
end

return projectilePackage;