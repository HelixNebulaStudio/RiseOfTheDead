local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");

local modTouchHandler = shared.require(game.ReplicatedStorage.Library.TouchHandler);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffects);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local npcPackage = {
    Name = "Zricera";
    HumanoidType = "Zombie";
    PathAgent = {AgentRadius=20; AgentHeight=6;};
    
	Configurations = {
        MaxDamage = 45;

        AttackDamage = 50;
        AttackRange = 20;
        AttackSpeed = 4;

        MaxHealth = 100;
        
        ThrowCooldown = 7;
    };
    
    Properties = {
        BasicEnemy = false;
        IsHostile = true;

        TargetableDistance = 40;
        LockOnExpireDuration = NumberRange.new(5, 10);

        Level = 1;
        ExperiencePool = 1000;
        MoneyReward = {Min = 1500; Max = 1700};
        DropRewardId = "heavy";
    };

    Audio = {};

    AddComponents = {
        "DropReward";
        "TargetHandler";
        "BodyDestructibles";
        "ZombieBasicMeleeAttack";
        "ThrowTarget";
        "RbxConfigSync";
    };
    AddBehaviorTrees = {
        "ZombieBossDefaultTree";
    };

    TouchHandler = nil;
    ThinkCycle = 1;
};
--==

function npcPackage.onRequire()
    local touchHandler = modTouchHandler.new("FireSteps", 0.5);

    function touchHandler:OnPlayerTouch(player, basePart, part)
        local npcChar = basePart.Parent and basePart.Parent.Parent or nil;
        if npcChar == nil or npcChar:FindFirstChildWhichIsA("Humanoid") == nil then return end;
        
        local npcClass: NpcClass? = shared.modNpcs.getByModel(npcChar);
        if npcClass == nil then return end;

        local playerClass: PlayerClass = shared.modPlayers.get(player);
        if playerClass == nil or not playerClass.HealthComp:CanTakeDamageFrom(npcClass) then return end;

        if player then
            modStatusEffects.Burn(player, 35, 5);
        end;
        game.Debris:AddItem(basePart, 0);
    end
    
    function touchHandler:OnPartTouch(basePart, part)
        if CollectionService:HasTag(part, "Flammable") == nil then return end;

        local modFlammable = shared.require(game.ServerScriptService.ServerLibrary.Flammable);
        modFlammable:Ignite(part);
    end

    npcPackage.TouchHandler = touchHandler;
end

