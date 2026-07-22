local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
local modSfxService = shared.require(game.ReplicatedStorage.Library.SfxService);
local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);
local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local raycastParams = RaycastParams.new();
raycastParams.FilterType = Enum.RaycastFilterType.Include;
raycastParams.IgnoreWater = true;
raycastParams.FilterDescendantsInstances = {workspace.Environment};
raycastParams.CollisionGroup = "Raycast";

local projectilePackage = {
	Id = script.Name;

	ArcTracerConfig = {
		LifeTime = 5;
		Velocity = 50;
		Bounce = 0;
		Acceleration = Vector3.new(0, -workspace.Gravity/8, 0);
		RayRadius = 0.5;
	};

	Properties = {
		Damage = 5;
	};
    
};
--==

function projectilePackage.BindInstance(projectile: ProjectileInstance)
    local newProjectile = script:WaitForChild("junkRoot"):Clone();

    local junkList = newProjectile:GetChildren();
    for a=#junkList, 1, -1 do
        if junkList[a]:IsA("BasePart") or junkList[a]:IsA("Model") then continue end;
        table.remove(junkList, a);
    end
    local chosenJunk = junkList[math.random(1, #junkList)];
    for _, obj in pairs(junkList) do
        if obj == chosenJunk then continue end;
        obj:Destroy();
    end
    local weld = chosenJunk:FindFirstChild("junkWeld", true);
    if weld then
        weld.C1 = CFrame.Angles(
            math.rad(math.random(0, 360)), 
            math.rad(math.random(0, 360)), 
            math.rad(math.random(0, 360))
        );
    end

	projectile.Part = newProjectile;
end

function projectilePackage.BindArcContact(projectile: ProjectileInstance, arcPoint: ArcPoint)
    if arcPoint.Hit == nil then return end;

    local projectilePart = projectile.Part;
    local properties = projectile.Properties;

    if properties.Popped then return end;
    properties.Popped = true;

    if RunService:IsClient() then return end;

    local hitPart, hitPoint = arcPoint.Hit, arcPoint.Point;
    local damageBy: CharacterClass? = projectile.CharacterClass;

    local touchConn;
    local function onContact(toucheePart)
        if toucheePart == nil then return end;

        local healthComp: HealthComp? = modHealthComponent.getByModel(toucheePart.Parent);
        if healthComp == nil or healthComp.IsDead or not healthComp:CanTakeDamageFrom(damageBy) then 
            return
        end;

        local targetModel = healthComp:GetModel();
        if targetModel == nil then return end;

        local toucherEntityClass: EntityClass = healthComp.CompOwner;
        if toucherEntityClass.ClassName ~= "PlayerClass" then return end;
        
        if arcPoint.Hit == toucheePart then
            modSfxService.spawnImpactEffect{
                BasePart = arcPoint.Hit;
                Point = arcPoint.Point;
                Normal = arcPoint.Normal;
            };
        else
            modSfxService.spawnImpactEffect{
                BasePart = toucheePart;
                Point = toucheePart.Position;
            };
        end

        touchConn:Disconnect();
        touchConn = nil;
        
        local targetCharacterClass = toucherEntityClass :: CharacterClass;
        
        local junkStatus = targetCharacterClass.StatusComp:GetOrDefault("EmcumberingJunk");
        
        local newAmt = 5;
        if junkStatus then
            newAmt += junkStatus.Values.Amount;
        end

        targetCharacterClass.StatusComp:Apply("EmcumberingJunk", {
            Expires = workspace:GetServerTimeNow() + 30;
            Duration = 30;
            Values = {
                Amount = newAmt;
            };
        });

        healthComp:TakeDamage(DamageData.new{
            DamageBy = damageBy;
            Damage = projectile.Properties.Damage;
        });

        Debugger.Expire(projectilePart);
    end

    touchConn = projectilePart.Touched:Connect(onContact);
    onContact(hitPart);

    local junkDebris: BasePart = projectilePart:Clone();
    Debugger.Expire(projectilePart);

    Debugger.Expire(junkDebris, 5);
    junkDebris.Anchored = false;
    junkDebris.Massless = true;

    local weld = Instance.new("Weld");
    weld.Name = "weld";
    weld.Parent = junkDebris;

    weld.Part0 = junkDebris;
    weld.Part1 = hitPart;

    local worldCf = CFrame.lookAlong(hitPoint, arcPoint.Direction);
    weld.C1 = hitPart.CFrame:ToObjectSpace(worldCf);

    junkDebris.Parent = workspace.Debris;
    
    local junkWeld = junkDebris:FindFirstChild("junkWeld", true);
    if junkWeld then
        junkWeld.C0 = CFrame.identity;
    end
    
    return true;
end

return projectilePackage;