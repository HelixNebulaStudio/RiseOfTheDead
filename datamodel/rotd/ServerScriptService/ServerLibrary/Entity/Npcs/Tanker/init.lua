local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Tanker";
    HumanoidType = "Zombie";
    
	Configurations = {
        AttackDamage = 20;
        AttackRange = 8;
        AttackSpeed = 2.3;

        MaxHealth = 100;
        WalkSpeed = 8;
    };
    Properties = {
        IsHostile = true;

        TargetableDistance = 75;

        Level = 1;
        ExperiencePool = 40;
        MoneyReward = NumberRange.new(15, 20);
    };

    AddComponents = {
        "TargetHandler";
        "MeleeAttack";
        "ThrowTarget";
    };
    AddBehaviorTrees = {
        "ZombieBossDefaultTree";
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;

    local level = math.max(properties.Level, 0);

    if properties.HardMode then
        configurations.BaseValues.MaxHealth = math.max(200000 + 5000*level, 100);
        configurations.BaseValues.AttackDamage = 50;
        configurations.BaseValues.WalkSpeed = 14;
    else
        configurations.BaseValues.MaxHealth = math.max(5000 + 1500*level, 100);
        configurations.BaseValues.AttackDamage = 20;
        configurations.BaseValues.WalkSpeed = 8;
    end

    properties.NextAction = "RebarSlam";
    properties.RebarSlamCooldown = tick()+10;
    properties.RebarSpinCooldown = tick()+20;
end

function npcPackage.Spawned(npcClass: NpcClass)
    npcClass.WieldComp:Equip{
        ItemId = "tankerrebar";
    }
end

return npcPackage;