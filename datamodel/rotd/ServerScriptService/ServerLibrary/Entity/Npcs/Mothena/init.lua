local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modMath = shared.require(game.ReplicatedStorage.Library.Util.Math);

local npcPackage = {
    Name = "Mothena";
    HumanoidType = "Zombie";
    
	Configurations = {
        MaxHealth = 100;
    };
    Properties = {
        BasicEnemy = false;
        IsHostile = true;

        TargetableDistance = 256;

        Level = 1;
        ExperiencePool = 1000;
        MoneyReward = NumberRange.new(4800, 5200);

        KnockbackResistant = 1;
        SkipMoveInit = true;

        MovementFrequency = 50;
        AltReduction = 0;
    };

    AddComponents = {
        "TargetHandler";
        "BodyDestructibles";
    };
    AddBehaviorTrees = {
        "HasEnemy";
    };
    
    ThinkCycle = 0.5;
};


function npcPackage.Spawning(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<anydict> = npcClass.Properties;
    local rootPart = npcClass.RootPart;

    local isHard = properties.HardMode;
    local level = math.max(properties.Level, 0);

    if properties.HardMode then
        configurations.BaseValues.MaxHealth = math.max(500000 + 10000*level, 100);
        configurations.BaseValues.AttackDamage = 10;
    else
        configurations.BaseValues.MaxHealth = math.max(20000 + 4000*level, 100);
        configurations.BaseValues.AttackDamage = 5;
    end

    if not isHard then
        for _, obj in pairs(npcClass.Character:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Material == Enum.Material.Foil then
                obj.Material = Enum.Material.Sand;
                obj.Color = Color3.fromRGB(214, 82, 82);
            end
        end
    end

    npcClass.Garbage:Tag(rootPart:WaitForChild("BodyPosition"));
    npcClass.Garbage:Tag(rootPart:WaitForChild("BodyGyro"));

    local poisonIvyModel = Instance.new("Model");
    poisonIvyModel.Name = `PoisonIvyModel`;
    poisonIvyModel.Parent = npcClass.Character;
    properties.PoisonIvyModel = poisonIvyModel;

    properties.FacePoint = npcClass.SpawnCFrame.Position;
    properties.HoverPoint = properties.FacePoint + Vector3.new(0, 32, 0);
    properties.MoveState = "Follow";
    properties.MoveStateChangedTick = tick();
end

function npcPackage.Spawned(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties = npcClass.Properties;
    local npcChar = npcClass.Character;
    local rootPart = npcClass.RootPart;
    local isHard = properties.HardMode;

    local bodyDestructiblesComp = npcClass:GetComponent("BodyDestructibles");

    local wingModels = {"LeftWing"; "RightWing"};
    for a=1, #wingModels do
        local wingModel: Model = npcClass.Character:WaitForChild(wingModels[a]) :: Model;
        local primaryPart = wingModel.PrimaryPart;

        local destructible: DestructibleInstance = bodyDestructiblesComp:Create(wingModel.Name, wingModel);
        destructible.Properties.DestroyModel = false;
        local newHealth = configurations.MaxHealth * (isHard and 0.25 or 0.15);

        local limbHealthComp: HealthComp = destructible.HealthComp;
        
        destructible:SetupHealthbar{
            Size = UDim2.new(2, 0, 0.5, 0);
            Distance = 128;
            OffsetWorldSpace = Vector3.new(0, 1, 0);
            ShowLabel = false;
        };
        destructible:SetHealthbarEnabled(true);

        limbHealthComp:SetMaxHealth(newHealth);
        limbHealthComp:Reset();
        
        limbHealthComp.OnHealthChanged:Connect(function(newHealth, prevHealth, damageData)
            if limbHealthComp.IsDead then return end;

            local newDmg = damageData:Clone();
            newDmg.HideBubble = true;
            
            npcClass.HealthComp:TakeDamage(newDmg);
        end)

        destructible.OnDestroy:Connect(function()
            primaryPart.Color = Color3.fromRGB(26, 0, 0);
            modAudio.Play("TicksZombieExplode", primaryPart.Position).PlaybackSpeed = 0.3;
            properties.AltReduction = math.max(properties.AltReduction-15, -30);
            wingModel:SetAttribute("EntityParent", true);
        end)
    end

    local bodyPosition = rootPart:WaitForChild("BodyPosition");
	local bodyGyro = rootPart:WaitForChild("BodyGyro");

    local initT = math.floor(tick());
    local seed = 0.12345;
    local offset = Vector3.new();

    local isFrost = false;

    npcClass.Garbage:Tag(RunService.Stepped:Connect(function(delta)
        for _, v in next, npcChar:GetDescendants() do
            if not v:IsA("BasePart") then continue end;
            v.CanCollide = false;
        end

        local moveFreq = properties.MovementFrequency;
        local altReduce = properties.AltReduction;
        local hoverPoint = properties.HoverPoint;
        local facePoint = properties.FacePoint;

        if isFrost then
            moveFreq /= 4;
        end

        hoverPoint += Vector3.new(0, altReduce, 0);

        local dir = (hoverPoint-bodyPosition.Position).Unit;
        local rotY = 0;
        
        local tagetDir = (facePoint - bodyPosition.Position).Unit;
        rotY = math.atan2(tagetDir.Z, -tagetDir.X)+math.pi/2;
        
        local midAng, maxAng = math.rad(-90), math.rad(90);
        local rotZ = -math.clamp(math.atan(dir.Z)/2, midAng, maxAng);
        local rotX = math.clamp(math.atan(dir.X)/2, midAng, maxAng);
        bodyGyro.CFrame = CFrame.Angles(rotZ, 0, rotX) * CFrame.Angles(0, rotY, 0);
        --pitch, yaw, roll
        
        local t = tick()-initT;
        offset = Vector3.new(
            math.noise(seed, t, 1)*moveFreq, 
            (math.noise(seed, t, 2)+0.5)*moveFreq, 
            math.noise(seed, t, 3)*moveFreq
        );

        bodyPosition.Position = hoverPoint + offset;
        bodyPosition.P = isFrost and 5000 or 11000;
    end));


    local lastPosition = rootPart.Position;
    local clockWiseSpin = math.random(0, 1) == 1 and 1 or -1;
    task.spawn(function()
        local t=0;
        while not npcClass.HealthComp.IsDead do
            local delta = task.wait(0.1);
            
            local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;
            if enemyTargetData then
                if properties.MoveState == "Follow" then
                    local enemyDistance = enemyTargetData.Distance;
                    local enemyCharacterClass = enemyTargetData.HealthComp.CompOwner;
                    local enemyPosition = enemyCharacterClass.RootPart.Position;


                    local flyAltitude = modMath.MapNum(enemyDistance, 0, 100, 15, 45);
                    local spinVec = Vector3.new(math.sin(t/4), 0, math.cos(t/4));

                    local newHoverPoint = enemyPosition + Vector3.new(0, flyAltitude, 0) + spinVec * 80;

                    local isInVision = npcClass:IsInVision(enemyCharacterClass.Character);
                    if not isInVision then
                        t += delta * clockWiseSpin;
                    end
                    properties.HoverPoint = newHoverPoint;
                    properties.FacePoint = enemyPosition;
                    lastPosition = enemyPosition;

                    if properties.AttackCooldownTick == nil or tick() > properties.AttackCooldownTick then
                        properties.AttackCooldownTick = tick() + math.random(8, 11);

                        properties.MoveState = "Attack";
                        properties.MoveStateChangedTick = tick();
                    end


                elseif properties.MoveState == "Attack" then
                    local enemyCharacterClass = enemyTargetData.HealthComp.CompOwner;
                    local enemyPosition = enemyCharacterClass.RootPart.Position;

                    local tpi = t/8 * math.pi;
                    local s = math.ceil(tick()/2%5);
                    
                    local x = math.sin((tpi-1)/2);
                    local z = math.cos(tpi-1);
                    
                    local v;
                    if s == 1 then
                        v = Vector3.new(x, 0, z);
                    elseif s == 2 then
                        v = Vector3.new(z, 0, x);
                    elseif s == 3 then
                        v = Vector3.new(-x, 0, -z);
                    elseif s == 4 then
                        v = Vector3.new(-z, 0, x);
                    elseif s == 5 then
                        v = Vector3.new(z, 0, -x);
                    end

                    t += delta;

                    local swerveVec = v;
                    properties.HoverPoint = lastPosition + Vector3.new(0, 35, 0) + swerveVec * 80;
                    properties.FacePoint = enemyPosition;
                    lastPosition = enemyPosition;

                    if tick() - properties.MoveStateChangedTick >= 4 then
                        properties.MoveState = "Follow";
                        properties.MoveStateChangedTick = tick();
                    end

                end
            else
                local spinVec = Vector3.new(math.sin(t/4), 0, math.cos(t/4));
                properties.HoverPoint = lastPosition + Vector3.new(0, 35, 0) + spinVec * 65;
                properties.FacePoint = lastPosition;
                t += delta * clockWiseSpin;

            end

        end
    end)

    npcClass.StatusComp.OnProcess:Connect(function()
        isFrost = #npcClass.StatusComp:ListStatusWithTags{"Frost"} > 0;
    end)
end

return npcPackage;