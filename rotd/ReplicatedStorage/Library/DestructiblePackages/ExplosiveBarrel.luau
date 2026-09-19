local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modExplosionHandler = shared.require(game.ReplicatedStorage.Library.ExplosionHandler);

local destructiblePackage = {
    Name = "ExplosiveBarrel";
    DebrisName = "ExplosiveBarrel";
};
--==

function destructiblePackage.BindNew(destructible: DestructibleInstance)
    local healthComp: HealthComp = destructible.HealthComp;

    destructible.OnDestroy:Connect(function(reasonData)
        local targetPart = reasonData.TargetPart or destructible.Model:FindFirstChildWhichIsA("BasePart");
        local targetPos = targetPart.Position;
        
        modAudio.Play("VechicleExplosion", targetPos);
        modAudio.Play("Explosion4", targetPos);

		local ex = Instance.new("Explosion");
		ex.DestroyJointRadiusPercent = 0;
		ex.BlastRadius = 16;
		ex.BlastPressure = 0;
		ex.Position = targetPos;
		ex.Parent = workspace;
		Debugger.Expire(ex, 1);
		
		local hitLayers = modExplosionHandler:Cast(targetPos, {
			Radius = 16;
		});

        local damageBy: CharacterClass = reasonData.DamageBy;
		modExplosionHandler:Process(targetPos, hitLayers, {
			ExplosionBy = damageBy;

			ExplosionStun = 1;

			DamageOrigin = targetPos;
			OnPartHit = modExplosionHandler.GenericOnPartHit;

            BindDamageDataNew = function(dmgData: DamageData)
                local damageTo: EntityClass = dmgData.DamageTo :: EntityClass;

                if damageTo.ClassName == "NpcClass" then
                    local npcClass: NpcClass = damageTo :: NpcClass;
					local isBasicEnemy = npcClass.Properties.BasicEnemy == true;
					dmgData.Damage = npcClass.HealthComp.MaxHealth * (isBasicEnemy and math.random(80, 100)/100 or math.random(10, 20)/100);
                    
                    if npcClass.Properties.HasElectronics then
                        npcClass.StatusComp:Apply("StrongRoot", {
                            Expires = workspace:GetServerTimeNow() + 5;
                            Duration = 5;
                        });
                    end

                elseif damageTo.ClassName == "Destructible" then
                    local destructible: DestructibleInstance = damageTo :: DestructibleInstance;
                    dmgData.Damage = math.floor(destructible.HealthComp.MaxHealth * 0.334);

                elseif damageTo.ClassName == "PlayerClass" then
                    dmgData.Damage = 25;

                end
            end;
		});
    end)
end

return destructiblePackage;