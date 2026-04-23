local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);

local projectilePackage = {
	Id = script.Name;

	ArcTracerConfig = {
		Velocity = 10;
		LifeTime = 5;
		Bounce = 0;
		Acceleration = Vector3.new(0, -0.2, 0);
		KeepAcceleration = true;
		RayRadius = 1.5;

		IgnoreEntities = true;
		AddTagsToArcTracer = {"PlayerCharacters"};
	};

	Properties = {
		Damage = 100;
	};
};
--==

function projectilePackage.BindInstance(projectile: ProjectileInstance)
	projectile.Part = script:WaitForChild("gasCloud"):Clone();
end

function projectilePackage.BindFire(projectile: ProjectileInstance)
    local projectilePart = projectile.Part;

    local gasEmitter = projectilePart:WaitForChild("SporeGasEmitter");
    gasEmitter:Emit(3);
end

function projectilePackage.BindArcContact(projectile: ProjectileInstance, arcPoint: ArcPoint)
    local projectilePart = projectile.Part;

    if arcPoint.Hit == nil then return end;
    Debugger.Expire(projectilePart, 0);

    local player: Player = game.Players:GetPlayerFromCharacter(arcPoint.Hit.Parent);

    if player then
        local playerClass: PlayerClass = shared.modPlayers.get(player);
        local statusComp: StatusComp = playerClass.StatusComp;

        for k, statusClass: StatusClassInstance in pairs(statusComp.List) do
            if statusClass.Buff == false then continue end;
            if statusClass.Cleansable ~= true then continue end;
            if statusClass.Expires == nil then continue end;

            statusClass.Expires = workspace:GetServerTimeNow();
            statusClass:Sync();
        end

        modStatusEffects.Dizzy(player, 3, "bloater");
    end

    return true;
end

return projectilePackage;