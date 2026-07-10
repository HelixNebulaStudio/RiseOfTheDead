local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");
local TweenService = game:GetService("TweenService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modTouchHandler = shared.require(game.ReplicatedStorage.Library.TouchHandler);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);
local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);
local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local TWEENINFO = TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
local FIRE_COLOR = Color3.fromRGB(103, 0, 62);

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

    TouchHandler = nil;
    PartList = {};
};
--==

function projectilePackage.onRequire()
    if RunService:IsClient() then return end;

    local touchHandler = modTouchHandler.new("OilyOil", 1);
    projectilePackage.TouchHandler = touchHandler;

    function touchHandler:OnHumanoidTouch(humanoid, flammablePart, hitPart)
        local projectile: ProjectileInstance = projectilePackage.PartList[flammablePart];
        if projectile == nil then return end;

        local damageBy: NpcClass = projectile.CharacterClass :: NpcClass;
        local targetModel = hitPart.Parent;

        local targetHealthComp: HealthComp? = modHealthComponent.getByModel(targetModel);
        if targetHealthComp == nil then return; end;
        if targetHealthComp:CanTakeDamageFrom(damageBy) == false then return end;
        targetModel = targetHealthComp:GetModel();

        local damageTo: EntityClass = targetHealthComp.CompOwner;

        local damage = 1;

        if damageTo.ClassName == "NpcClass" and damageTo.HumanoidType ~= "Zombie" then
            local npcClass: NpcClass = damageTo :: NpcClass;
            local maxHealth = npcClass.HealthComp.MaxHealth;

            if npcClass.Properties.Infector == true then
                damage = maxHealth * 0.05;
            else
                damage = math.clamp(maxHealth * 0.05, 35, 5000);
            end

        elseif damageTo.ClassName == "PlayerClass" then
            local playerClass: PlayerClass = damageTo :: PlayerClass;
            modStatusEffects.Burn(playerClass:GetInstance(), 10, 5);

        end

        local dmgData = DamageData.new{
            DamageBy = damageBy;
            Damage = damage;
            StorageItem = self.StorageItem;
            TargetPart = hitPart;
            DamageType = "Fire";
        };

        targetHealthComp:TakeDamage(dmgData);
    end
end

function projectilePackage.GetProjectileFromPart(part)
    return projectilePackage.PartList[part];
end

function projectilePackage.Ignite(projectile: ProjectileInstance)
    if projectile == nil then return end;
    
    local npcClass: NpcClass = projectile.CharacterClass :: NpcClass;
    if npcClass == nil or npcClass.HealthComp == nil then return end;
    
    local projectilePart = projectile.Part;
    if projectilePart == nil then return end;

    local FIRE_PARTICLE: ParticleEmitter = game.ReplicatedStorage.Particles.Fire2;
    FIRE_PARTICLE.Color = ColorSequence.new(FIRE_COLOR);
    
	local newFire = FIRE_PARTICLE:Clone();
	newFire.Parent = projectilePart;

	if math.random(1, 3) == 1 then
		local fireAtt = Instance.new("Attachment");
		fireAtt.Name = "_naturalLight";
		fireAtt.Parent = newFire;
		fireAtt.WorldCFrame = CFrame.new(modVector.GetRandomSurfacePoint(projectilePart, math.pi/4));

		local sizeMag = projectilePart.Size.Magnitude;
		local fireParticle = Instance.new("Fire");
        fireParticle.Color = FIRE_COLOR;
		fireParticle.Size = math.random(2, math.max(3, sizeMag));
		fireParticle.Heat = fireParticle.Size/(math.random(101, 178)/100);
		fireParticle.Parent = fireAtt;

		local pointLight = Instance.new("PointLight");
		pointLight.Color = FIRE_COLOR;
		pointLight.Brightness = 1;
		pointLight.Range = fireParticle.Size * 2;
		pointLight.Shadows = false;
		pointLight.Parent = fireAtt;
	end

	if math.random(1, 5) == 1 then
		local sound = modAudio.Play("Fire", projectilePart, true);
		sound.Volume = math.random(1, 3)/10;
	end;

	task.spawn(function()
		task.wait(math.random(0, 2500)/10000);
		local sound = modAudio.Play(`FireBall{math.random(1,4)}`, projectilePart);
		sound.PlaybackSpeed = math.random(900,1100)/1000;
	end)

	task.delay(0.5, function()
		projectilePackage.TouchHandler:AddObject(projectilePart);
	end)
end

function projectilePackage.BindInstance(projectile: ProjectileInstance)
	projectile.Part = script:WaitForChild("oilyoil"):Clone();
end

function projectilePackage.BindFire(projectile: ProjectileInstance)
    local projectilePart = projectile.Part;
end

function projectilePackage.BindArcContact(projectile: ProjectileInstance, arcPoint: ArcPoint)
    local hitPart = arcPoint.Hit;
    local hitPosition = arcPoint.Point;

    local properties = projectile.Properties;
    local projectilePart = projectile.Part;

    local damageBy: CharacterClass? = projectile.CharacterClass;
    
    if hitPart.Name == "oilyoil" then
        local despawnTime = projectilePart:GetAttribute("DespawnTime");
        if despawnTime then
            projectilePart:SetAttribute("DespawnTime", tick()+60);
        end
        
        projectilePart:Destroy();
        return;
    end
    
    projectilePart.Anchored = true;
    
    if projectilePart.Parent == nil then return end;
    
    projectilePart.CFrame = CFrame.lookAlong(hitPosition, arcPoint.Normal) * CFrame.Angles(math.rad(-90), 0, 0);
    
    if projectilePart.Parent and projectilePart.Parent.Name ~= "oilyoil" then
        local newModel = Instance.new("Model");
        newModel.Name = "oilyoil";
        newModel.Parent = workspace.Environment;

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

    projectilePackage.PartList[projectilePart] = projectile;
    projectile.Garbage:Tag(function()
        projectilePackage.PartList[projectilePart] = nil;
    end)
end

return projectilePackage;