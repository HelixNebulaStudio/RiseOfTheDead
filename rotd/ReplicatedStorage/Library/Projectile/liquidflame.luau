local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modTouchHandler = shared.require(game.ReplicatedStorage.Library.TouchHandler);
local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

if RunService:IsServer() then
    modFlammable = shared.require(game.ServerScriptService.ServerLibrary.Flammable);
end

local STATUS_KEY = "LiquidFlame";

local projectilePackage = {
	Id = script.Name;

	ArcTracerConfig = {
		Velocity = 50;
		LifeTime = 10;
		Bounce = 0;
		Acceleration = Vector3.new(0, -workspace.Gravity/16, 0);
		KeepAcceleration = true;
		IgnoreEntities = false;
        IgnoreWater = false;
		AddTagsToArcTracer = {"LiquidFlame"};
	};

	Properties = {
		Damage = 100;
	};

    PartList = {};
    TouchHandler = nil;
};
--==

function projectilePackage.onRequire()
    if RunService:IsServer() then
        local touchHandler = modTouchHandler.new(script.Name, 0.333);
        
        function touchHandler:OnHumanoidTouch(humanoid, hitbox, part)
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

            projectilePackage.enemyHit(projectile, part, healthComp);

            modAudio.Play(`BurnTick{math.random(1, 3)}`, part).PlaybackSpeed = math.random(90, 110)/100;
        end

        projectilePackage.TouchHandler = touchHandler;
    end
end

function projectilePackage.BindInstance(projectile: ProjectileInstance)
    local projectilePart = script:WaitForChild("flammable"):Clone();
    
    local fireParticle2 = game.ReplicatedStorage.Particles.Fire2:Clone();
    fireParticle2.Parent = projectilePart;

	projectile.Part = projectilePart;
    projectilePart.Transparency = 1;
    
    CollectionService:AddTag(projectilePart, "Flammable");
end

function projectilePackage.BindFire(projectile: ProjectileInstance)
    local properties = projectile.Properties;
    local projectilePart = projectile.Part;
    
    local despawnTime = projectile.ArcTracerConfig.LifeTime + (properties.EverlastDuration or 0);
    if properties.FixedLifeTime then
        despawnTime = properties.FixedLifeTime;
        game.Debris:AddItem(projectilePart, despawnTime);
    end

    projectilePart:SetAttribute("DespawnTime", tick()+despawnTime);
    
    if math.random(1, 4) == 1 then
        task.delay(math.random(0, 20)/100, function()
            local sound = modAudio.Play("Fire", projectilePart, true);
            sound.Volume = math.random(10, 30)/100;
        end);
    end;

	local particles = projectilePart:WaitForChild("Fire2");
    particles.LockedToPart = true;
    particles:Emit(4);

    local att = Instance.new("Attachment");
    att.Name = "FireAtt";

    local fireParticle = game.ReplicatedStorage.Particles.Fire;
    fireParticle:Clone().Parent = att;
    att.Parent = projectilePart;
end

function projectilePackage.enemyHit(projectile: ProjectileInstance, hitPart, healthComp)
    local properties = projectile.Properties;
    local damageBy: CharacterClass? = projectile.CharacterClass;

    local projectilePart = projectile.Part;
    local damage = (properties.Damage or 1);
    
    local damageTo: EntityClass = healthComp.CompOwner :: EntityClass;
    local damageData = DamageData.new{
        Damage = damage;
        DamageBy = damageBy;
        DamageTo = damageTo;

        ToolHandler = projectile.ToolHandler;
        StorageItem = projectile.StorageItem;
        TargetPart = hitPart;

        DamageType = "Fire";
        DamageCate = DamageData.DamageCategory.Projectile;
    };
    
    if damageTo.ClassName == "NpcClass" or damageTo.ClassName == "PlayerClass" then
        local statusComp: StatusComp = (damageTo :: CharacterClass).StatusComp;
    
        local statusClass: StatusClassInstance = statusComp:GetOrDefault(STATUS_KEY);
        if statusClass == nil then
            statusComp:Apply(STATUS_KEY, {
                Expires = workspace:GetServerTimeNow()+5;
                ApplyBy = damageBy;
                Values = {
                    TargetPart = hitPart;
                    
                    Damage = damage;
                    Stacks = 1;
                };
            });
        else
            statusClass.Values.Stacks = statusClass.Values.Stacks +1;
            statusClass.Expires = workspace:GetServerTimeNow()+5;
        end
        
    elseif damageTo.ClassName == "Destructible" then
        for a=1, 10 do
            projectile:PreTakeDamageDamageData(damageData);
            healthComp:TakeDamage(damageData);
            
            task.wait(0.5);
            if healthComp.CurHealth <= 0 then break; end;
        end
    end
    
    if damage and damage > 0 then
        projectile:PreTakeDamageDamageData(damageData);
        healthComp:TakeDamage(damageData);
        
        local oldDespawnTime = projectilePart:GetAttribute("DespawnTime");
        projectilePart:SetAttribute("DespawnTime", oldDespawnTime-0.1);
        if tick() > oldDespawnTime then
            projectilePart:Destroy();
            Debugger.Expire(projectilePart);
        end
    end
