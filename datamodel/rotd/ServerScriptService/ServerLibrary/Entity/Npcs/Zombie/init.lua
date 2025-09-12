local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Zombie";
    HumanoidType = "Zombie";
    
	Configurations = {
        AttackDamage = 5;
        AttackRange = 5;
        AttackSpeed = 2;

        MaxHealth = 50;
    };
    
    Properties = {
        BasicEnemy = true;
        IsHostile = true;

        TargetableDistance = 50;

        Level = 1;
        ExperiencePool = 20;
        DropRewardId = "zombie";
    };

    Audio = {};

    AddComponents = {
        "TargetHandler";
        "RandomClothing";
        "ZombieBasicMeleeAttack";
    };
    AddBehaviorTrees = {
        "ZombieDefaultTree";
    };
};

function npcPackage.LevelSet(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;

    local level = math.max(properties.Level, 0);

    local lvlHealth = math.max(50 + 50*level, 50)-1;
    local lvlMoveSpeed = math.clamp(18 + math.floor(level/10), 1, 35);
    local lvlAttackDamage = (level/2);
    
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

    properties.OnChanged:Connect(function(k, v)
        if npcClass.HealthComp.IsDead then return end;
        if k == "Level" then
            npcPackage.LevelSet(npcClass);
        end
    end)
    npcPackage.LevelSet(npcClass);

    npcClass.Garbage:Tag(npcClass.OnThink:Connect(function()
        npcClass.BehaviorTree:RunTree("ZombieDefaultTree", true);
    end));

    npcClass:GetComponent("RandomClothing")();
end

return npcPackage;