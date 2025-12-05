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
    local healthComp: HealthComp = npcClass.HealthComp;

    local level = math.max(properties.Level, 0);

    local lvlMoveSpeed = math.clamp(8 + math.floor(level/20), 1, 30);
    configurations.BaseValues.WalkSpeed = lvlMoveSpeed;
    
    local lvlHealth = 100+math.max(100 + 100*level, 100);
    configurations.BaseValues.MaxHealth = lvlHealth;

    local lvlAttackDamage = 30 + 3*level;
    configurations.BaseValues.AttackDamage = lvlAttackDamage;

    if healthComp.LastDamagedBy == nil then
        healthComp:Reset();
    end
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