end

function projectilePackage.BindArcContact(projectile: ProjectileInstance, arcPoint: ArcPoint)
    if RunService:IsClient() then return end

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
        steam:Emit(1);

        return true;
    end;

    local damageBy: CharacterClass? = projectile.CharacterClass;

    local touched = {};
    local function onFlameTouch(hitPart)
        if hitPart == nil then return end;
        if RunService:IsClient() then return end; -- old;
        if hitPart.Name == "_Water" and hitPart:IsDescendantOf(workspace.Debris) then 
            Debugger.Expire(projectilePart); 
            return 
        end;

        local healthComp: HealthComp? = modHealthComponent.getByModel(hitPart.Parent);
        if healthComp == nil or healthComp.IsDead or not healthComp:CanTakeDamageFrom(damageBy) then 
            return
        end;

        local targetModel = healthComp:GetModel();
        if targetModel == nil then return end;

        if table.find(touched, targetModel) then return end;
        table.insert(touched, targetModel);

	 	task.spawn(function()
			projectilePackage.enemyHit(projectile, hitPart, healthComp);
		end);
    end
    
    if hitPart and hitPart.Anchored ~= true then
        onFlameTouch(hitPart);
        return;
    end
    
    if properties.Activated then return end;
    properties.Activated = true;
    
	local particles = projectilePart:WaitForChild("Fire2");
    particles.LockedToPart = false;
    
    local landingCframe = CFrame.lookAlong(arcPoint.Point, arcPoint.Normal)  * CFrame.Angles(math.rad(-90), 0, 0);

    local rngSize = math.random(18, 22)/10;
    local newSize = Vector3.new(rngSize, 0.6, rngSize);
    
    projectilePart:SetAttribute("Owner", damageBy and damageBy.Name);
    projectilePart.Size = newSize;
    projectilePart.CFrame = landingCframe;
    projectilePart.Transparency = 0.8;
    
    if hitPart == nil then return end;
    
    local newFlame = hitPart;
    

    if not newFlame:HasTag("LiquidFlame") then
        local overlapParam = OverlapParams.new();
        overlapParam.IncludeInstances = CollectionService:GetTagged("LiquidFlame");
        overlapParam.MaxParts = 1;
        
        local hitList = workspace:GetPartBoundsInBox(landingCframe, newSize*1.5, overlapParam);
        
        if #hitList > 0 then
            newFlame = hitList[1];
        end
    end
    
    if newFlame:HasTag("LiquidFlame") then
        newFlame:SetAttribute("Owner", damageBy and damageBy.Name);
        newFlame:SetAttribute("DespawnTime", projectilePart:GetAttribute("DespawnTime"));
        
        newSize = newFlame.Size.X+0.5;
        newFlame.Size = Vector3.new(math.clamp(newSize, 2, 4), 0.6, math.clamp(newSize, 2, 4))
        
        local flames = newFlame:GetChildren();
        if #flames <= 4 then
            local oldFireAtt = projectilePart.FireAtt;
            oldFireAtt.Parent = newFlame;
            oldFireAtt.WorldCFrame = CFrame.new(landingCframe.X, newFlame.Position.Y, landingCframe.Z);
            
            if oldFireAtt:FindFirstChild("Fire") then
                oldFireAtt.Fire.Size = math.clamp(oldFireAtt.Fire.Size +1, 3, 12);
            end
            
        else
            local fireAtt = nil;
            for a=1, #flames do
                if flames[a].Name == "FireAtt" then
                    fireAtt = flames[a];
                    break;
                end
            end
            
            fireAtt.WorldCFrame = CFrame.new(landingCframe.X, newFlame.Position.Y, landingCframe.Z);

            if fireAtt:FindFirstChild("Fire") then
                fireAtt.Fire.Size = math.clamp(fireAtt.Fire.Size +1, 3, 12);
            end
            
        end

        Debugger.Expire(projectilePart);
        return true;
        
    else
        if projectilePart:FindFirstChild("FireAtt") then
            projectilePart.FireAtt.WorldCFrame = CFrame.new(projectilePart.FireAtt.WorldCFrame.Position);
        end

        projectilePackage.PartList[projectilePart] = projectile;
        projectilePackage.TouchHandler:AddObject(projectilePart);
        projectile.Garbage:Tag(function()
            projectilePackage.PartList[projectilePart] = nil;
        end)
        onFlameTouch(hitPart);

        task.spawn(function()
            while workspace:IsAncestorOf(projectilePart) do
                local overlapParam = OverlapParams.new();
                overlapParam.IncludeInstances = CollectionService:GetTagged("Flammable");
                overlapParam.MaxParts = 1;
                
                local hitList = workspace:GetPartBoundsInBox(
                    projectilePart.CFrame, 
                    projectilePart.Size*1.5, 
                    overlapParam
                );
                if #hitList > 0 then
                    modFlammable:Ignite(hitList[1]);
                end

                task.wait(math.random(4, 10) + (#CollectionService:GetTagged("LiquidFlame") * 0.25));
            end
        end)
        
        projectilePart:AddTag("LiquidFlame");

        return true;
    end
end

return projectilePackage;