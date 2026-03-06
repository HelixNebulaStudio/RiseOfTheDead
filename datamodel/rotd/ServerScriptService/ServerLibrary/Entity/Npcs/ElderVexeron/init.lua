local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService")

local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modParticleSprinkler = shared.require(game.ReplicatedStorage.Particles.ParticleSprinkler);
local modMath = shared.require(game.ReplicatedStorage.Library.Util.Math);
local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local npcPackage = {
    Name = "ElderVexeron";
    HumanoidType = "Zombie";
    
	Configurations = {
        MaxHealth = 100;
    };
    
    Properties = {
        BasicEnemy = false;
        IsHostile = true;
        Immortal = 1;

        TargetableDistance = 1024;
        LockOnExpireDuration = NumberRange.new(100, 120);

        Level = 1;
        ExperiencePool = 1000;
        MoneyReward = NumberRange.new(2000, 3500);

        ContactDamage = 10;
        SpeedRatio = 1;

        KnockbackResistant = 1;
    };

    Audio = {};

    AddComponents = {
        "DropReward";
        "TargetHandler";
        "BodyDestructibles";
    };
    AddBehaviorTrees = {
        "HasEnemy";
    };

    TouchHandler = nil;
    ThinkCycle = 1;
};
--==

function npcPackage.Spawning(npcClass: NpcClass)
    local character = npcClass.Character;
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;
    local healthComp: HealthComp = npcClass.HealthComp;

    properties.SpitterKilled = 0;
    properties.SnoozeTimer = tick();

    local isHard = properties.HardMode;
    local level = math.max(properties.Level, 0);

    local bodyVelocity = Instance.new("BodyVelocity");
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge);
    bodyVelocity.Velocity = Vector3.new(0, 0, 0);
    bodyVelocity:SetAttribute("Speed", 10); --MARK: Move Speed
    bodyVelocity.P = 1000;
    bodyVelocity.Parent = npcClass.RootPart;
    properties.BodyVelocity = bodyVelocity;
		
    local bodyGyro = Instance.new("BodyGyro");
	bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge);
	bodyGyro.P = 40000;
	bodyGyro.Parent = npcClass.RootPart;
	properties.BodyGyro = bodyGyro;	

    npcClass.Humanoid.PlatformStand = true;
    npcClass.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false);
    npcClass.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true);
    npcClass.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true);

    npcClass.RootPart.RootPriority = 1;

    local twistAngleLimit = 65;
	local vexBodyPrefab = character:WaitForChild("Vexeworm");

    configurations.BaseValues.MaxHealth = 9_999_999;
    properties.VexeronLength = 8;
    properties.ContactDamage = 10;

    local bodyWeights = {};
    local ballConstraints = {};
    local vexBodies = {};

    local prevLowerLink = vexBodyPrefab:WaitForChild("LowerLink");
    for a=1, properties.VexeronLength do
        local new = vexBodyPrefab:Clone();
        new.Name = new.Name..a;
    
        new.Size = vexBodyPrefab.Size * 4;
        local nULink = new:WaitForChild("UpperLink");
        local nLLink = new:WaitForChild("LowerLink");
        nULink.Position = Vector3.new(0, 20, 0);
        nLLink.Position = Vector3.new(0, -20, 0);

        local constraint = Instance.new("BallSocketConstraint");
        constraint.Attachment0 = new:WaitForChild("UpperLink");
        constraint.Attachment1 = prevLowerLink;
        constraint.TwistLimitsEnabled = true;
        constraint.UpperAngle = twistAngleLimit;
        constraint.TwistLowerAngle = -twistAngleLimit;
        constraint.TwistUpperAngle = twistAngleLimit;
        constraint.Parent = new;
        prevLowerLink = new:WaitForChild("LowerLink");

        table.insert(ballConstraints, constraint);
        
        local newBodyVelocity = Instance.new("BodyVelocity");
        newBodyVelocity.Name = "Weight";
        local force = 250_000_000;
        newBodyVelocity.MaxForce = Vector3.new(force, force, force);
        newBodyVelocity.Velocity = Vector3.new(0, 0, 0);
        newBodyVelocity.P = 1500;
        newBodyVelocity.Parent = new;
        
        table.insert(bodyWeights, newBodyVelocity);
        table.insert(vexBodies, new);
        
        new.Parent = character;
    end
    npcClass.Garbage:Tag(function()
        table.clear(vexBodies);
    end)
    properties.VexBodies = vexBodies;


    local vexeronRemote = Instance.new("RemoteEvent");
    vexeronRemote.Name = "VexeronRemote";
    vexeronRemote.Parent = character;

    npcClass.Garbage:Tag(vexeronRemote.OnServerEvent:Connect(function(player: Player, vexBodyPart: BasePart)
        local playerClass: PlayerClass = shared.modPlayers.get(player);
        local hitCharacter = playerClass.Character;
        if hitCharacter == nil or playerClass.HealthComp.IsDead then return end;
        if vexBodyPart == nil or not vexBodyPart:IsDescendantOf(character) then return end;
        if not playerClass.HealthComp:CanTakeDamageFrom(npcClass) then return end;

        local vexeronHitDebounce = playerClass.Properties.VexeronHitDebounceTick;
        if vexeronHitDebounce and tick() <= vexeronHitDebounce then return end;

        playerClass.Properties.VexeronHitDebounceTick = tick() + 0.3;

        playerClass.HealthComp:TakeDamage(DamageData.new{
            Damage = properties.ContactDamage;
            DamageBy = npcClass;
        });

        if isHard then
            modStatusEffects.Knockback(player, vexBodyPart, 50);
        end
    end))

    function properties.UpdateVelocity()
        bodyVelocity.Velocity = bodyGyro.CFrame.UpVector * bodyVelocity:GetAttribute("Speed");

        for a=1, #bodyWeights do
            if bodyWeights[a].Parent == nil then continue end;
            
            bodyWeights[a].Velocity = bodyWeights[a].Parent.CFrame.UpVector * bodyVelocity:GetAttribute("Speed");
        end
    end

    bodyVelocity:GetPropertyChangedSignal("P"):Connect(properties.UpdateVelocity);
    bodyGyro:GetPropertyChangedSignal("CFrame"):Connect(properties.UpdateVelocity);
    npcClass.Garbage:Tag(bodyVelocity);
    npcClass.Garbage:Tag(bodyGyro);

    for _, v in next, character:GetDescendants() do
        if not v:IsA("BasePart") then continue end;
        v.CollisionGroup = "CollisionOff";
    end

    npcClass.Garbage:Tag(function()
		modAudio.Play("VexeronGrowl", properties.DeathPosition);

        for a=1, #ballConstraints do
            game.Debris:AddItem(ballConstraints[a], 0);
        end
        table.clear(ballConstraints);

        for a=1, #bodyWeights do
            local parentPart = bodyWeights[a].Parent;
            if parentPart:IsA("BasePart") then
                parentPart.CollisionGroup = "Debris";
                parentPart.CanCollide = true;
            end
            game.Debris:AddItem(bodyWeights[a], 0);
        end
        table.clear(bodyWeights);
    end)

    properties.State = "Hunt";
    properties.StageChangedTick = tick();
