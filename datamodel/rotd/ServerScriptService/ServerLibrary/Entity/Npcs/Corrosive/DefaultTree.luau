local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local treePackage = {
    LogicString = {
        ChargeTree = "HasEnemy & CanCharge & [Charge]";
        Default = "ChargeTree | ZombieBossDefaultTree";
    };
};
--==


function treePackage.ZombieBossDefaultTree(npcClass: NpcClass)
    return npcClass.BehaviorTree:RunTree("ZombieBossDefaultTree", false);
end

function treePackage.HasEnemy(npcClass: NpcClass)
    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;
    return enemyTargetData ~= nil;
end



--MARK: ChargeTree
function treePackage.CanCharge(npcClass: NpcClass)
    local properties = npcClass.Properties;
    if properties.ChargeCooldown and tick() <= properties.ChargeCooldown then return false; end;
    
    return true;
end

function treePackage.Charge(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local isHard = properties.IsHard;

    properties.ChargeCooldown = tick()+15;
    npcClass.Move:Stop();

    Debugger:Warn(`{npcClass.Name} Charge`);
    task.wait(0.1);
    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    if isHard then
        npcClass.Move:Face(enemyNpcClass.RootPart, nil, 2);
        npcClass.PlayAnimation("ChargeBegin", nil, nil, 2);
        task.wait(2);
    else
        npcClass.Move:Face(enemyNpcClass.RootPart, nil, 1.5);
        npcClass.PlayAnimation("ChargeBegin");
        task.wait(3);
    end

    local targetPosition = enemyNpcClass.RootPart.Position + Vector3.new(0, 0.3, 0);
    local targetDir = (targetPosition-npcClass.RootPart.Position).Unit;
    targetPosition = targetPosition + targetDir * 6;

    local targetDistance = math.max(npcClass:DistanceFromCharacter(targetPosition), 16);
    local speed = isHard and 150 or 100;
    local duration = math.clamp(targetDistance/speed, 0.01, 3);

    npcClass.PlayAnimation("Charging");

    local targetNpcClasses = {};
    npcClass:GetComponent("TargetHandler"):MatchTargets(function(targetNpcClass: NpcClass)
        local targetHealthComp: HealthComp = targetNpcClass.HealthComp;
        if targetHealthComp == nil or targetHealthComp.IsDead then return end;

        local isTargettable = targetHealthComp:CanTakeDamageFrom(npcClass);
        if not isTargettable then return end;

        table.insert(targetNpcClasses, targetHealthComp.CompOwner);
    end)

    local hitNpcClassDebounce = {};

    npcClass.Move:MoveTo(targetPosition);
    npcClass.Move:Face(targetPosition);

    local throwTargetComp = npcClass:GetComponent("ThrowTarget");
    
    modAudio.Play("ChargeRoar", npcClass.RootPart);
    
    npcClass.Move:Fly({
        Velocity = targetDir * speed;
        Direction = targetDir;
    }, duration, function(index, trajPoint)
        task.spawn(function()
            while npcClass.Move.IsFlying do
                RunService.PostSimulation:Wait();
                for a=1, #targetNpcClasses do
                    local targetNpcClass: NpcClass = targetNpcClasses[a];
                    local targetRootPart = targetNpcClass.RootPart;

                    local distance = npcClass:DistanceFromCharacter(targetRootPart.Position);
                    local relativeCframe = npcClass.RootPart.CFrame:ToObjectSpace(targetRootPart.CFrame);
                    local absAngle = math.abs(math.deg(math.atan2(relativeCframe.X, -relativeCframe.Z)));

                    if absAngle <= 33 and distance <= 6 then
                        if hitNpcClassDebounce[targetNpcClass] then continue end;
                        hitNpcClassDebounce[targetNpcClass] = true;
                        throwTargetComp(targetNpcClass, 100, isHard and 40 or 20);
                    end
                end
            end
        end)
    end)
    table.clear(hitNpcClassDebounce);

    task.wait(1);
    npcClass.StopAnimation("Charging");
end

return treePackage;