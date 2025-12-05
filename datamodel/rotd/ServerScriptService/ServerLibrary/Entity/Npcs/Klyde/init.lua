local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Klyde";
    HumanoidType = "Bandit";
    
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
    };
    AddBehaviorTrees = {
        "ZombieBossDefaultTree";
    };

    IdleRandomChatCooldown = NumberRange.new(10, 20);
    IdleRandomChat = {
        "Come out, come out, whereeever you are!";
		"Come ooon, you think you can out run bullets?";
		"Ooooooh Yeeeeah!!";
		"Bring it on kiddos!";
		"Woooooo! There's plenty more where that came from!";
		"Daance! Monkey, dance!";
		"Dance! Hahahaha! Dance!";
		"The more you moove, the more fun it gets!";
		"Praise BioX for this amazing catastrophe!";
    };
    
    ThinkCycle = 1;
};

function npcPackage.Spawning(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;

    local level = math.max(properties.Level, 0);

    if properties.HardMode then
        configurations.BaseValues.MaxHealth = math.max(75000 + 4000*level, 100);
        configurations.BaseValues.AttackDamage = 20;
        configurations.BaseValues.WalkSpeed = 12;

        properties.KnockbackResistant = 1;
    else
        configurations.BaseValues.MaxHealth = math.max(35000 + 2000*level, 100);
        configurations.BaseValues.AttackDamage = 10;
        configurations.BaseValues.WalkSpeed = 12;

        properties.KnockbackResistant = 0.5;
    end

    properties.GrenadeLauncherCooldown = tick();
end

function npcPackage.Spawned(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;

    wieldComp.TargetableTags.Destructibles = true;

    npcClass.WieldComp:Equip{
        ItemId = "grenadelauncher";
        OnSuccessFunc = function(toolHandler: ToolHandlerInstance)
            local equipmentClass: EquipmentClass? = toolHandler.EquipmentClass;
            if equipmentClass == nil then return end;

            equipmentClass.Properties.InfiniteAmmo = 1;

            local modifier = equipmentClass.Configurations.newModifier("BanditGun");
            modifier.SetValues.Damage = 5;
            modifier.SetValues.Rpm = 999;
            modifier.SetValues.NpcPercentHealthDamage = 0.1;
            equipmentClass.Configurations:AddModifier(modifier, true);
        end
    };
end

return npcPackage;