end

function npcPackage.Spawned(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local healthComp = npcClass.HealthComp;
    local rootPart = npcClass.RootPart;
    local character = npcClass.Character;

    local isHard = properties.HardMode;
    local bodyVelocity = properties.BodyVelocity;
    local bodyGyro = properties.BodyGyro;


    local bodyDestructiblesComp = npcClass:GetComponent("BodyDestructibles");

    function properties.PointTo(point: Vector3, lerpIntensity: number?)
		local newFrontCf = CFrame.new(rootPart.Position, point) * CFrame.Angles(-math.pi/2, 0, 0);
		
		bodyGyro.CFrame = bodyGyro.CFrame:Lerp(newFrontCf, math.clamp(lerpIntensity or 0.01, 0.01, 1));
	end

    local bodyParts = npcClass.Character:GetChildren();
    for a=1, #bodyParts do
        local bodyPart: BasePart = bodyParts[a];
        if not bodyParts[a]:IsA("BasePart") then continue end;

        bodyPart:SetNetworkOwner(nil);
    end
    
    local spawnPoint = npcClass.SpawnCFrame;
    task.spawn(function() 
        while not healthComp.IsDead do
            local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;
            local enemyPosition = enemyTargetData and enemyTargetData.HealthComp.CompOwner.RootPart.Position or spawnPoint.Position;

            local curTick = tick();
            local t = curTick/8;

            local targetPoint;
            if enemyTargetData == nil or properties.State == "Idle" then
                local spinVec = Vector3.new(math.sin(t), 0, math.cos(t));
                targetPoint = spawnPoint.Position + (spinVec * 80);

            elseif properties.State == "Snooze" then
                targetPoint = Vector3.new(0, -100, 0);

            elseif properties.State == "Hunt" then
                local enemyDistance = enemyTargetData.Distance;

                local spinVec = Vector3.new(math.sin(t), 0, math.cos(t));
                local lapseRatio = math.clamp(tick()-properties.StageChangedTick, 0, 16)/16;

                local newPos = enemyPosition + (spinVec * ((lapseRatio*80) + 50));
                newPos = newPos+ Vector3.new(0, -math.clamp(enemyDistance/4, 0, 25), 0);
                targetPoint = newPos;
                
            end

            if targetPoint then
                local dist = npcClass:DistanceFromCharacter(targetPoint);
                local lerpIntensity = modMath.MapNum(dist, 0, 400, 0, 1, true);
                properties.PointTo(targetPoint, lerpIntensity);
            end

            task.wait();
        end
    end)

    local targetHandlerComp = npcClass:GetComponent("TargetHandler");
    
    properties.ActiveVexSpitters = {};
    properties.SpawnSpitterCooldown = tick() + 4;
    
    properties.OnChanged:Connect(function(k, v, ov) 
        if k == "State" and v == "Snooze" then
            for _, model in ipairs(properties.ActiveVexSpitters) do
                if model == nil then continue end;
                model:Destroy();
            end
        end
    end)

    npcClass.OnThink:Connect(function()
        local curTick = tick();

        if curTick < properties.SpawnSpitterCooldown then return end;
        properties.SpawnSpitterCooldown = curTick + 2;

        if properties.State == "Snooze" then return end;

        local activeVexSpitters = properties.ActiveVexSpitters;
        if #activeVexSpitters >= 5 then return end;

        local vexBody: BasePart = properties.VexBodies[math.random(1, #properties.VexBodies)];

        local rngDir = modVector.RandomUnitVector(2);

        local vexSpitterNpcClass: NpcClass = shared.modNpcs.spawn2{
            Name = "Vex Spitter";
            CFrame = CFrame.new(vexBody.Position);
            BindPreSetup = function(npcClass: NpcClass)
                npcClass.Properties.SpawnPointSet = true;
            end;
        };
        table.insert(activeVexSpitters, vexSpitterNpcClass.Character);
        vexSpitterNpcClass.Character:ScaleTo(2.5);

        local weld = Instance.new("Motor6D");
        vexSpitterNpcClass.HealthComp.OnIsDeadChanged:Connect(function(isDead)
            if not isDead then return end;
            if npcClass.HealthComp.IsDead then return end;

            for a=#activeVexSpitters, 1, -1 do
                if activeVexSpitters[a] == vexSpitterNpcClass.Character then
                    table.remove(activeVexSpitters, a);
                    if properties.State ~= "Snooze" then
                        properties.SpitterKilled += 1;
                    end
                    break;
                end
            end

            weld:Destroy();
        end)

        local vexSpitterTargetHandlerComp = vexSpitterNpcClass:GetComponent("TargetHandler");
        targetHandlerComp.OnTargetUpdate:Connect(function(character)
            vexSpitterTargetHandlerComp:AddTarget(character, nil);
        end)

        weld.Parent = vexSpitterNpcClass.RootPart;
        weld.Part0 = vexSpitterNpcClass.RootPart;
        weld.Part1 = vexBody;
        weld.C0 = CFrame.new(0, -15, 0) * CFrame.Angles(math.rad(90), math.rad(math.random(1, 360)), 0);

        vexSpitterNpcClass:SetNetworkOwner(nil);
    end)
end

return npcPackage;