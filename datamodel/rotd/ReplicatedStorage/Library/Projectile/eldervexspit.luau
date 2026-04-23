local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modExplosionHandler = shared.require(game.ReplicatedStorage.Library.ExplosionHandler);
local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local projectilePackage = {
	Id = script.Name;

	ArcTracerConfig = {
		Velocity = 50;
		LifeTime = 10;
		RayRadius = 1.5;
		Delta = 1/60;
		Acceleration = Vector3.new(0, -0.2, 0);
        IgnoreEntities = true;
	};

	Properties = {
		Damage = 10;
		ExplosionRadius = 10;
	};
};
--==

function projectilePackage.BindInstance(projectile: ProjectileInstance)
	projectile.Part = script:WaitForChild("vexSpit"):Clone();
end

function projectilePackage.BindArcContact(projectile: ProjectileInstance, arcPoint: ArcPoint)
    local properties = projectile.Properties;
    local damageBy: CharacterClass? = projectile.CharacterClass;

    local projectilePart = projectile.Part;

    if properties.Activated then return end;
    properties.Activated = true;

    projectilePart.Transparency = 1;
    Debugger.Expire(projectilePart, 0.1);

    if not RunService:IsServer() then return end;
    local lastPosition = arcPoint.Point;

    local ex = Instance.new("Explosion");
    ex.DestroyJointRadiusPercent = 0;
    ex.BlastRadius = properties.ExplosionRadius;
    ex.BlastPressure = 0;
    ex.Position = lastPosition;
    ex.Parent = workspace;
    Debugger.Expire(ex, 6);

    local soundDebris = Instance.new("Part");
    soundDebris.Size = Vector3.new(0, 0, 0);
    soundDebris.Anchored = true;
    soundDebris.CanCollide = true;
    soundDebris.Transparency = 1;
    soundDebris.Parent = workspace.Debris;
    Debugger.Expire(soundDebris, 6);
    soundDebris.CFrame = CFrame.new(lastPosition);
    modAudio.Play("TicksZombieExplode", soundDebris).PlaybackSpeed = 1.5;

    pcall(function()
        local readTerrain = (workspace.Terrain:ReadVoxels(Region3.new(lastPosition, lastPosition):ExpandToGrid(4), 4));
        local terrainMat = readTerrain[1] and readTerrain[1][1] and readTerrain[1][1][1];
        if terrainMat and terrainMat == Enum.Material.Water then
            modAudio.Play("ExplosionUnderwater", soundDebris);
        end
    end)

    local hitLayers = modExplosionHandler:Cast(lastPosition, {
        Radius = properties.ExplosionRadius;
    });
    local hitlist = hitLayers and hitLayers[1] or {};
    if damageBy == nil or damageBy.ClassName == "NpcClass" then
        hitlist = hitLayers and hitLayers[1] or {};
    else
        hitlist = hitLayers and hitLayers[2] or {};
    end

    for a=1, #hitlist do
        local hitpart = hitlist[a];
        if not hitpart.Anchored and hitpart:IsDescendantOf(workspace.Environment) then
            local rootModel = hitpart;

            while rootModel:GetAttribute("DynamicPlatform") == nil do
                rootModel = rootModel.Parent;
                if rootModel == workspace or rootModel == game then break; end
            end

            if rootModel:GetAttribute("DynamicPlatform") == nil then
                local assemblyRootPart = hitpart:GetRootPart();
                if assemblyRootPart and assemblyRootPart.Anchored ~= true then
                    assemblyRootPart.Velocity = (assemblyRootPart.Position-lastPosition).Unit*30;

                end
            end
        end
    end

    projectilePackage.damage(projectile, hitlist, lastPosition);
end

function projectilePackage.damage(projectile: ProjectileInstance, hitPartList, lastPosition)
    local damageBy: CharacterClass? = projectile.CharacterClass;
    
    local properties = projectile.Properties;

    hitPartList = type(hitPartList) == "table" and hitPartList or {hitPartList};

    local fs = {};
    for _, hitObj in pairs(hitPartList) do
        local targetModel = hitObj.Parent;

        local healthComp: HealthComp? = modHealthComponent.getByModel(targetModel);
        if healthComp == nil then continue end;
        if healthComp.CompOwner == damageBy then continue end;

        table.insert(fs, function()
            local damage = properties.Damage or 1;

            if not healthComp:CanTakeDamageFrom(damageBy) then return end;

            damage = healthComp.MaxHealth*0.1;

            local dmgData = DamageData.new{
                ToolHandler = projectile.ToolHandler;
                Damage = damage;
                DamageBy = damageBy;
                StorageItem = projectile.StorageItem;
                TargetPart = hitObj;
                DamageType = "Explosive";
            };
            healthComp:TakeDamage(dmgData);

            local assemblyRootPart = targetModel.PrimaryPart or hitObj:GetRootPart();
            if assemblyRootPart and assemblyRootPart.Anchored ~= true then
                assemblyRootPart.Velocity = (assemblyRootPart.Position-lastPosition).Unit*50 + Vector3.new(0, 40, 0);
            end
        end)
    end
    for a=1, #fs do
        fs[a]();
    end
end

return projectilePackage;