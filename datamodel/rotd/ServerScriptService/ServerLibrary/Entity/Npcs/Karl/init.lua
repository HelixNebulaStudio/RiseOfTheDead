local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Karl";
    HumanoidType = "Bandit";
    
	Configurations = {
        AttackDamage = 20;
        AttackRange = 4;
        AttackSpeed = 1;

        MaxHealth = 100;
        WalkSpeed = 20;
    };
    Properties = {
        IsHostile = true;
        Smart = true;

        TargetableDistance = 75;

        Level = 1;
        ExperiencePool = 35;
        MoneyReward = NumberRange.new(15, 20);
    };

    AddComponents = {
        "TargetHandler";
        "ZombieBasicMeleeAttack";
    };
    AddBehaviorTrees = {
        "ZombieBossDefaultTree";
    };

    IdleRandomChatCooldown = NumberRange.new(10, 20);
    IdleRandomChat = {
		"Don't run so I can slice you!";
		"Let's not make this difficult!";
		"Which way is it, the easy way or the hard way?";
		"Do you need to catch a breath? Stand still!";
		"Come back here!";
		"Is this your blood on my blade?";
    };
    
    ThinkCycle = 1;
};

function npcPackage.Spawning(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;

    local level = math.max(properties.Level, 0);

    if properties.HardMode then
        configurations.BaseValues.MaxHealth = math.max(95000 + 4000*level, 100);
        configurations.BaseValues.AttackDamage = 30;

        properties.KnockbackResistant = 1;
    else
        configurations.BaseValues.MaxHealth = math.max(55000 + 2000*level, 100);
        configurations.BaseValues.AttackDamage = 10;

        properties.KnockbackResistant = 0.5;
    end
    
end

function npcPackage.Spawned(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local wieldComp: WieldComp = npcClass.WieldComp;

    wieldComp.TargetableTags.Destructibles = true;

    npcClass.WieldComp:Equip{
        ItemId = "machete";
        OnSuccessFunc = function(toolHandler: ToolHandlerInstance)
            local equipmentClass: EquipmentClass? = toolHandler.EquipmentClass;
            if equipmentClass == nil then return end;
            
            local modifier = equipmentClass.Configurations.newModifier("MacheteMelee");
            modifier.SetValues.Damage = configurations.AttackDamage;
            modifier.SetValues.NpcPercentHealthDamage = 0.25;
            equipmentClass.Configurations:AddModifier(modifier, true);
        end;
    };
end

return npcPackage;