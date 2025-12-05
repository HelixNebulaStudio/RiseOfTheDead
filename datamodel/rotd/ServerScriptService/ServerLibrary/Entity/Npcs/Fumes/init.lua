local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Fumes";
    HumanoidType = "Zombie";
    
	Configurations = {
        AttackDamage = 10;
        AttackRange = 8;
        AttackSpeed = 2.3;

        MaxHealth = 100;
        WalkSpeed = 8;
    };
    Properties = {
        IsHostile = true;
        Detectable = false;

        TargetableDistance = 75;

        Level = 1;
        ExperiencePool = 40;
        MoneyReward = NumberRange.new(15, 20);
    };

    AddComponents = {
        "TargetHandler";
        "ZombieBasicMeleeAttack";
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
        configurations.BaseValues.MaxHealth = math.max(123000 + 4000*level, 100);
        configurations.BaseValues.AttackDamage = 80;
        configurations.BaseValues.WalkSpeed = 12;

        properties.FumesCloudSize = 90;
        properties.KnockbackResistant = 1;
    else
        configurations.BaseValues.MaxHealth = math.max(8000 + 2000*level, 100);
        configurations.BaseValues.AttackDamage = 40;
        configurations.BaseValues.WalkSpeed = 8;

        properties.FumesCloudSize = 70;
        properties.KnockbackResistant = 0.5;
    end

    properties.ThreatSenseHidden = true;
    properties.WeakPointHidden = true;
    properties.Immunity = 2;

    properties.CloudState = 0;
end

function npcPackage.Spawned(npcClass: NpcClass)
end

return npcPackage;