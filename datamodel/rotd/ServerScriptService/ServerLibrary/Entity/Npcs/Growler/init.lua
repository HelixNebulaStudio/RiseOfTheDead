local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modTables = shared.require(game.ReplicatedStorage.Library.Util.Tables);

local npcPackage = {
    Name = "Growler";
    HumanoidType = "Zombie";
    
	Configurations = {
        AttackDamage = 5;
        AttackRange = 8;
        AttackSpeed = 0.5;

        MaxHealth = 50;
    };
    
    Properties = {
        BasicEnemy = true;
        IsHostile = true;

        TargetableDistance = 70;
        LockOnExpireDuration = NumberRange.new(5, 8);

        Level = 1;
        ExperiencePool = 30;
        DropRewardId = "growler";
    };

    Audio = {};

    AddComponents = {
        "TargetHandler";
        "RandomClothing";
        "ZombieBasicMeleeAttack";
        "BodyDestructibles";
    };
    AddBehaviorTrees = {
        "ZombieDefaultTree";
    };
};
--==

function npcPackage.LevelSet(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;

    local level = math.max(properties.Level, 0);

    local lvlHealth = math.max(100 + 100*level, 200);
    local lvlMoveSpeed = math.clamp(15 + math.floor(level/10), 1, 30);
    local lvlAttackDamage = 10 + level/3;
    
    npcClass.Move.SetDefaultWalkSpeed = lvlMoveSpeed;
    npcClass.Move:Init();
    
    local healthComp: HealthComp = npcClass.HealthComp;
    healthComp:SetMaxHealth(lvlHealth);
    if healthComp.LastDamagedBy == nil then
        healthComp:Reset();
    end

    local levelstatModifier = configurations:GetModifier("LevelStat");
    if levelstatModifier == nil then
        levelstatModifier = configurations.newModifier("LevelStat");
    end
    
    levelstatModifier.SumValues.MaxHealth = lvlHealth;
    levelstatModifier.SumValues.AttackDamage = lvlAttackDamage;

    configurations:AddModifier(levelstatModifier, false);
end

function npcPackage.Spawning(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;

    npcPackage.LevelSet(npcClass);
		
    local driedFleshModel = npcClass.Character:WaitForChild("DriedNekronFlesh");
    local fleshParts = driedFleshModel:GetChildren();
    
    modTables.Shuffle(fleshParts);
    for a=1, #fleshParts do
        if a > 3 then
            Debugger.Expire(fleshParts[a], 0);
        else
            local part = fleshParts[a];
            part.Transparency = 0;
        end
    end


    local bodyDestructiblesComp = npcClass:GetComponent("BodyDestructibles");

    local shieldPrefix = {"Left"; "Right"};
    for a=1, #shieldPrefix do
        local prefix = shieldPrefix[a];
        local name = `{prefix} Scale Claw`;
        
        local shieldAccessory = npcClass.Character:FindFirstChild(name);
        
        local destructible: DestructibleInstance = bodyDestructiblesComp:Create(name, shieldAccessory);
        destructible.DebrisName = name;
        destructible.HealthComp:SetMaxHealth(math.max(npcClass.HealthComp.MaxHealth*0.1, 50));
        destructible.HealthComp:Reset();

        destructible:SetupHealthbar{
            Size = UDim2.new(1.2, 0, 0.25, 0);
            Distance = 32;
            OffsetWorldSpace = Vector3.new(0, 1, 0);
            ShowLabel = false;
        };
        destructible:SetHealthbarEnabled(true);

        destructible.OnDestroy:Connect(function()
            local hurtSound = modAudio.Play(`ZombieHurt2`, npcClass.RootPart);
            hurtSound.PlaybackSpeed = math.random(90, 100)/100;
        end)
    end

    
    npcClass:GetComponent("RandomClothing"){
        AddHair = false;
    };
end


return npcPackage;