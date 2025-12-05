local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Leaper";
    HumanoidType = "Zombie";
    
	Configurations = {
        AttackDamage = 5;
        AttackRange = 6;
        AttackSpeed = 2;

        MaxHealth = 50;
        
        LeapCooldownDuration = 5;
    };
    
    Properties = {
        BasicEnemy = true;
        IsHostile = true;

        TargetableDistance = 40;
        LockOnExpireDuration = NumberRange.new(5, 8);

        Level = 1;
        ExperiencePool = 30;
        DropRewardId = "leaper";
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

    local lvlMoveSpeed = math.clamp(16 + math.floor(level/15), 1, 30);
    configurations.BaseValues.WalkSpeed = lvlMoveSpeed;
    
    local lvlHealth = 50+math.max(60 + 40*level, 60);
    configurations.BaseValues.MaxHealth = lvlHealth;

    local lvlAttackDamage = 10 + (level/10);
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

    npcClass:GetComponent("RandomClothing")();
end


return npcPackage;