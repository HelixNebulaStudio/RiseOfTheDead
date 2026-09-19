local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);
local modParticleSprinkler = shared.require(game.ReplicatedStorage.Particles.ParticleSprinkler);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modMath = shared.require(game.ReplicatedStorage.Library.Util.Math);
local modHealthComponent = shared.require(game.ReplicatedStorage.Components.HealthComponent);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local treePackage = {
    LogicString = {
        RebarSlamTree = "HasEnemy & CanSlam & [RebarSlam]";
        RebarTornadoTree = "HasEnemy & CanTornado & [RebarTornado]";
        SwingRebarTree = "HasEnemy & CanSwingRebar & [SwingRebar]";
        Default = "RebarSlamTree | RebarTornadoTree | SwingRebarTree | ZombieBossDefaultTree";
    };
};

function treePackage.ZombieBossDefaultTree(npcClass: NpcClass)
    return npcClass.BehaviorTree:RunTree("ZombieBossDefaultTree", false);
end

function treePackage.HasEnemy(npcClass: NpcClass)
    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;
    return enemyTargetData ~= nil;
end



--MARK: RebarSlamTree
function treePackage.CanSlam(npcClass: NpcClass)
    local properties = npcClass.Properties;
    if properties.NextAction ~= "RebarSlam" then return false; end;
    return tick() > properties.RebarSlamCooldown;
end

