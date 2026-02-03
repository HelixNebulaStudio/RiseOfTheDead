local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modArcParticles = shared.require(game.ReplicatedStorage.Particles.ArcParticles);
local modLaserParticle = shared.require(game.ReplicatedStorage.Particles.LaserParticle);

local treePackage = {
    LogicString = {
        HyperBeamTree = "HasEnemy & CanHyperBeam & [HyperBeam]";
        Default = "HyperBeamTree | ZombieBossDefaultTree";
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


--MARK: HyperBeam
function treePackage.CanHyperBeam(npcClass: NpcClass)
    local properties = npcClass.Properties;
    if properties.HyperBeamCooldown and tick()-properties.HyperBeamCooldown <= 15 then return false; end;
    return true
end

function treePackage.HyperBeam(npcClass: NpcClass)
    local properties = npcClass.Properties;
    properties.HyperBeamCooldown = tick();

    local isHard = properties.HardMode;

    npcClass.Move:SetMoveSpeed("set", "hyperbeamstop", 0, 9, 5);

    local chargeUpPeriod = 2;
    npcClass.PlayAnimation("HyperBeam", chargeUpPeriod);
    
    local energyBall = properties.EnergyBall;
    energyBall.Transparency = 0.3;

    local energyLight = properties.EnergyLight;
    energyLight.Enabled = true;

    local flashTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 6, true);
    TweenService:Create(energyBall, flashTweenInfo, {
        Color = Color3.fromRGB(160, 0, 0);
        Transparency = 0.5;
    }):Play();

    local chargeUpTweenInfo = TweenInfo.new(chargeUpPeriod);
    TweenService:Create(energyBall, chargeUpTweenInfo, {
        Size = Vector3.new(1.6, 1.6, 1.6);
    }):Play();
    TweenService:Create(energyLight, chargeUpTweenInfo, {
        Brightness = 1;
    }):Play();

    local leftHand = npcClass.Character:WaitForChild("LeftHand");
    modAudio.Play("BeamChargeUp", leftHand);

    local hyperbeam = game.ServerStorage.Prefabs.Objects:WaitForChild("Hyperbeam"):Clone();
    hyperbeam.Size = Vector3.new(0, 0, 0);
    hyperbeam.Parent = workspace.Debris;
    Debugger.Expire(hyperbeam, 5);

    task.wait(1);
    if npcClass.HealthComp.IsDead then return end

    local att1 = Instance.new("Attachment");
    att1.Name = "Att1";
    att1.Parent = hyperbeam;
    local att2 = Instance.new("Attachment");
    att2.Name = "Att2";
    att2.Parent = hyperbeam;
    att1.Position = Vector3.new(0, 1, 0);
    att2.Position = Vector3.new(0, -1, 0);

    modArcParticles.broadcast(att1, att2, {
        Color = Color3.fromRGB(255, 0, 4);
        Color2 = Color3.fromRGB(8, 0, 255);
        Amount = 3;
        Thickness = 0.2;
    });

    modAudio.Play("BeamChargeLoop", hyperbeam);

    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;
    local enemyRootPart = enemyNpcClass.RootPart;

    local targetingPos = enemyRootPart.Position;
    local aimLockingTick = tick();

    local lockedPos;

    local lockonActive = true;
    task.spawn(function()
        while lockonActive do
            targetingPos = enemyRootPart.Position;

            local pos = targetingPos;
            if lockedPos then
                pos = lockedPos;
            end

            local beamPivot = (pos + leftHand.Position)/2;
            local beamDir = (pos - leftHand.Position).Unit;
            local beamMag = math.clamp((pos - leftHand.Position).Magnitude, 4, 64);
            
            npcClass.Move:Face(pos);

            local a = (math.clamp(tick()-aimLockingTick, 0, chargeUpPeriod)/chargeUpPeriod);

            local size = 1 * a;
            hyperbeam.Size = Vector3.new(size, beamMag, size);
            hyperbeam.CFrame = CFrame.lookAlong(beamPivot, beamDir) * CFrame.Angles(math.pi/2, 0, 0);

            att1.Position = Vector3.new(0, beamMag/2, 0);
            att2.Position = Vector3.new(0, -beamMag/2, 0);

            RunService.Heartbeat:Wait();
            if npcClass.HealthComp.IsDead then return end
        end
    end)

    task.wait(chargeUpPeriod);
    if npcClass.HealthComp.IsDead then return end

    local aimLockTweenInfo = TweenInfo.new(0.2);
    TweenService:Create(hyperbeam, aimLockTweenInfo, {
        Size = Vector3.new(0, hyperbeam.Size.Y, 0);
    }):Play();

    lockedPos = targetingPos;

    task.wait(0.2);
    if npcClass.HealthComp.IsDead then return end

    hyperbeam:Destroy();
    energyBall.Transparency = 1;
    energyBall.Size = Vector3.zero;
    energyLight.Enabled = false;
    
    npcClass.StopAnimation("HyperBeam");
    lockonActive = false;

    npcClass:GetComponent("ArcExplosion")(lockedPos, properties.ExplosionDamage, properties.ExplosionRange);
end

return treePackage;