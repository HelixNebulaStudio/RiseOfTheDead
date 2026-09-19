local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local projectilePackage = {
	Id = script.Name;

	ArcTracerConfig = {
		Velocity = 50;
		LifeTime = 0.5;
		Bounce = 0;
		Acceleration = Vector3.new(0, 4, 0);
		KeepAcceleration = true;
		IgnoreEntities = false;
		RayRadius = 2;
	};

	Properties = {
		Damage = 100;
	};
};
--==

function projectilePackage.onRequire()
    if RunService:IsServer() then
        local fireParticle2: ParticleEmitter = game.ReplicatedStorage.Particles.Fire2:Clone();
        fireParticle2.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255));
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 0));
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255));
        });
        fireParticle2.Rate = 0;
        fireParticle2.Lifetime = NumberRange.new(0.7);
        fireParticle2.Parent = script:WaitForChild("Flame");
    end
end

function projectilePackage.BindInstance(projectile: ProjectileInstance)
	projectile.Part = script:WaitForChild("Flame"):Clone();

end

function projectilePackage.BindFire(projectile: ProjectileInstance)
    local particles = projectile.Part:WaitForChild("Fire2");
    particles.LockedToPart = true;
    task.spawn(function()
        for a=1, 3 do
            particles:Emit(3);
            task.wait();
            task.wait();
        end
    end)
end

function projectilePackage.BindArcContact(projectile: ProjectileInstance, arcPoint: ArcPoint)
    local properties = projectile.Properties;

    if properties.Activated then return end;
    local hitPart = arcPoint.Hit;

    local projectilePart = projectile.Part;
    
    local touched = properties.Touched or {};
    if properties.Touched == nil then
        properties.Touched = touched;
    end 
   
    local damageBy: CharacterClass? = projectile.CharacterClass;

    local function onFlameTouch(hitPart)
        if hitPart == nil then return end;
        if RunService:IsClient() then return end;
        if hitPart.Name == "_Water" and hitPart:IsDescendantOf(workspace.Debris) then 
            Debugger.Expire(projectilePart, 0); 
            return 
        end;

        local targetModel = hitPart.Parent;
        local healthComp: HealthComp? = modHealthComponent.getByModel(targetModel);
        if healthComp == nil or not healthComp:CanTakeDamageFrom(damageBy) then return end;
        targetModel = healthComp:GetModel();
        
        if healthComp.CompOwner == damageBy then return end;

        if touched[targetModel] ~= nil then
            return;
        end
        touched[targetModel] = true;
        
        task.spawn(function()
            projectilePackage.enemyHit(projectile, hitPart, healthComp);
        end);
    end
    
    if CollectionService:HasTag(hitPart, "Flammable") then
        local modFlammable = shared.require(game.ServerScriptService.ServerLibrary.Flammable);
        modFlammable:Ignite(hitPart);
    end
    
    onFlameTouch(hitPart);
    
    if arcPoint.LastPoint then
        properties.Activated = false;
        table.clear(touched);
    end
end

function projectilePackage.enemyHit(projectile: ProjectileInstance, hitPart, healthComp)
    local properties = projectile.Properties;
    
    local damageBy: CharacterClass? = projectile.CharacterClass;

    local damage = properties.Damage;
    local knockbackForce = properties.KnockbackForce or 1;

    local fireDuration = 25 + (properties.EverlastDuration or 0);
    if properties.FixedLifeTime then
        fireDuration = properties.FixedLifeTime;
    end
    
    local damageTo: EntityClass = healthComp.CompOwner;
    local damageData = DamageData.new{
        Damage = damage;
        DamageBy = projectile.CharacterClass;
        DamageTo = damageTo;
        
        ToolHandler = projectile.ToolHandler;
        StorageItem = projectile.StorageItem;
        TargetPart = hitPart;
        DamageType = "Fire";
        DamageCate = DamageData.DamageCategory.Projectile;
    };

    if damageTo.ClassName == "NpcClass" then
        local npcClass: NpcClass = damageTo :: NpcClass;
        
        local statusClass: StatusClassInstance = npcClass.StatusComp:GetOrDefault("LiquidFlame");
        if statusClass == nil then
            npcClass.StatusComp:Apply("LiquidFlame", {
                Expires = workspace:GetServerTimeNow() + fireDuration;
                Duration = fireDuration;
                ApplyBy = projectile.CharacterClass;
                Values = {
                    TargetPart = hitPart;
                    Damage = (damage * 0.5);
                    Stacks = 1;
                };
            });

        else
            statusClass.Expires = workspace:GetServerTimeNow() + fireDuration;
            statusClass.Duration = fireDuration;
            statusClass.Values.Stacks += 1;
            
        end

        projectile:PreTakeDamageDamageData(damageData);
        healthComp:TakeDamage(damageData);

        if npcClass.KnockbackResistant == nil or npcClass.KnockbackResistant == 0 then
            local knockbackStrength = knockbackForce;
            if knockbackStrength and damageBy then
                local knockDir = (damageTo:GetCFrame().Position - damageBy:GetCFrame().Position).Unit;
                local toRootPart = damageTo.RootPart;
                toRootPart.Velocity = (knockDir * knockbackStrength) + Vector3.new(0, 40, 0);
            end
        end
        
    elseif healthComp.CompOwner.ClassName == "Destructible" then
        projectile:PreTakeDamageDamageData(damageData);
        healthComp:TakeDamage(damageData);
        
    elseif healthComp.CompOwner.ClassName == "PlayerClass" then
        local playerClass: PlayerClass = healthComp.CompOwner :: PlayerClass;
        local player: Player = playerClass:GetInstance();

        modStatusEffects.Burn(player, 50, 5);
        
        projectile:PreTakeDamageDamageData(damageData);
        healthComp:TakeDamage(damageData);
    end
		
end

return projectilePackage;