function treePackage.RebarSlam(npcClass: NpcClass)
    local properties = npcClass.Properties;
    properties.RebarSlamCooldown = tick()+10;

    Debugger:Warn(`{npcClass.Name} RebarSlam`);
    npcClass.Move:Stop();
    task.wait(0.5);
    if npcClass.HealthComp.IsDead then return end;

    local toolHandler: ToolHandlerInstance? = npcClass.WieldComp.ToolHandler;
    if npcClass.WieldComp.ItemId ~= "tankerrebar" or toolHandler == nil then return end;
    if toolHandler.MainToolModel == nil then return end;

    local handle = toolHandler.MainToolModel.PrimaryPart;
    local impactPointAtt = handle.ImpactPoint;
    local impactOrigin = Vector3.new(impactPointAtt.WorldPosition.X, npcClass.RootPart.Position.Y, impactPointAtt.WorldPosition.Z);
    
    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    npcClass.Move:Face(enemyNpcClass.RootPart);

    toolHandler.ToolAnimator:Play("SlamAttack");

    task.delay(0.9, function()
        if npcClass.HealthComp.IsDead then return end;
            
        local raycastPreset = RaycastParams.new();
        raycastPreset.FilterType = Enum.RaycastFilterType.Include;
        raycastPreset.CollisionGroup = "Raycast";
        raycastPreset.FilterDescendantsInstances = {workspace.Environment; workspace.Terrain};
        
        local rootPart = npcClass.RootPart;
        local dir = rootPart.CFrame.LookVector * Vector3.new(1, 0, 1);
        
        local fencePrefab = script.Parent:WaitForChild("barbedFence");

        local slamOrigin = impactOrigin + dir*3.5;
        local origin = slamOrigin;
        
        local wallLength = 10;
        for a=1, wallLength do

            local wallRayResult = workspace:Raycast(origin, dir*3.459, raycastPreset);
            local floorRayResult = workspace:Raycast(origin, -Vector3.yAxis*4, raycastPreset);
            
            if floorRayResult then
                local rayPos, _rayNorm = floorRayResult.Position, floorRayResult.Normal;

                local particlePacket = {
                    Type=1;
                    Origin=CFrame.new(rayPos);
                    SpreadRange={Min=-0.5; Max=0.5};
                    Velocity=Vector3.new(0, 1, 0);
                    SizeRange={Min=0.3; Max=0.6};
                    Material=Enum.Material.Slate;
                    DespawnTime=3;
                    Speed=30;
                    Color = Color3.fromRGB(65, 46, 33);

                    MinSpawnCount=3;
                    MaxSpawnCount=4;
                };
                modParticleSprinkler:Emit(particlePacket);
                
                local newPrefab: Model = fencePrefab:Clone();
                newPrefab:PivotTo(CFrame.lookAt(rayPos, rayPos + dir) * CFrame.Angles(0, math.rad(90), 0))
                newPrefab.Parent = workspace.Environment;

                local destructibleConfig = modDestructibles.createDestructible();
                destructibleConfig:SetAttribute("DebrisName", "TankerBarbedFence");
                destructibleConfig.Parent = newPrefab;
                
                local fencePart = newPrefab:WaitForChild("Fence") :: BasePart;
                fencePart.CollisionGroup = "PlayerClips";

                local destructible: DestructibleInstance = modDestructibles.getOrNew(destructibleConfig);

                local onFenceTouch;
                onFenceTouch = function(hitPart)
                    if destructible.HealthComp.IsDead then return end;

                    if hitPart.Parent == npcClass.Character then
                        destructible.HealthComp:SetIsDead(true);
                    end;
                    task.wait(0.2);
                    if destructible.HealthComp.IsDead then return end;

                    fencePart.Touched:Once(onFenceTouch);
                end

                local delayTouchActivation = properties.HardMode and 35 or 20;
                if RunService:IsStudio() then delayTouchActivation = 5; end;
                task.delay(delayTouchActivation, function()
                    fencePart.Touched:Once(onFenceTouch);
                end)
                npcClass.Garbage:Tag(newPrefab);
                
            else
                break;
            end

            if wallRayResult then
                break;
            end
            
            origin = origin + dir*3.459;
            task.wait(0.1);
        end
        
    end)
    task.delay(0.8, function()
        if npcClass.HealthComp.IsDead then return end;

        modAudio.Play("Explosion4", npcClass.RootPart).TimePosition = 1;

        local targetDataList: {NpcTargetData} = npcClass:GetComponent("TargetHandler"):MatchTargets(function(targetData)
            if targetData.HealthComp == nil then return end;
            local targetNpcClass: NpcClass = targetData.HealthComp.CompOwner;

            if targetNpcClass.HealthComp.IsDead then
                return false;
            end;

            local canDamage = targetNpcClass.HealthComp:CanTakeDamageFrom(npcClass);
            if not canDamage then
                return false;
            end

            return true;
        end)

        for a=1, #targetDataList do
            local targetNpcClass: CharacterClass = targetDataList[a].HealthComp.CompOwner;

            local enemyChar: Model = targetNpcClass.Character;
            local enemyPivot = enemyChar:GetPivot();
            
            local displace = (enemyPivot.Position-impactPointAtt.WorldPosition);
            local dist = Vector3.new(displace.X, displace.Y*4, displace.Z).Magnitude;
            
            local isHard = properties.HardMode;
            local damageRange = (isHard and 32 or 12);
            local dmgScaling = modMath.MapNum(math.clamp(dist, 0, damageRange), 
                0, (isHard and 32 or 24), 
                (isHard and 200 or 45), (isHard and 95 or 25)
            );
            
            if dist > damageRange then continue end;
            
            if dmgScaling > (isHard and 95 or 25) then
                local throwTargetComp = npcClass:GetComponent("ThrowTarget");
                throwTargetComp(enemyTargetData.HealthComp.CompOwner, 100, isHard and 28 or 40);

                targetNpcClass.HealthComp:TakeDamage(DamageData.new{
                    Damage = isHard and 200 or 45;
                    DamageCate = DamageData.DamageCategory.Melee;
                });
            end
        end

    end)
    
    task.wait(5);
    properties.NextAction = "RebarTornado";
end



--MARK: RebarTornadoTree
function treePackage.CanTornado(npcClass: NpcClass)
    local properties = npcClass.Properties;
    if properties.NextAction ~= "RebarTornado" then return false; end;
    return tick() > properties.RebarSpinCooldown;
end