function npcPackage.Spawning(npcClass: NpcClass)
    local character = npcClass.Character;
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;

    local isHard = properties.HardMode;
    local level = math.max(properties.Level, 0);

    configurations.BaseValues.WalkSpeed = 16;

    local lvlHealth = math.max(10000 + 500*level, 10000);
    if isHard then
        lvlHealth = 1200300;
    end

    npcClass:GetComponent("RbxConfigSync")(function(configDict)
        if configDict.MaxHealth then
            lvlHealth = configDict.MaxHealth;
        end
        if configDict.MaxDamage then
            configurations.BaseValues.MaxDamage = configDict.MaxDamage;
        end
    end)

    Debugger:Warn("MaxHealth", lvlHealth);
    Debugger:Warn("MaxDamage", configurations.BaseValues.MaxDamage);
    configurations.BaseValues.MaxHealth = lvlHealth;


    if not isHard then
        for _, obj in pairs(character:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Material == Enum.Material.Foil then
                obj.Material = Enum.Material.Pebble;
                obj.Color = Color3.fromRGB(218, 134, 122);
            end
        end
    end

    npcClass.Garbage:Tag(function()
        local fakeHead = npcClass.Character:WaitForChild("FakeHead");
        fakeHead.Material = Enum.Material.SmoothPlastic;
        game.Debris:AddItem(fakeHead:FindFirstChild("Fire"), 0);
    end)

    local flameStepModel = Instance.new("Model");
    flameStepModel.Name = `FlameSteps`;
    flameStepModel.Parent = npcClass.Character;
    properties.FlameStepModel = flameStepModel;

    properties.SpitFireCooldown = tick();
    properties.LeapCooldown = tick();
    properties.ThrowPlayerCooldown = tick();
    properties.SleepHealCooldown = tick();
    properties.SleepHealCount = 1;
    properties.SleepHealPool = 0;
end

function npcPackage.Spawned(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties = npcClass.Properties;
    local healthComp: HealthComp = npcClass.HealthComp;
    local character = npcClass.Character;

    local isHard = properties.HardMode;
    local framePrefab = game.ServerStorage.Prefabs.Objects:WaitForChild("ZriceraFlame");

    npcClass.Character:SetAttribute("EntityHudHealth", true);
    
    local lastLavaSpawn = tick();
    local circlePi = math.pi*2;
    local function spawnLava(position)
        if tick()-lastLavaSpawn <= 0.1 then return end;
        lastLavaSpawn = tick();
        
        local raycastParams = RaycastParams.new();
        raycastParams.FilterType = Enum.RaycastFilterType.Include;
        raycastParams.IgnoreWater = true;
        raycastParams.FilterDescendantsInstances = {workspace.Environment};
        raycastParams.CollisionGroup = "Raycast";
        
        local lavaCount = 6;
        
        for a=1, lavaCount do
            
            local ringPos = position + (CFrame.Angles(0, circlePi/lavaCount*a , 0) * CFrame.new(0, 0, 3)).Position;

            local raycastResult = workspace:Raycast(ringPos + Vector3.new(0, 3, 0), Vector3.new(0, -16, 0), raycastParams);
            if raycastResult then
                local newFlame = framePrefab:Clone();
                newFlame.CFrame = CFrame.new(raycastResult.Position);
                newFlame.Parent = properties.FlameStepModel;
                Debugger.Expire(newFlame, 10);
                npcPackage.TouchHandler:AddObject(newFlame);
                
            end
            
        end
        
    end

    local bodyDestructiblesComp = npcClass:GetComponent("BodyDestructibles");
    local lvlHealth = configurations.BaseValues.MaxHealth;

    local limbsList = {
        {Name="LeftArm"; Text="Left Leg"; Health=math.max(lvlHealth*0.0125, 15000); HardHealthMulti=10;};
        {Name="RightArm"; Text="Right Leg"; Health=math.max(lvlHealth*0.0125, 15000); HardHealthMulti=10;};
        {Name="LeftLeg"; Text="Left Hind"; Health=math.max(lvlHealth*0.005, 15000); HardHealthMulti=10;};
        {Name="RightLeg"; Text="Right Hind"; Health=math.max(lvlHealth*0.005, 15000); HardHealthMulti=10;};
    };

    for a=1, #limbsList do
        local limb = limbsList[a];
        local limbModel: Model = character:WaitForChild(limb.Name)

        local destructible: DestructibleInstance = bodyDestructiblesComp:Create(limb.Name, limbModel);
        destructible.Properties.DestroyModel = false;
        local newHealth = limb.Health * (isHard and limb.HardHealthMulti or 1);
        
        local limbHealthComp: HealthComp = destructible.HealthComp;
        limbHealthComp:SetMaxHealth(newHealth);
        limbHealthComp:Reset();

        limbHealthComp.OnHealthChanged:Connect(function(newHealth, prevHealth, damageData)
            if limbHealthComp.IsDead then return end;
            if newHealth == prevHealth then return end;
            if damageData.Damage == nil then return end;

            healthComp:TakeDamage(damageData);
        end)

        destructible.OnDestroy:Connect(function()
            local hurtSound = modAudio.Play(`ZombieHurt1`, npcClass.RootPart);
            hurtSound.PlaybackSpeed = math.random(85, 95)/100;

            if limbModel.PrimaryPart then
                limbModel.PrimaryPart.Color = Color3.fromRGB(50, 50, 50);
            end
        end)
    end



    local runningTracks = npcClass.AnimationController:GetTrackGroup("Running");
    for a=1, #runningTracks do
        local track = runningTracks[a].Track;
        npcClass.Garbage:Tag(track:GetMarkerReachedSignal("Step"):Connect(function(paramString)
            if paramString == "1" then
                local rightArmDestructible: DestructibleInstance = bodyDestructiblesComp:Get("RightArm");
                local rightPaw = rightArmDestructible.Model:FindFirstChild("RightHand");
                if rightPaw and not rightArmDestructible.HealthComp.IsDead then
                    spawnLava(rightPaw.Position);
                end

            elseif paramString == "2" then
                local leftArmDestructible: DestructibleInstance = bodyDestructiblesComp:Get("LeftArm");
                local leftPaw = leftArmDestructible.Model:FindFirstChild("LeftHand");
                if leftPaw and not leftArmDestructible.HealthComp.IsDead then
                    spawnLava(leftPaw.Position);
                end

            end
        end));
    end

    modAudio.Play("ZriceriaRoar", npcClass.RootPart).Volume = 1;
    modAudio.Play("Fire", npcClass.RootPart, true).Volume = 3;
end

return npcPackage;