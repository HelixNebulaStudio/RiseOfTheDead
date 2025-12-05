local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Zpiderling";
    HumanoidType = "Zombie";
    
	Configurations = {
        AttackDamage = 5;
        AttackRange = 8;
        AttackSpeed = 2.3;

        MaxHealth = 100;
        WalkSpeed = 8;
    };
    Properties = {
        IsHostile = true;

        TargetableDistance = 75;

        Level = 1;
        ExperiencePool = 10;
        MoneyReward = NumberRange.new(15, 20);

        Immortal = 1;
    };
    Audio={
        BasicMeleeAttack="SpiderAttack1";
        Death="SpiderDeath1";
    };

    AddComponents = {
        "TargetHandler";
        "ZombieBasicMeleeAttack";
    };
    AddBehaviorTrees = {
        "ZombieBossDefaultTree";
    };
};

function npcPackage.onRequire()

end

function npcPackage.Spawning(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;

    local level = math.max(properties.Level, 0);

    if properties.HardMode then
        configurations.BaseValues.MaxHealth = math.max(50*(level/2), 100);
        configurations.BaseValues.AttackDamage = 5;
    else
        configurations.BaseValues.MaxHealth = math.max(20*(level/2), 10);
        configurations.BaseValues.AttackDamage = 2;
    end
    configurations.BaseValues.WalkSpeed = 20;
end

function npcPackage.Spawned(npcClass: NpcClass)
    task.delay(0.5, function()
        npcClass.Properties.Immortal = nil;
    end)

    npcClass.OnThink:Connect(function()
        if npcClass.HealthComp.IsDead then return end;
        local npcChar = npcClass.Character;
        npcChar.UpperTorso.CanCollide = false;
    end)
end

return npcPackage;