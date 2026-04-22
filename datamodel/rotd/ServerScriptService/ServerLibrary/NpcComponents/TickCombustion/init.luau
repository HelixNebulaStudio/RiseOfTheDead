local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);
local modExplosionHandler = shared.require(game.ReplicatedStorage.Library.ExplosionHandler);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);
local modRaycastUtil = shared.require(game.ReplicatedStorage.Library.Util.RaycastUtil);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modObjectPool = shared.require(game.ReplicatedStorage.Library.Util.ObjectPool);

local Component = {};
Component.ClassName = "NpcComponent";
Component.__index = Component;
Component.Pool = nil;

function Component.onRequire()
	remoteNpcComponent = modRemotesManager:Get("NpcComponent");
    explosionEffectPrefab = game.ReplicatedStorage.Prefabs.NpcAbilities:WaitForChild("TicksExplosionEffect");
    tickBlobsPrefab = game.ReplicatedStorage.Prefabs.NpcAbilities:WaitForChild("TickBlobs"):GetChildren();

    Component.Pool = modObjectPool.new(explosionEffectPrefab, 4);
end

function Component.new(npcClass: NpcClass)
	local self = {
		NpcClass = npcClass;
        CombustOnDeath = true;
	};
	
    npcClass.Garbage:Tag(function()
        local properties = npcClass.Properties;
        
        if properties.TickingSound then
            properties.TickingSound:Stop();
            game.Debris:AddItem(properties.TickingSound, 0);
            properties.TickingSound = nil;
        end
    end)

    local npcChar = npcClass.Character;
    task.spawn(function()
        if npcChar:FindFirstChild("ExplosiveTickBlobs") == nil then
            local blobsModel = Instance.new("Model");
            blobsModel.Name = "ExplosiveTickBlobs";
            blobsModel.Parent = npcChar;

            local bodyParts = {};
            if npcChar:FindFirstChild("UpperTorso") then
                table.insert(bodyParts, npcChar.UpperTorso);
            end
            if npcChar:FindFirstChild("LowerTorso") then
                table.insert(bodyParts, npcChar.LowerTorso);
            end
            if npcChar:FindFirstChild("Head") then
                table.insert(bodyParts, npcChar.Head);
            end

            if #bodyParts > 0 then 
                for a=3, math.random(4, 6) do
                    local bodyPart = bodyParts[math.random(1, #bodyParts)];
                    local rngDir = modVector.RandomUnitVector(3);
                    local surPos, surNorm = modRaycastUtil.getSurfaceFromDirection(bodyPart, rngDir);
                    if surPos == nil then continue end;

                    local newCf = CFrame.lookAlong(surPos, surNorm);
                    local newBlob = tickBlobsPrefab[math.random(1, #tickBlobsPrefab)]:Clone();
                    newBlob.CFrame = newCf;
                    newBlob.Parent = blobsModel;
                    newBlob.Transparency = 0;
                    newBlob.Size = Vector3.one * math.random(350, 600)/1000;

                    local weld = Instance.new("Weld");
                    weld.Parent = newBlob;
                    weld.Part0 = bodyPart;
                    weld.Part1 = newBlob;
                    weld.C0 = bodyPart.CFrame:ToObjectSpace(newCf);
                end
            end
        end
    end)

	setmetatable(self, Component);

    npcClass.HealthComp.OnIsDeadChanged:Connect(function(isDead)
        if not isDead then return end;
        if self.CombustOnDeath == false then return end;

        local lvl = npcClass.Properties.Level;
        self(math.max(lvl, 20), math.clamp(lvl*2, 40, 80), false);
    end)

	return self;
end

function Component:__call(damage, range, isLethal)
	local npcClass: NpcClass = self.NpcClass;
	local properties = npcClass.Properties;

    local explosionPoint = npcClass:GetCFrame().Position;

    modAudio.Play("TicksZombieExplode", explosionPoint).PlaybackSpeed = math.random(100,120)/100;

    local newExplosionPart = Component.Pool:Get();
    
    local effectMesh = newExplosionPart:WaitForChild("Mesh");
    effectMesh.Scale = Vector3.one * math.random(0, 99)/10000000;
    newExplosionPart.Transparency = math.random(0, 99)/10000000;
    newExplosionPart.CFrame = npcClass.Head.CFrame;
    newExplosionPart.Parent = workspace.Debris;

    local tweenTime = 0.5;
    range = range or 60;

    remoteNpcComponent:FireAllClients("TickCombustion", "detonate", effectMesh, tweenTime, range);
    task.delay(1, function()
        Component.Pool:Return(newExplosionPart);
    end)

    local splashReflectedValue = nil;
    task.spawn(function()
        local hitLayers = modExplosionHandler:Cast(explosionPoint, {
            Radius = 20;
        });

        local newExplosionProcessPacket = {
            ExplosionBy = npcClass;

            Damage = (damage or 30);
            ExplosionStun = 1;
            ExplosionStunThreshold = 0;

            IgniteFlammables = false;

            DamageOrigin = explosionPoint;
        };
        
        newExplosionProcessPacket.BindHealthCompHit = function(explodeHealthComp: HealthComp, damage: number)
            local explodeEntityClass: EntityClass = explodeHealthComp.CompOwner :: EntityClass;
            if explodeEntityClass == npcClass then return true end;
            if explodeHealthComp:CanTakeDamageFrom(npcClass) == false then return true end;

            local dist = explodeEntityClass:DistanceFrom(explosionPoint);
            if dist >= 30 then return true end;

            local dmgMulti = (1-math.clamp(dist, 0, 30)/30);
            local dmgData = DamageData.new{
                DamageBy = npcClass;
                Damage = damage * dmgMulti;
            };

            if explodeEntityClass.ClassName == "NpcClass" then
                local explodeNpcClass: NpcClass = explodeEntityClass :: NpcClass;
                
                if explodeNpcClass.Properties.BasicEnemy then
                    damage = explodeHealthComp.MaxHealth * 0.2;

                    if splashReflectedValue then
                        damage = damage*splashReflectedValue;
                    end
                    task.spawn(function()
                        if explodeHealthComp.IsDead then return end;
                        local tickCombustionComp = explodeNpcClass:GetComponent("TickCombustion");
                        if tickCombustionComp == nil then return end;

                        task.wait(math.random(50, 250)/1000);
                        if explodeHealthComp.IsDead then return end;

                        tickCombustionComp(math.max(damage/2, 10), range+4, isLethal);
                    end)

                    if newExplosionProcessPacket.ExplosionStun then
                        explodeNpcClass.StatusComp:Apply("ExplosionRagdoll", {
                            Expires = workspace:GetServerTimeNow() + newExplosionProcessPacket.ExplosionStun;
                            Values = {
                                Ragdoll = true;
                            }
                        });
                    end

                else
                    damage = explodeHealthComp.MaxHealth * 0.05;
                end
                
            elseif explodeEntityClass.ClassName == "PlayerClass" then
                local playerClass: PlayerClass = explodeEntityClass :: PlayerClass;

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

            explodeHealthComp:TakeDamage(dmgData);

            task.spawn(function()
                if explodeEntityClass.ClassName == "PlayerClass" then
                    local player: Player = (explodeEntityClass :: PlayerClass):GetInstance();
                    shared.modPlayers.cameraShakeAndZoom(player, 10 * math.clamp(dist/32, 0, 1), 0, 0.5, 0.01, false);
                end
            end)

            return true;
        end

        modExplosionHandler:Process(explosionPoint, hitLayers, newExplosionProcessPacket);
    end)


    task.spawn(function()
        if isLethal == false then return; end;

        game.Debris:AddItem(npcClass.Character:FindFirstChild("ExplosiveTickBlobs"), 0);
        
        local explosionPoint = explosionPoint + Vector3.new(math.random(-20,20)/100, -0.5, math.random(-20,20)/100);
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

        npcClass:Kill();
    end)

end

return Component;