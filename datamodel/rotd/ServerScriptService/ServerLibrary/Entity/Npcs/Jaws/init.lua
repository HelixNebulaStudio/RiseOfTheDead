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
        BasicEnemy = true;
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
    local properties: PropertiesVariable<{}> = npcClass.Properties;
    local character = npcClass.Character;

    local level = math.max(properties.Level, 0);

    if properties.HardMode then
        configurations.BaseValues.MaxHealth = math.max(40000 + 6000*level, 100);
        configurations.BaseValues.AttackDamage = 30;
    else
        configurations.BaseValues.MaxHealth = math.max(20000 + 3000*level, 100);
        configurations.BaseValues.AttackDamage = 20;
    end

    npcClass.Move:SetMoveSpeed("set", "default", 0);

    local bodyDestructiblesComp = npcClass:GetComponent("BodyDestructibles");

    local jawModels = {
        character:WaitForChild("LJaw");
        character:WaitForChild("RJaw");
    }

    for a=1, #jawModels do
        local key = jawModels[a].Name:sub(1,1);
        local insideModel = jawModels[a]:WaitForChild("JawInsides");
        
        local jawDestructible: DestructibleInstance = bodyDestructiblesComp:Create(`${key} Jaw`, insideModel);
        
        function jawDestructible.HealthComp:TakeDamage(damageData: DamageData)
            npcClass.HealthComp:TakeDamage(damageData);
        end
    end

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
    properties.LastStrikeCooldown = tick()+5;
end

function npcPackage.Spawned(npcClass: NpcClass)
    local properties = npcClass.Properties;
    npcClass.Character:SetAttribute("EntityHudHealth", true);
end

return npcPackage;