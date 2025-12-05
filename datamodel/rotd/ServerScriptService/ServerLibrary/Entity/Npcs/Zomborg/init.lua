local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local npcPackage = {
    Name = "Zomborg";
    HumanoidType = "Zombie";
    
	Configurations = {
        AttackDamage = 45;
        AttackRange = 7;
        AttackSpeed = 1.5;

        MaxHealth = 100;
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
        configurations.BaseValues.AttackDamage = 80;
        configurations.BaseValues.WalkSpeed = 12;
    else
        configurations.BaseValues.MaxHealth = math.max(16000 + 3000*level, 100);
        configurations.BaseValues.AttackDamage = 45;
        configurations.BaseValues.WalkSpeed = 8;
    end

    properties.ExplosionDamage = 30;
    properties.ExplosionRange = 25;
    properties.ExplosionBeamCooldown = tick()-28;

    
    local leftHand = npcClass.Character:WaitForChild("LeftHand");
    local energyBall = Instance.new("Part");
    energyBall.Color = Color3.fromRGB(255, 0, 0);
    energyBall.CastShadow = false;
    energyBall.Transparency = 1;
    energyBall.CanCollide = false;
    energyBall.CanQuery = false;
    energyBall.Shape = Enum.PartType.Ball;
    energyBall.Size = Vector3.new(0.1, 0.1, 0.1);
    energyBall.Material = Enum.Material.Neon;
    energyBall.Massless = true;
    energyBall.CFrame = CFrame.new(leftHand.Position);
    energyBall.Parent = leftHand;
    local energyLight = Instance.new("PointLight");
    energyLight.Color = Color3.fromRGB(255, 0, 0);
    energyLight.Range = 12;
    energyLight.Brightness = 0;
    energyLight.Enabled = false;
    energyLight.Parent = energyBall;
    properties.EnergyLight = energyLight;

    local weld = Instance.new("Motor6D");
    weld.Part0 = leftHand;
    weld.Part1 = energyBall;
    weld.Parent = energyBall;

    properties.EnergyBall = energyBall;
end


function npcPackage.Spawned(npcClass: NpcClass)
    local properties = npcClass.Properties;
    
    -- Shield
    local healthComp: HealthComp = npcClass.HealthComp;

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

                npcClass:GetComponent("ArcExplosion")(part.Position, 30, 48);
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