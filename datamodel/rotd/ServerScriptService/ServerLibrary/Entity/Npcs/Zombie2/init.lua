local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Zombie2";
    HumanoidType = "Zombie";
    CharacterPrefabName = "Zombie";
    
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
    };

    Audio = {};

    AddComponents = {
        "TargetHandler";
        "RandomClothing";
        "ZombieBasicMeleeAttack";
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;

    local level = math.max(properties.Level, 0);
    
    npcClass.Move.SetDefaultWalkSpeed = math.clamp(18 + math.floor(level/10), 1, 35);
    npcClass.Move:Init();

    local levelstatModifier = configurations.newModifier("LevelStat");

    levelstatModifier.SumValues.MaxHealth = 50*level;
    levelstatModifier.SumValues.AttackDamage = (level/2);

    configurations:AddModifier(levelstatModifier, false);

    npcClass.Garbage:Tag(npcClass.OnThink:Connect(function()
        npcClass.BehaviorTree:RunTree("ZombieDefaultTree", true);
    end));
end

return npcPackage;