function treePackage.RebarTornado(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local isHard = properties.HardMode;
    properties.RebarSpinCooldown = tick()+20;

    Debugger:Warn(`{npcClass.Name} RebarTornado`);
    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;
    local enemyCharComp: CharacterClass = enemyTargetData.HealthComp.CompOwner;

    npcClass.Move:Follow(enemyCharComp.RootPart, 0.5);
		
    local toolHandler: ToolHandlerInstance? = npcClass.WieldComp.ToolHandler;
    if toolHandler == nil then return end;

    toolHandler.ToolAnimator:Play("SpinAttack");
    local spinDuration = isHard and math.random(9, 10) or 4;
    
    npcClass.Move:SetMoveSpeed("set", "spinsprint", isHard and 26 or 22, 5, spinDuration);

    local toolModel = toolHandler.MainToolModel;
    if not toolModel then return end;

    local collider = toolModel.Collider;

    if collider:GetAttribute("CollideConn") == nil then
        collider:SetAttribute("CollideConn", true);
        
        local hitDebounce = {};
        npcClass.Garbage:Tag(hitDebounce);

        local attackSpeed = 0.5; -- Default attack speed
        collider.Touched:Connect(function(hitPart)
            if not properties.IsRebarTornadoing then return end;
            local enemyPrefab = hitPart.Parent;
            if not enemyPrefab:IsA("Model") then return end;
            
            local enemyHealthComp: HealthComp? = modHealthComponent.getByModel(enemyPrefab);
            if enemyHealthComp and enemyHealthComp.CurHealth > 0 then
                
                if hitDebounce[enemyPrefab] == nil or (tick()-hitDebounce[enemyPrefab]) > attackSpeed then
                    hitDebounce[enemyPrefab] = tick();
                    
                    -- Damage the target using proper damage data
                    local dmgData = DamageData.new{
                        Damage = isHard and 50 or 25;
                        DamageBy = npcClass;
                        DamageCategory = DamageData.DamageCategory.Melee;
                    };
                    enemyHealthComp:TakeDamage(dmgData);
                    
                    modAudio.Play(math.random(1, 2) == 1 and "BulletBodyImpact" or "BulletBodyImpact2", collider);

                    if enemyHealthComp.CompOwner.ClassName == "PlayerClass" then
                        local playerClass: PlayerClass = enemyHealthComp.CompOwner :: PlayerClass;
                        local player: Player = playerClass:GetInstance();
                        
						shared.modPlayers.cameraShakeAndZoom(player, 10, 5, 0.5, 0.01, true);

                        if isHard then
                            modStatusEffects.Slowness(player, 5, 0.5);
                        end
                    end
                end
                
            end
        end)
    end
    
    
    local trackData = toolHandler.ToolAnimator:GetTrackData("SpinAttack");
    trackData.CustomSpeed = true;
    
    local track: AnimationTrack = trackData.Track;
    
    if track:GetAttribute("LoopConn") == nil then
        track:SetAttribute("LoopConn", true);
        
        local _d=0.4167;
        local isSpinning = false;
        track:GetMarkerReachedSignal("Event"):Connect(function(paramString)
            if paramString == "SpinStart" then
                if isSpinning then return end;
                isSpinning = true;
                
                properties.IsRebarTornadoing = true;
                local totalA = spinDuration * 10;
                
                local speedStep = (15-10)/totalA;
                local currSpeed = 10
                
                for a=1, totalA do
                    properties.IsRebarTornadoing = true;
                    npcClass.Move:Face(npcClass:GetCFrame().Position - npcClass:GetCFrame().RightVector*64, currSpeed);
                    task.wait(0.1);

                    if npcClass.HealthComp.IsDead then break; end;
                    currSpeed = currSpeed + speedStep;
                end

                properties.IsRebarTornadoing = false;
                track:AdjustSpeed(1);
                isSpinning = false;
            
            elseif paramString == "SpinEnd" then
                track:AdjustSpeed(0);
                
            end

        end)
    end
    
    task.wait(spinDuration+1);

    properties.NextAction = "RebarSlam";
end


--MARK: SwingRebarTree
function treePackage.CanSwingRebar(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;

    if properties.PrimaryAttackCooldown and tick() < properties.PrimaryAttackCooldown then
        return false;
    end;

    return enemyTargetData.Distance <= 10;
end

function treePackage.SwingRebar(npcClass: NpcClass)
    local properties = npcClass.Properties;
    properties.PrimaryAttackCooldown = tick() + math.random(90, 110)/100;

    local wieldComp: WieldComp = npcClass.WieldComp;
    
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    npcClass.Move:HeadTrack(enemyNpcClass.RootPart, 2);

    wieldComp:InvokeToolAction("PrimarySwingRequest");
end

return treePackage;