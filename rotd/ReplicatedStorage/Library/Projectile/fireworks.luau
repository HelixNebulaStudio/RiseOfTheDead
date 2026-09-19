local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local projectilePackage = {
	Id = script.Name;

	ArcTracerConfig = {
		LifeTime = 10;
		Acceleration = Vector3.new(0, 296.2, 0);
        KeepAcceleration = true;
		Delta = 1/15;
	};

	Properties = {
		Damage = 100;
	};
};
--==

function projectilePackage.BindInstance(projectile: ProjectileInstance)
	projectile.Part = script:WaitForChild("rocket"):Clone();
    templateFireworksParticle = game.ReplicatedStorage.Particles:WaitForChild("Fireworks");
end

function projectilePackage.PopFireworks(projectilePart)
    projectilePart.Transparency = 1;

    local pop2Snd = projectilePart:WaitForChild("Pop2");
    pop2Snd:Play();
    local bang4Snd = projectilePart:WaitForChild("Bang4");
    bang4Snd:Play();

    local newPar = templateFireworksParticle:Clone();
    local colorPattlet = {
        {ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 4) ); 
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 4))};
        {ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 255) ); 
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 255))};
        {ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 234) ); 
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 234))};
        {ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 226, 0) ); 
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 226, 0))};
        {ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 247) ); 
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 247))};
        {ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 93, 0) ); 
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 93, 0))};
        {ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 8) ); 
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 8))};
    };
    local pickedColor = colorPattlet[math.random(1,#colorPattlet)];

    newPar.Color = ColorSequence.new(pickedColor);
    newPar.Speed = NumberRange.new(math.random(200, 500)/10);
    newPar.Lifetime = NumberRange.new(math.random(300, 800)/100);
    newPar.Parent = projectilePart;

    local light = Instance.new("PointLight");
    light.Color = pickedColor[1].Value;
    light.Range = 60;
    light.Brightness = 1;
    light.Shadows = false;
    light.Parent = projectilePart;

    newPar:Emit(math.random(64, 256));
    game.Debris:AddItem(projectilePart, 2);
end

function projectilePackage.BindFire(projectile: ProjectileInstance)
    local properties = projectile.Properties;
    local projectilePart = projectile.Part;

    local launchSnd = projectilePart:WaitForChild("Launch");
    launchSnd:Play();

    task.delay(math.random(50, 150)/100, function()
        if properties.Popped then return end;
		properties.Popped = true;

        projectilePackage.PopFireworks(projectilePart);
    end)
end

function projectilePackage.BindArcContact(projectile: ProjectileInstance, arcPoint: ArcPoint)
    local hitPart = arcPoint.Hit;

    local damageBy: CharacterClass? = projectile.CharacterClass;
    local properties = projectile.Properties;
    local projectilePart = projectile.Part;

    if RunService:IsServer() then
        if CollectionService:HasTag(hitPart, "Flammable") then
            local modFlammable = shared.require(game.ServerScriptService.ServerLibrary.Flammable);
            modFlammable:Ignite(hitPart);
        end

        if projectilePart:CanSetNetworkOwnership() then projectilePart:SetNetworkOwner(nil) end;

        local targetModel = hitPart.Parent;
        if not targetModel then return end;

        local healthComp: HealthComp = modHealthComponent.getByModel(targetModel);
        if not healthComp then return end;
        targetModel = healthComp:GetModel();

        local damage = 100;
        local damageTo: CharacterClass = healthComp.CompOwner :: CharacterClass;

        if damageTo.ClassName == "NpcClass" then
            local dmgMulti = 1;
            if dmgMulti then
                damage = damage * dmgMulti;
            else
                damage = 0;
            end
        end
        if damage <= 0 then return end;

        if not healthComp:CanTakeDamageFrom(damageBy) then return end;

        healthComp:TakeDamage(DamageData.new{
            ToolHandler = projectile.ToolHandler,
            Damage = damage,
            DamageBy = damageBy,
            StorageItem = projectile.StorageItem,
            TargetPart = hitPart,
            DamageType = "Explosive";
        });

        if hitPart.Anchored and properties.Popped ~= true then
            properties.Popped = true;
            task.spawn(projectilePackage.PopFireworks, projectilePart);
        end

        return properties.Popped;

    else
        local targetModel = hitPart.Parent;
        local humanoid = targetModel and targetModel:FindFirstChildWhichIsA("Humanoid");
        if humanoid then
            modAudio.Play(
                math.random(1,2)==1 and "BulletBodyImpact" or "BulletBodyImpact2", 
                projectilePart
            ).RollOffMaxDistance = 1024;
        end

    end
    
    return;
end

return projectilePackage;