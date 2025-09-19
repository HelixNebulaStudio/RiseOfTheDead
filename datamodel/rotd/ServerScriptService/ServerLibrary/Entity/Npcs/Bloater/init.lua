local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modTables = shared.require(game.ReplicatedStorage.Library.Util.Tables);

local npcPackage = {
    Name = "Bloater";
    HumanoidType = "Zombie";
    
	Configurations = {
        AttackDamage = 5;
        AttackRange = 7;
        AttackSpeed = 2;

        MaxHealth = 50;

        BurpCooldown = 7;
    };
    
    Properties = {
        BasicEnemy = true;
        IsHostile = true;

        TargetableDistance = 100;
        LockOnExpireDuration = NumberRange.new(1, 3);

        Level = 1;
        ExperiencePool = 35;
        DropRewardId = "bloater";
    };

    Audio = {};

    AddComponents = {
        "DropReward";
        "TargetHandler";
        "ZombieBasicMeleeAttack";
        "RandomClothing";
        "BodyDestructibles";
        "DizzyCloud";
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

    local lvlHealth = math.max(0 + 100*level, 100);
    local lvlMoveSpeed = 10;
    local lvlAttackDamage = 30 + 2*level;
    
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
		

    local sporesModel = npcClass.Character:WaitForChild("Spores");
    local sporesParts = sporesModel:GetChildren();
    
    modTables.Shuffle(sporesParts);
    local pickCount = math.random(8, 12);
    for a=1, #sporesParts do
        if a > pickCount then
            game.Debris:AddItem(sporesParts[a], 0);
            
        else
            local sporePart = sporesParts[a];
            sporePart.Transparency = 0;
            
            if math.random(1, 3) == 1 then
                local newDrip = game.ReplicatedStorage.Particles:WaitForChild("SporeDripEmitter"):Clone();
                newDrip.Rate = math.random(3, 8);
                newDrip.Speed = NumberRange.new(3, 6);
                newDrip.Parent = sporePart.SporeEmitter;
            end
        end
    end

    local bodyDestructiblesComp = npcClass:GetComponent("BodyDestructibles");

    local destructible: DestructibleInstance = bodyDestructiblesComp:Create("Spores", sporesModel);
    destructible.HealthComp:SetMaxHealth(math.max(npcClass.HealthComp.MaxHealth*0.1, 50));
    destructible.HealthComp:Reset();

    destructible.OnDestroy:Connect(function()
        local hurtSound = modAudio.Play(`ZombieHurt2`, npcClass.RootPart);
        hurtSound.PlaybackSpeed = math.random(60, 70)/100;
    end)

    npcClass.HealthComp.OnIsDeadChanged:Connect(function()
        if not npcClass.HealthComp.IsDead then return end;

        npcClass:GetComponent("DizzyCloud")(math.clamp(properties.Level, 10, 30));
    end)

    npcClass:GetComponent("RandomClothing"){
        AddHair = false;
    };
end


return npcPackage;