local modProjectile = shared.require(game.ReplicatedStorage.Library.Projectile);
--==
local destructiblePackage = {
    Name = "GasPipe";
    DisableDestroy = true;
};

function destructiblePackage.BindNew(destructible: DestructibleInstance)
    local healthComp: HealthComp = destructible.HealthComp;
    healthComp:SetMaxHealth(1);
    healthComp:SetHealth(1);

    local pipeFuel = 100;

    local random = Random.new();
    destructible.OnDestroy:Connect(function(reasonData)
        local targetPart = reasonData.TargetPart;
        if targetPart == nil then return end;

		local oldColor = targetPart.Color;
		targetPart.Color = Color3.new(
            math.clamp(oldColor.R * 0.5, 0, 1), 
            math.clamp(oldColor.G * 0.5, 0, 1), 
            math.clamp(oldColor.B * 0.5, 0, 1)
        );
		
		repeat
			local origin = CFrame.new(targetPart.Position);
			
            local projectileInstance: ProjectileInstance = modProjectile.fire("gasoline", {
                CharacterClass = reasonData.DamageBy;
                OriginCFrame = origin;
                SpreadDirection = Vector3.new(0, -1, 0);
            });

			local dirCf = CFrame.lookAt(origin.Position, origin.Position + Vector3.new(
                random:NextNumber(-1,1), 0, 
                random:NextNumber(-1,1))
            ).LookVector * random:NextNumber(0, 1.4);
			
            modProjectile.serverSimulate(projectileInstance, {
                Velocity = dirCf * 20;
                RayWhitelist = {workspace.Environment; workspace.Terrain};
                IgnoreEntities = true;
            });
			
			task.wait(math.random(3,6)/10);
			pipeFuel = pipeFuel - math.random(1, 5);
		until pipeFuel <= 0;
		
		task.delay(20, function()
			pipeFuel = 100;
			targetPart.Color = oldColor;

            healthComp:Reset();
		end)
    end)
end

return destructiblePackage;