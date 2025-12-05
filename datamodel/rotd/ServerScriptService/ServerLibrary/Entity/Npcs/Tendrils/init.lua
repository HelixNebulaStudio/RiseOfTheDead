local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modTables = shared.require(game.ReplicatedStorage.Library.Util.Tables);

local npcPackage = {
    Name = "Tendrils";
    HumanoidType = "Zombie";
    
	Configurations = {
        AttackDamage = 5;
        AttackRange = 5;
        AttackSpeed = 2;

        MaxHealth = 50;

        MeleeImmunity = 1;

        GrappleRange = 16;
        GrappleCooldown = 5;
    };
    
    Properties = {
        BasicEnemy = true;
        IsHostile = true;

        TargetableDistance = 30;
        LockOnExpireDuration = NumberRange.new(1, 2);

        Level = 1;
        ExperiencePool = 45;
        DropRewardId = "tendrils";
    };

    Audio = {};

    AddComponents = {
        "DropReward";
        "TargetHandler";
        "ZombieBasicMeleeAttack";
        "TendrilsGrapple";
    };
    AddBehaviorTrees = {};
};
--==

function npcPackage.LevelSet(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;
    local healthComp: HealthComp = npcClass.HealthComp;

    local level = math.max(properties.Level, 0);

    local lvlMoveSpeed = 0;
    configurations.BaseValues.WalkSpeed = lvlMoveSpeed;
    
    local lvlHealth = math.max(200*level, 200);
    configurations.BaseValues.MaxHealth = lvlHealth;

    local lvlAttackDamage = 20 + 2*level;
    configurations.BaseValues.AttackDamage = lvlAttackDamage;

    if healthComp.LastDamagedBy == nil then
        healthComp:Reset();
    end
end

function npcPackage.Spawning(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;

    npcPackage.LevelSet(npcClass);
end


return npcPackage;