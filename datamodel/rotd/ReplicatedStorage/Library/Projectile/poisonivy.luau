local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modTouchHandler = shared.require(game.ReplicatedStorage.Library.TouchHandler);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local projectilePackage = {
	Id = script.Name;

	ArcTracerConfig = {
		LifeTime = 30;
		Velocity = 20;
		Bounce = 0;
		Acceleration = Vector3.new(0, -workspace.Gravity/16, 0);
		IgnoreEntities = true;
	};

	Properties = {
		Damage = 20;
	};
    
    TouchHandler = nil;
};
--==

function projectilePackage.onRequire()
    if RunService:IsServer() then
        local touchHandler = modTouchHandler.new("PoisonIvy", 1);

        function touchHandler:OnPlayerTouch(player, basePart, part)
            local npcChar = basePart.Parent and basePart.Parent.Parent or nil;
            if npcChar == nil or npcChar:FindFirstChildWhichIsA("Humanoid") == nil then return end;

            local npcClass: NpcClass? = shared.modNpcs.getByModel(npcChar);
            if npcClass == nil then return end;

            modAudio.Play(math.random(1,2)==1 and "BulletBodyImpact" or "BulletBodyImpact2", basePart);
            
            local playerClass: PlayerClass = shared.modPlayers.get(player);
            if playerClass == nil then return end;
            if not playerClass.HealthComp:CanTakeDamageFrom(npcClass) then return end;

            modStatusEffects.Poisoned(player, 6);
            playerClass.HealthComp:TakeDamage(DamageData.new{
                Damage = projectilePackage.Properties.Damage;
                DamageBy = npcClass;
            });
        end
        projectilePackage.TouchHandler = touchHandler;
    end
end

function projectilePackage.BindInstance(projectile: ProjectileInstance)
	projectile.Part = script:WaitForChild("poisonWood"):Clone();
end

function projectilePackage.BindArcContact(projectile: ProjectileInstance, arcPoint: ArcPoint)
    local projectilePart = projectile.Part;

    if not RunService:IsServer() then return end;
    if arcPoint.Hit == nil then return end;

    if projectilePart:CanSetNetworkOwnership() then 
        projectilePart:SetNetworkOwner(nil) 
    end;

    local dir = arcPoint.Point + arcPoint.Direction - (arcPoint.Normal or Vector3.zero);
    projectilePart.CFrame = CFrame.new(arcPoint.Point, dir);
    
    projectilePackage.TouchHandler:AddObject(projectilePart);
end

return projectilePackage;