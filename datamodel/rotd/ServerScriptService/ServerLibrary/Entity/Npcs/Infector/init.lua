local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");

local npcPackage = {
    Name = "Infector";
    HumanoidType = "Zombie";
    
	Configurations = {
        AttackDamage = 10;
        AttackRange = 3;
        AttackSpeed = 3.5;

        MaxHealth = 50;
    };
    
    Properties = {
        BasicEnemy = false;
        IsHostile = true;
        Infector = true;

        TargetableDistance = 128;

        Level = 1;
        ExperiencePool = 20;
        DropRewardId = "zombie";
    };

    Audio = {};

    AddComponents = {
        "Chat";
        "DropReward";
        "TargetHandler";
    };
};

function npcPackage.LevelSet(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;
    local healthComp: HealthComp = npcClass.HealthComp;

    local level = math.max(properties.Level, 0);

    configurations.BaseValues.WalkSpeed = 22;

    local lvlHealth = math.max(50000 + 50*level, 50000)-1;
    configurations.BaseValues.MaxHealth = lvlHealth;

    local lvlAttackDamage = (level/2);
    configurations.BaseValues.AttackDamage = lvlAttackDamage;
    
    if healthComp.LastDamagedBy == nil then
        healthComp:Reset();
    end
end

function npcPackage.Spawning(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;

    npcPackage.LevelSet(npcClass);

    CollectionService:AddTag(npcClass.Character, "TargetableEntities");
    CollectionService:AddTag(npcClass.RootPart, "Enemies");
    CollectionService:AddTag(npcClass.Character, "Zombies");

    task.spawn(function()
        local face = npcClass.Head:WaitForChild("face");
        face.Texture = "rbxassetid://5195838286";
    end)
end

return npcPackage;