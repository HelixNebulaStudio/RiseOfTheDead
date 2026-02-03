local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");

local modArcTracing = shared.require(game.ReplicatedStorage.Library.ArcTracing);

local treePackage = {
    LogicString = {
        Default = "Leap | ZombieDefaultTree";
    };
    LeapArcTracer = nil;
};

--==

function treePackage.onRequire()
	local arcTracer = modArcTracing.new();
	--arcTracer.DebugArc = true;
	arcTracer.RayWhitelist = {workspace.Terrain; workspace.Environment; workspace.Clips};
	arcTracer.RayRadius = 1.5;
	arcTracer.Acceleration = Vector3.new(0, -workspace.Gravity, 0);
	arcTracer.Delta = 1/7;

    treePackage.LeapArcTracer = arcTracer;
end

function treePackage.Leap(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local properties = npcClass.Properties;

    if properties.IsMoving == false then return false; end;
    if enemyTargetData == nil then return false; end;
    if npcClass.Humanoid.FloorMaterial == Enum.Material.Air then return false; end;
    
    local dist = enemyTargetData.Distance;
    if dist < 16 then return false; end;

    local leapArcTracer = treePackage.LeapArcTracer;
    leapArcTracer.RayWhitelist = CollectionService:GetTagged("PlayerCharacters");
    table.insert(leapArcTracer.RayWhitelist, workspace.Environment);

    local enemyHealthComp: HealthComp = enemyTargetData.HealthComp;
    local enemyNpcClass: NpcClass = enemyHealthComp.CompOwner;

    local targetRootPart = enemyNpcClass.Humanoid.RootPart;

    local tarVec = targetRootPart.AssemblyLinearVelocity;
    local origin = npcClass.RootPart.Position;
    local targetPoint = targetRootPart.CFrame.Position 
                        + tarVec
                        + Vector3.new(0,5,0) 
                        + Vector3.new(math.clamp(tarVec.X,-30,30), 0, math.clamp(tarVec.Z,-30,30));
    
    local speed = 100;
    local duration = math.clamp(dist/speed, 0.4, 1.6);
    local velocity = leapArcTracer:GetVelocityByTime(origin, targetPoint, duration);
        
    local angle = Vector3.yAxis:Angle(velocity);
    if angle >= 1.3 or angle <= 0.1 then return false; end;
    
    local velMagnitude = velocity.Magnitude;
    if velMagnitude > 200 then return false; end;
    
    local leapCooldown = npcClass.Configurations.LeapCooldownDuration;

    if properties.LeapTryCounter and properties.LeapTryCounter > 2 then
        leapCooldown = leapCooldown + properties.LeapTryCounter;
    end

    if properties.LastLeap and tick() - properties.LastLeap < leapCooldown then return false; end;
    properties.LastLeap = tick();
    properties.LeapTryCounter = (properties.LeapTryCounter or 0) + 1;

    npcClass.Move:SetMoveSpeed("set", "leap", 0, npcClass.Move.MoveSpeedPriority.Action);

    local downAng = CFrame.Angles(-math.pi/2, 0, 0);

    local hitPart, _hitPos;
    local arcPoints = leapArcTracer:GeneratePath(origin, velocity, function(arcPoint)
        if (arcPoint.Point.Y-origin.Y) > 32 then return true end;
        
        if arcPoint.Hit == nil then return end
        hitPart = arcPoint.Hit;
        _hitPos = hitPart.Position;
        
        return true;
    end);
    
    if #arcPoints > 0 then
        npcClass.PlayAnimation("LeapStart");

        task.wait(0.3);
        if npcClass.HealthComp.IsDead then return false; end;

        properties.LeapTryCounter = 0;
        npcClass.PlayAnimation("Leap", 0);
        
        npcClass.Move:Fly(arcPoints, leapArcTracer.Delta, function(index, arcPoint)
            if index >= (#arcPoints-1) then return true; end;

            npcClass.Humanoid.PlatformStand = true;
            arcPoint.AlignCFrame = arcPoint.AlignCFrame * downAng;
            properties.LastLeap = tick();

            return;
        end);
        npcClass.Humanoid.PlatformStand = false;
    end
    
    if npcClass.HealthComp.IsDead then return false; end;
    npcClass.StopAnimation("Leap");
    npcClass.Move:Recompute();
    
    npcClass.Move:SetMoveSpeed("remove", "leap");
    npcClass.Humanoid.PlatformStand = false;

    return false;
end

function treePackage.ZombieDefaultTree(npcClass: NpcClass)
    return npcClass.BehaviorTree:RunTree("ZombieDefaultTree", false);
end

return treePackage;