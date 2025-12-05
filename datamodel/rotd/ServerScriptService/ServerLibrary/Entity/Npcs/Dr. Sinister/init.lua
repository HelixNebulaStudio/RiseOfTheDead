local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modTables = shared.require(game.ReplicatedStorage.Library.Util.Tables);

local npcPackage = {
    Name = "Dr. Sinister";
    HumanoidType = "Zombie";
    
	Configurations = {
        AttackDamage = 5;
        AttackRange = 8;
        AttackSpeed = 1;

        MaxHealth = 50;

        SinisterScanRange = 16;
        SinisterScanCooldown = 5;
    };
    
    Properties = {
        BasicEnemy = true;
        IsHostile = true;

        TargetableDistance = 70;

        Level = 1;
        ExperiencePool = 50;
    };

    Audio = {};

    AddComponents = {
        "TargetHandler";
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

    local lvlMoveSpeed = 15;
    configurations.BaseValues.WalkSpeed = lvlMoveSpeed;

    local lvlHealth = math.clamp(2000*level, 2000, 102400);
    configurations.BaseValues.MaxHealth = lvlHealth;

    local lvlAttackDamage = 25 + 2*level;
    configurations.BaseValues.AttackDamage = lvlAttackDamage;
    
    if healthComp.LastDamagedBy == nil then
        healthComp:Reset();
    end
end

function npcPackage.Spawning(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;

    npcPackage.LevelSet(npcClass);

    npcClass.Character:SetAttribute("EntityHudHealth", true);
end


return npcPackage;