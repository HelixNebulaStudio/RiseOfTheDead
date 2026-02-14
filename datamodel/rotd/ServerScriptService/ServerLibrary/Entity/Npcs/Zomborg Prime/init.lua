local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local npcPackage = {
    Name = "Zomborg Prime";
    HumanoidType = "Zombie";
    
	Configurations = {
        AttackDamage = 45;
        AttackRange = 7;
        AttackSpeed = 1.5;

        MaxHealth = 100;
        MaxArmor = 100;
        WalkSpeed = 8;
    };
    Properties = {
        IsHostile = true;

        TargetableDistance = 75;

        Level = 1;
        ExperiencePool = 50;
        MoneyReward = NumberRange.new(60, 80);

        KnockbackResistant = 1;
    };

    AddComponents = {
        "TargetHandler";
        "ZombieBasicMeleeAttack";
        "BodyDestructibles";
        "ThrowTarget";
        "ArcExplosion";
    };
    AddBehaviorTrees = {
        "ZombieBossDefaultTree";
    };

    TouchHandler = nil;
};

function npcPackage.Spawning(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;

    local level = math.max(properties.Level, 0);

    if properties.HardMode then
        configurations.BaseValues.MaxHealth = math.max(500000 + 10000*level, 100);
        configurations.BaseValues.MaxArmor =  30000;
        configurations.BaseValues.AttackDamage = 80;
        configurations.BaseValues.WalkSpeed = 10;
    else
        configurations.BaseValues.MaxHealth = math.max(16000 + 3000*level, 100);
        configurations.BaseValues.MaxArmor =  15000;
        configurations.BaseValues.AttackDamage = 45;
        configurations.BaseValues.WalkSpeed = 6;
    end
end


function npcPackage.Spawned(npcClass: NpcClass)
    local configurations = npcClass.Configurations;
    local properties = npcClass.Properties;
    
    -- Shield
    local healthComp: HealthComp = npcClass.HealthComp;

    local bodyDestructiblesComp = npcClass:GetComponent("BodyDestructibles");

    local maxHealth = configurations.BaseValues.MaxHealth;

    local powerSource = npcClass.Character:WaitForChild("PowerSource");
    local powerSrcDestructible: DestructibleInstance = bodyDestructiblesComp:Create("Power Source", powerSource);
    powerSrcDestructible.HealthComp:SetMaxHealth(math.max(maxHealth*0.2, 50));
    powerSrcDestructible.HealthComp:Reset();
    
    powerSrcDestructible:SetupHealthbar{
        Size = UDim2.new(1.2, 0, 0.25, 0);
        Distance = 32;
        OffsetWorldSpace = Vector3.new(0, 1, 0);
        ShowLabel = false;
    };
    powerSrcDestructible:SetHealthbarEnabled(true);
    powerSrcDestructible.OnDestroy:Connect(function()
        powerSource.PrimaryPart.Material = Enum.Material.SmoothPlastic;
        powerSource.PrimaryPart.Color = Color3.fromRGB(0, 35, 0);

        local hurtSound = modAudio.Play(`ZombieHurt2`, npcClass.RootPart);
        hurtSound.PlaybackSpeed = math.random(90, 100)/100;

        npcClass.HealthComp:TakeDamage(DamageData.new{
            Damage = powerSrcDestructible.HealthComp.MaxHealth;
            DamageType = "Explosive";
        });
    end)
    powerSrcDestructible.OnDestroy:Connect(function()
        npcClass:GetComponent("ArcExplosion")(npcClass.RootPart.Position, 10, 128);
    end)


    local leftLauncher = npcClass.Character:WaitForChild("LeftLauncher");
    local rightLauncher = npcClass.Character:WaitForChild("RightLauncher");

    properties.LauncherPoints = {};

    local launchers = {leftLauncher, rightLauncher};
    for a=1, #launchers do
        local launcher = launchers[a];

        local launcherPoint = launcher:WaitForChild("PrimaryPart"):WaitForChild("LaunchPoint");
        table.insert(properties.LauncherPoints, launcherPoint);

        local destructible: DestructibleInstance = bodyDestructiblesComp:Create(launcher.Name, launcher);
        destructible.DebrisName = launcher:GetAttribute("DebrisName");
        destructible.HealthComp:SetMaxHealth(math.max(maxHealth*0.1, 50));
        destructible.HealthComp:Reset();
        destructible:SetEnabled(false);
        
        destructible:SetupHealthbar{
            Size = UDim2.new(1.2, 0, 0.25, 0);
            Distance = 32;
            OffsetWorldSpace = Vector3.new(0, 1, 0);
            ShowLabel = false;
        };
        destructible:SetHealthbarEnabled(true);

        destructible.OnDestroy:Connect(function()
            for a=#properties.LauncherPoints, 1, -1 do
                if properties.LauncherPoints[a] == launcherPoint then
                    table.remove(properties.LauncherPoints, a);
                end
            end

            local hurtSound = modAudio.Play(`ZombieHurt2`, launcherPoint.WorldPosition);
            hurtSound.PlaybackSpeed = math.random(90, 100)/100;

            if powerSrcDestructible.HealthComp.IsDead then return end;
            npcClass:GetComponent("ArcExplosion")(launcherPoint.WorldPosition, 10, 32);
        end)

        powerSrcDestructible.OnDestroy:Connect(function()
            destructible:SetEnabled(true);
        end)
    end

    task.spawn(function()
        while not npcClass.HealthComp.IsDead do
            task.wait(0.5);
            if powerSrcDestructible.HealthComp.IsDead then return; end;

            if npcClass.HealthComp.CurArmor < npcClass.HealthComp.MaxArmor then 
                local healAmt = powerSrcDestructible.HealthComp.MaxHealth*0.3;
                local curArmor = npcClass.HealthComp.CurArmor;
                npcClass.HealthComp:SetArmor(curArmor + healAmt);
            end;

            for a=1, #launchers do
                local launcher = launchers[a];
                local destructible: DestructibleInstance = bodyDestructiblesComp:Get(launcher.Name);
                if destructible == nil or destructible.HealthComp.IsDead then continue; end;
                if destructible.HealthComp.CurHealth >= destructible.HealthComp.MaxHealth then continue; end;

                local healAmt = destructible.HealthComp.MaxHealth*0.3;
                destructible.HealthComp:TakeDamage(DamageData.new{
                    Damage = -healAmt;
                    DamageType = "Heal";
                })
            end
        end
    end)



    local shieldsTable = {};
    for a=1, 3 do
		local shield = Instance.new("Part");
		shield.Color = Color3.fromRGB(255, 0, 0);
		shield.CanCollide = false;
        shield.CanQuery = false;
		shield.Shape = Enum.PartType.Ball;
		shield.Size = Vector3.new(0.1, 0.1, 0.1);
		shield.Material = Enum.Material.ForceField;
		shield.Transparency = 1;
		shield.Massless = true;
        shield.CFrame = CFrame.new(npcClass.RootPart.Position);
		shield.Parent = npcClass.Character;
        npcClass.Garbage:Tag(shield);

        local weld = Instance.new("Motor6D");
        weld.Part0 = npcClass.RootPart;
        weld.Part1 = shield;
        weld.Parent = shield;

        table.insert(shieldsTable, {
            Index = a;
            Part = shield;
            IsActivated = false;
            Activate = function(self)
                if self.IsActivated then return end;
                self.IsActivated = true;

                local part = self.Part;
                part.Transparency = 0;

                TweenService:Create(part, TweenInfo.new(3), {
                    Size = Vector3.one * (8 + (a*3));
                }):Play();
                
                task.wait(3);
                if npcClass.HealthComp.IsDead then return end
                part:Destroy();

                npcClass:GetComponent("ArcExplosion")(part.Position, 20, 48);
            end
        });
    end

    healthComp.OnHealthChanged:Connect(function()
        local hpRatio = healthComp.CurHealth/healthComp.MaxHealth;

        if hpRatio <= 0.3 then
            shieldsTable[1]:Activate();
            properties.Immunity = 0.9;

        elseif hpRatio <= 0.6 then
            shieldsTable[2]:Activate();
            properties.Immunity = 0.6;

        elseif hpRatio <= 0.9 then
            shieldsTable[3]:Activate();
            properties.Immunity = 0.3;

        end
    end)
end

return npcPackage;