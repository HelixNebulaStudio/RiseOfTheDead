local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Hector Shot";
    HumanoidType = "Bandit";
    
	Configurations = {
        AttackDamage = 90;
        AttackRange = 8;
        AttackSpeed = 2;

        MaxHealth = 100;
        WalkSpeed = 8;
    };
    Properties = {
        IsHostile = true;
		Smart = true;

        TargetableDistance = 75;

        Level = 1;
        ExperiencePool = 40;
        MoneyReward = NumberRange.new(130, 180);
    };

    AddComponents = {
        "TargetHandler";
        "Chat";
    };
    AddBehaviorTrees = {
        "HasEnemy";
    };

    HuntInitSpeech = {
		"Look who do we have here!";
		"I see you!";
		"Peeka boo, I see you!";
		"Look what we got here!";
    };
    LassoInitSpeech = {
        "Yeeeeehaw!";
		"Y'all need to start running!";
		"C'mon now!";
    };
    LassoedSpeech = {
        "Git! Got another one!";
        "Ho! You ain't running fast enough!";
        "He-yah!";
    };

    Voice = {
        VoiceId = 3;
        Pitch = -7;
        Speed = 1.15;
        PlaybackSpeed = 1.2;
    };
    
    ThinkCycle = 1;
};

function npcPackage.Spawning(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;

    local level = math.max(properties.Level, 0);

    if properties.HardMode then
        configurations.BaseValues.MaxHealth = math.max(98000 + 8000*level, 100);
        configurations.BaseValues.AttackDamage = 90;
        configurations.BaseValues.WalkSpeed = 22;

        properties.KnockbackResistant = 1;
    else
        configurations.BaseValues.MaxHealth = math.max(69000 + 4000*level, 100);
        configurations.BaseValues.AttackDamage = 60;
        configurations.BaseValues.WalkSpeed = 20;

        properties.KnockbackResistant = 0.5;
    end

    properties.State = "Search";
end

function npcPackage.Spawned(npcClass: NpcClass)
end

return npcPackage;