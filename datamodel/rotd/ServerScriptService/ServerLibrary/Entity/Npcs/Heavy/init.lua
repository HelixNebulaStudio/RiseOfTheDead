local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Heavy";
    HumanoidType = "Zombie";
    
	Configurations = {
        AttackDamage = 5;
        AttackRange = 4;
        AttackSpeed = 2.3;

        MaxHealth = 100;
        
        ThrowCooldown = 7;
    };
    
    Properties = {
        BasicEnemy = true;
        IsHostile = true;

        TargetableDistance = 40;
        LockOnExpireDuration = NumberRange.new(5, 10);

        Level = 1;
        ExperiencePool = 30;
        DropRewardId = "heavy";
    };

    Audio = {};

    AddComponents = {
        "DropReward";
        "TargetHandler";
        "RandomClothing";
        "ZombieBasicMeleeAttack";
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

    local lvlHealth = math.max(100 + 100*level, 100);
    local lvlMoveSpeed = math.clamp(8 + math.floor(level/20), 1, 30);
    local lvlAttackDamage = 30 + 3*level;
    
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

    npcClass:GetComponent("RandomClothing"){
        AddHair = false;
    };
end


return npcPackage;