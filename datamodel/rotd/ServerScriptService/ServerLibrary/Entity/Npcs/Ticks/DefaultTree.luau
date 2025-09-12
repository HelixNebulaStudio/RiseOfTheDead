local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modExplosionHandler = shared.require(game.ReplicatedStorage.Library.ExplosionHandler);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modRegion = shared.require(game.ReplicatedStorage.Library.Region);
local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local treePackage = {
    LogicString = {
        Default = "PreLogic | HasEnemy & (AlertTree | AggroTree) | [Idle]";
        AlertTree = "LookAtEnemy";
        AggroTree = "IgniteDetonation & [Detonate] | [FollowEnemy]";
    };
}

function treePackage.PreLogic(npcClass: NpcClass)
    return false;
end

function treePackage.HasEnemy(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local targetHandlerComp = npcClass:GetComponent("TargetHandler");

    local enemyTargetData = targetHandlerComp:MatchFirstTarget(function(targetData)
        if targetData.HealthComp == nil then return end;
        local targetCharacterClass: CharacterClass = targetData.HealthComp.CompOwner;

        if targetCharacterClass.ClassName == "PlayerClass" then
            local player: Player = (targetCharacterClass :: PlayerClass):GetInstance();

            if npcClass.NetworkOwners then
                local isNetOwner = table.find(npcClass.NetworkOwners, player) ~= nil;
                if not isNetOwner then
                    return false;
                end
            end
        end

        local isAlive = targetCharacterClass.HealthComp.IsDead ~= true;
        if not isAlive then return false end;

        local isTargettable = targetCharacterClass.HealthComp:CanTakeDamageFrom(npcClass);
        if not isTargettable then return false end;

        local isInRange = (targetData.Distance <= properties.TargetableDistance);
        if not isInRange then return false end;

        return true;
    end);

    properties.EnemyTargetData = enemyTargetData;

    return enemyTargetData ~= nil;
end

function treePackage.LookAtEnemy(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    local curTick = tick();
    if properties.LookAtEnemyTick == nil then
        properties.LookAtEnemyTick = curTick + math.random(200, 300)/1000;
		npcClass.PlayAnimation("Aggro");
        return true;

    elseif properties.LookAtEnemyTick > curTick then
        npcClass.Move:Face(enemyNpcClass.RootPart);
        return true;

    end

    return false;
end

function treePackage.IgniteDetonation(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local enemyTargetData = npcClass.Properties.EnemyTargetData;

    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    local targetRootPart = enemyNpcClass.RootPart;
    
    local detonTime = npcClass.Character:GetAttribute("DetonationTime");
    if detonTime == nil then
        if modRegion:InRegion(npcClass.RootPart.Position, targetRootPart.Position, 30) then
            local duration = 4;
            npcClass.Character:SetAttribute("DetonationTime", workspace:GetServerTimeNow()+duration);
            
            local tickingSound = modAudio.Play("ZombieAttack3", targetRootPart);
            tickingSound.Looped = true;
            tickingSound.Volume = 0;

            properties.TickingSound = tickingSound;
            npcClass.Garbage:Tag(tickingSound);
            
            task.spawn(function()
                detonTime = npcClass.Character:GetAttribute("DetonationTime");

                while workspace:GetServerTimeNow() <= detonTime do

                    if npcClass.Character:GetAttribute("DetonationTime") == nil then return end;
                    local timeLeft = npcClass.Character:GetAttribute("DetonationTime")-workspace:GetServerTimeNow();
                    
                    timeLeft = duration-math.clamp(timeLeft, 0, duration);
                    
                    tickingSound.PlaybackSpeed = 1+ (timeLeft/duration * 8);
                    tickingSound.Volume = math.clamp(timeLeft/duration, 0.5, 1);
                    task.wait(0.2);
                    if npcClass.HealthComp.IsDead then break end;
                end

                properties.DetonationReady = true; 
            end)
        end
    end

    if properties.DetonationReady then
        return true;
    end

    return false;
end

function treePackage.Detonate(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;

    local configurations = npcClass.Configurations;
    local properties = npcClass.Properties;
    if properties.IsDetonating then return end;
    properties.IsDetonating = true;

    if not properties.DetonationReady then return end;

    if properties.TickingSound then
        properties.TickingSound:Stop();
        game.Debris:AddItem(properties.TickingSound, 0);
        properties.TickingSound = nil;
    end

    modAudio.Play("TicksZombieExplode", npcClass.RootPart.Position).PlaybackSpeed = math.random(100,120)/100;
		
	local explosionEffectPrefab = game.ReplicatedStorage.Prefabs.NpcAbilities:WaitForChild("TicksExplosionEffect");
    local newEffect = explosionEffectPrefab:Clone();
    local effectMesh = newEffect:WaitForChild("Mesh");
    newEffect.CFrame = npcClass.Head.CFrame;
    newEffect.Parent = workspace.Debris;
    local speed = 0.5;
    local range = 60;

    npcClass.Remote:FireAllClients("Ticks", "detonate", {effectMesh, speed, range});
    Debugger.Expire(newEffect, 1);
    
    local detonatePosition = npcClass.RootPart.Position;
    local targetDistance = enemyTargetData.Distance;

    local damage = configurations.AttackDamage * (1-math.clamp(targetDistance or 15, 0, 30)/30);
    if damage >= 1  then
        local splashReflectedValue = nil;
        task.spawn(function()
            local hitLayers = modExplosionHandler:Cast(detonatePosition, {
                Radius = 20;
            });

            local newExplosionProcessPacket = {
                ExplosionBy = npcClass;
                TargetableEntities = {
                    Humanoid=1;
                    Zombie=1;
                    Bandit=1;
                    Cultist=1;
                    Rat=1;
                };

                Damage = damage;
                ExplosionStun = 1;
                ExplosionStunThreshold = 0;

                IgniteFlammables=false;

                DamageOrigin = detonatePosition;
            };
            
            newExplosionProcessPacket.OnHealthHit = function(healthComp: HealthComp, damage: number)
                local characterClass: CharacterClass = healthComp.CompOwner;
                if characterClass.Character == npcClass.Character then return true end;
                if healthComp:CanTakeDamageFrom(npcClass) == false then return true end;

                if characterClass.ClassName == "NpcClass" then
                    local npcClass: NpcClass = characterClass :: NpcClass;
                    
                    if npcClass.Properties.BasicEnemy then
                        damage = healthComp.MaxHealth * 0.2;

                        if splashReflectedValue then
                            damage = damage*splashReflectedValue;
                        end
                        task.spawn(function()
                            if healthComp.IsDead then return end;
                            if npcClass.Name ~= "Ticks" then return end;

                            task.wait(math.random(50, 250)/1000);
                            npcClass.BehaviorTree:RunTreeLeaf("TicksTree", "Detonate");
                        end)

                    else
                        damage = healthComp.MaxHealth * 0.05;
                    end
                    
                elseif characterClass.ClassName == "PlayerClass" then
                    local playerClass: PlayerClass = characterClass :: PlayerClass;

                    local conGasProtection = playerClass.Configurations.GasProtection;
                    if conGasProtection then
                        damage = damage * (1-conGasProtection);
                    end

                    local conSplashReflection = playerClass.Configurations.SplashReflection;
                    if conSplashReflection then
                        splashReflectedValue = conSplashReflection;
                        newExplosionProcessPacket.ExplosionStun = newExplosionProcessPacket.ExplosionStun*conSplashReflection;
                    end
                    
                    if playerClass.Properties.tickre then
                        return true;
                    end

                    local conTickRepellent = playerClass.Configurations.TickRepellent;
                    if conTickRepellent then
                        playerClass.StatusComp:Apply("tickre", {
                            Expires = workspace:GetServerTimeNow() + conTickRepellent;
                            Duration = conTickRepellent;
                            Values = {
                                Amount = conTickRepellent;
                            }
                        });
                    end

                end

                local dmgData = DamageData.new{
                    DamageBy = npcClass;
                    Damage = damage;
                };
                healthComp:TakeDamage(dmgData);

                task.spawn(function()
                    local remotes = game.ReplicatedStorage.Remotes;
                    local remoteCameraShakeAndZoom = remotes.CameraShakeAndZoom;

                    if characterClass.ClassName == "PlayerClass" then
                        local player: Player = (characterClass :: PlayerClass):GetInstance();
                        remoteCameraShakeAndZoom:FireClient(
                            player,
                            10 * math.clamp(targetDistance/32, 0, 1), 
                            0, 
                            0.5, 
                            0.01, 
                            false
                        );
                    end
                end)

                return true;
            end

            modExplosionHandler:Process(detonatePosition, hitLayers, newExplosionProcessPacket);
        end)
    end

    task.spawn(function()
        game.Debris:AddItem(npcClass.Character:FindFirstChild("ExplosiveTickBlobs"), 0);
        
        local explosionPoint = npcClass.RootPart.Position + Vector3.new(math.random(-20,20)/100, -0.5, math.random(-20,20)/100);
        for _, obj in pairs(npcClass.Character:GetChildren()) do
            if not obj:IsA("BasePart") then continue end;
            
            local motor = obj:FindFirstChildWhichIsA("Motor6D")
            if motor and motor:GetAttribute("RagdollJoint") and obj.Name ~= "LowerTorso" then
                npcClass:BreakJoint(motor);
                
                local force = math.random(80, 140);
                local dir = (obj.Position-explosionPoint).Unit;
                local vel = dir * obj.AssemblyMass * force;
                obj:ApplyImpulse(vel);
            end
            
        end
    end)
    
    npcClass:Kill();

    return true;
end

function treePackage.FollowEnemy(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    npcClass.Move:Follow(enemyNpcClass.RootPart);    
end

function treePackage.Idle(npcClass: NpcClass)
    return false;
end

return treePackage;