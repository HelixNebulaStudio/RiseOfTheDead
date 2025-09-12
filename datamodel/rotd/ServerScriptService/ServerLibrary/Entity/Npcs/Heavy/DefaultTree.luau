local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");

local modArcTracing = shared.require(game.ReplicatedStorage.Library.ArcTracing);

local treePackage = {
    LogicString = {
        Default = "ThrowZombie | ZombieDefaultTree";
    };
    ThrowArcTracer = nil;
};

--==

function treePackage.onRequire()
	local arcTracer = modArcTracing.new();
	--arcTracer.DebugArc = true;
	arcTracer.RayRadius = 0.5;
	arcTracer.Acceleration = Vector3.new(0, -workspace.Gravity+90, 0);
	arcTracer.Delta = 1/7;

    treePackage.ThrowArcTracer = arcTracer;
end

function treePackage.ThrowZombie(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local properties = npcClass.Properties;

    if npcClass.Humanoid.FloorMaterial == Enum.Material.Air then return false; end;
    if enemyTargetData == nil then return false; end;
    
    local rightHand: BasePart? = npcClass.Character:FindFirstChild("RightHand") :: BasePart;
    if rightHand == nil or rightHand.AssemblyRootPart ~= npcClass.RootPart then
        return false;
    end;
    
    if properties.LastThrowZombie and tick()-properties.LastThrowZombie <= npcClass.Configurations.ThrowCooldown then 
        return false;
    end;
    properties.LastThrowZombie = tick();
    
    local targetCharacterClass: CharacterClass = enemyTargetData.HealthComp.CompOwner;
    local targetRootPart = targetCharacterClass.RootPart;

    local isInVision = npcClass:IsInVision(targetRootPart);
    if not isInVision then return false end;
    
    local maxRange = 16;
    local maxScan = 16;
    local rootPos = npcClass.RootPart.Position;
    local zombiesList: {NpcClass} = shared.modNpcs.listInRange(rootPos, maxRange, maxScan);
    
    local sortedNpcModules = {};
    for a=1, #zombiesList do
        local zNpcClass: NpcClass = zombiesList[a];

        local validNpcModule = zNpcClass ~= nil
            and zNpcClass ~= npcClass
            and not zNpcClass.HealthComp.IsDead
            and zNpcClass.Name == "Zombie"
            and zNpcClass.Properties.BasicEnemy == true
            and zNpcClass.Properties.SinisterImmunity ~= true;
        
        local healthRatio = zNpcClass.Humanoid.Health/zNpcClass.Humanoid.MaxHealth;

        if validNpcModule then
            local prefab = zNpcClass.Character;
            local prefabPosition = prefab:GetPivot().Position;

            local dist = (prefabPosition-rootPos).Magnitude;
            
            table.insert(sortedNpcModules, {
                NpcModule=zNpcClass;
                SortValue=((dist * 0.3) + math.clamp(1-healthRatio, 0, 1)*0.7);
            });
        end
    end
    table.sort(sortedNpcModules, function(a, b) return a.SortValue < b.SortValue; end);
    
    local throwNpcModule = sortedNpcModules[1] and sortedNpcModules[1].NpcModule or nil;
    table.clear(sortedNpcModules);

    local newGrip, stunStatus, throwDiedConn;
    
    local function cancel(force)
        local isCancelled = false;
        if npcClass.HealthComp.IsDead == true then
            isCancelled = true;
        end
        if throwNpcModule == nil 
            or throwNpcModule.Humanoid == nil 
            or throwNpcModule.Humanoid.Health <= 0 
            or throwNpcModule.IsDead 
        then
            isCancelled = true;
        end;
        if rightHand == nil or rightHand.AssemblyRootPart ~= npcClass.RootPart or not npcClass.Character:IsAncestorOf(rightHand) then
            isCancelled = true;
        end;
        
        if force == true or isCancelled then
            Debugger.Expire(newGrip, 0);
            
            if throwDiedConn then
                throwDiedConn:Disconnect();
            end
            if stunStatus then
                stunStatus.Expires=tick();
            end
            if npcClass.HealthComp.IsDead ~= true then
                npcClass.StopAnimation("ThrowCore");
                npcClass.Move:SetMoveSpeed("remove", "throw");
                npcClass.Move:Stop();
            end

            if throwNpcModule then
                if throwNpcModule.IsDead ~= true then
                    throwNpcModule.Humanoid.PlatformStand = false;
                    throwNpcModule.RootPart.Massless = false;
                end
            end
        end
        
        return isCancelled;
    end

    if cancel() then return false; end;

    throwDiedConn = throwNpcModule.Humanoid.Died:Connect(function()
        cancel(true);
    end)
    
    local stunDuration = 5;
    stunStatus = throwNpcModule.StatusComp:GetOrDefault("Stun", {
        Expires=tick()+stunDuration;
    });
    
    throwNpcModule.Move:Follow(npcClass.RootPart);
    npcClass.Move:Follow(throwNpcModule.RootPart);
    
    local reachDist = 5;
    for a=1, (4 *10) do
        local dist = (throwNpcModule.RootPart.Position-npcClass.RootPart.Position).Magnitude;
        if dist <= reachDist then
            break;
        else
            task.wait(0.1);
        end
        if cancel() then
            break;
        end
    end
    
    if cancel() then return false; end;
    
    local dist = (throwNpcModule.RootPart.Position-npcClass.RootPart.Position).Magnitude;
    if dist > reachDist then
        cancel(true);
        return false; 
    end;

    npcClass.Move:SetMoveSpeed("set", "throw", 0, 9);
    task.wait(0.3);
    if cancel() then return false; end;
    
    npcClass.PlayAnimation("Grab");
    task.wait(0.2);
    if cancel() then return false; end;
    
    npcClass.PlayAnimation("ThrowCore", 0.3);

    if not npcClass.HealthComp.IsDead then
        npcClass:SetNetworkOwner(nil);
    end
    if not npcClass.HealthComp.IsDead then
        throwNpcModule:SetNetworkOwner(nil);
    end
    
    throwNpcModule.RootPart.Massless = true;
    throwNpcModule.Humanoid.PlatformStand = true;

    newGrip = Instance.new("Motor6D");
    newGrip.C0 = CFrame.new(0.007, -0.769, -0.789) * CFrame.fromOrientation(38.921, -92.903, -93.362);
    newGrip.C1 = CFrame.new(0.401, 0, 0.266) * CFrame.fromOrientation(-0, -60, 0);

    throwNpcModule.Garbage:Tag(newGrip);
    npcClass.Garbage:Tag(newGrip);
    newGrip.Parent = rightHand;
    newGrip.Part0 = rightHand;
    newGrip.Part1 = throwNpcModule.RootPart;
    newGrip.Enabled = true;
    
    task.wait(0.3);
    if cancel() then return false; end;
    
    npcClass.Move:Face(targetRootPart, 32, 4);
    
    npcClass.PlayAnimation("Throw");
    task.wait(0.8);
    if cancel() then return false; end;
    
    local throwArcTracer = treePackage.ThrowArcTracer;

    throwArcTracer.RayWhitelist = CollectionService:GetTagged("PlayerCharacters");
    table.insert(throwArcTracer.RayWhitelist, workspace.Environment);

    local origin = npcClass.RootPart.Position;
    local targetPoint = targetRootPart.CFrame.Position + Vector3.new(0,5,0);

    local speed = 50;
    local duration = dist/speed;
    duration = math.clamp(duration, 0.5, 3);
    local velocity = throwArcTracer:GetVelocityByTime(origin, targetPoint, duration);

    local arcPoints = throwArcTracer:GeneratePath(origin, velocity, function(arcPoint)
        if (arcPoint.Point.Y-origin.Y) > 64 then return true end;

        if arcPoint.Hit == nil then return end
        
        return true;
    end);
    
    if #arcPoints > 1 then
        newGrip:Destroy();
        task.wait(0.1);

        throwNpcModule.RootPart.Massless = false;
        
        local downAng = CFrame.Angles(-math.pi/2, 0, 0);
        local lastVelocity: Vector3;
        throwNpcModule.Move:Fly(arcPoints, throwArcTracer.Delta, function(index, arcPoint)
            if index >= (#arcPoints-1) then return true; end;

            throwNpcModule.Humanoid.PlatformStand = true;
            arcPoint.AlignCFrame = arcPoint.AlignCFrame * downAng;
            stunStatus.Expires=tick()+0.2;
            lastVelocity = arcPoint.Velocity;

            return;
        end);

        throwNpcModule.SetAggression = 3;
        task.spawn(function()
            throwNpcModule.RootPart.Massless = false;
            if lastVelocity then
                throwNpcModule.RootPart:ApplyImpulse(lastVelocity);
            end
            
            task.wait(0.3);
            if throwNpcModule.IsDead then return end;
            
            throwNpcModule.Humanoid.PlatformStand = false;
            throwNpcModule.Move:Recompute();
        end)
    end
    
    task.wait(1);
    if cancel() then return false; end;
    npcClass.StopAnimation("ThrowCore");
    
    task.wait(1);
    if cancel() then return false; end;
    npcClass.Move:SetMoveSpeed("remove", "throw");
    
    cancel(true);

    return false;
end

function treePackage.ZombieDefaultTree(npcClass: NpcClass)
    return npcClass.BehaviorTree:RunTree("ZombieDefaultTree", false);
end

return treePackage;