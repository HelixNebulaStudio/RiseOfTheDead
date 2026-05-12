local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Jaws";
    HumanoidType = "Zombie";
    
	Configurations = {
        AttackDamage = 20;
        AttackRange = 15;
        AttackSpeed = 1;

        MaxHealth = 100;
        WalkSpeed = 0;
    };
    Properties = {
        BasicEnemy = false;
        IsHostile = true;

        TargetableDistance = 75;
        Detectable = false;

        Level = 1;
        ExperiencePool = 20;
        MoneyReward = NumberRange.new(25, 30);

        KnockbackResistant = 1;
        SkipMoveInit = true;
    };

    Audio = {
        Death = "ZombieDeath5";
        Attack = "ZombieAttack4";
    };

    AddComponents = {
        "TargetHandler";
        "ZombieBasicMeleeAttack";
        "BodyDestructibles";
    };
    AddBehaviorTrees = {
        "HasEnemy";
    };
};


function npcPackage.Spawning(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<anydict> = npcClass.Properties;
    local character = npcClass.Character;

    local level = math.max(properties.Level, 0);

    if properties.HardMode then
        configurations.BaseValues.MaxHealth = math.max(60000 + 3000*level, 100);
        configurations.BaseValues.AttackDamage = 40;
    else
        configurations.BaseValues.MaxHealth = math.max(30000 + 1500*level, 100);
        configurations.BaseValues.AttackDamage = 25;
    end

    npcClass.Move:SetMoveSpeed("set", "default", 0);

    local jawModels = {
        character:WaitForChild("LJaw");
        character:WaitForChild("RJaw");
    }

    local jawMotors = {};
    for _, obj in pairs(npcClass.Head:GetChildren()) do
        if obj:IsA("Motor6D") then
            table.insert(jawMotors, obj);
        end
    end

    npcClass.OnThink:Connect(function()
        npcClass.RootPart.CanCollide = false;
    end)

    properties.IsJawOpen = true;
    properties.JawModels = jawModels;
    properties.JawMotors = jawMotors;
    properties.LastStrikeCooldown = tick()+1;
end

function npcPackage.Spawned(npcClass: NpcClass)
    local properties = npcClass.Properties;

    npcClass.Character:SetAttribute("EntityHudHealth", true);

    
    local bodyDestructiblesComp = npcClass:GetComponent("BodyDestructibles");

    local jawModels = properties.JawModels;
    for a=1, #jawModels do
        local key = jawModels[a].Name:sub(1,1);
        local insideModel = jawModels[a]:WaitForChild("JawInsides");
        
        local jawDestructible: DestructibleInstance = bodyDestructiblesComp:Create(`${key} Jaw`, insideModel);
        jawDestructible.Properties.DestroyModel = false;

        function jawDestructible.HealthComp:TakeDamage(damageData: DamageData)
            npcClass.HealthComp:TakeDamage(damageData);
        end
    end
end

return npcPackage;