local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "The Prisoner";
    HumanoidType = "Zombie";
    
	Configurations = {
        --AttackDamage = 10;
        AttackRange = 8;
        AttackSpeed = 2.3;

        --MaxHealth = 2000;
    };
    
    Properties = {
        IsHostile = true;

        TargetableDistance = 75;

        Level = 1;
        ExperiencePool = 20;
        MoneyReward = NumberRange.new(15, 20);
    };

    AddComponents = {
        "TargetHandler";
        "MeleeAttack";
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;

    local levelstatModifier: ConfigModifier = configurations.newModifier("LevelStat");
    local level = math.max(properties.Level, 0);

    if properties.HardMode then
        levelstatModifier.SetValues.MaxHealth = math.max(123000 + 4000*level, 100);
        levelstatModifier.SetValues.AttackDamage = 30;
        npcClass.Move.SetDefaultWalkSpeed = 16;
    else
        levelstatModifier.SetValues.MaxHealth = math.max(1000 + 500*level, 100);
        levelstatModifier.SetValues.AttackDamage = 10;
        npcClass.Move.SetDefaultWalkSpeed = 10;
    end
    configurations:AddModifier(levelstatModifier, false);

    npcClass.Move:Init();

    task.spawn(function()
        local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1, true);
        
        local chainMotor1 = npcClass.Character:WaitForChild("RightUpperArm"):WaitForChild("RUAChain2");
        local chainMotor2 = npcClass.Character:WaitForChild("RightLowerArm"):WaitForChild("RLAChain2");
        
        local rate = math.pi;
        local rad = 0;
        while not npcClass.HealthComp.IsDead do
            rad = rad + (rate * task.wait());
            chainMotor1.C1 = CFrame.Angles(0, rad, 0);
            chainMotor2.C1 = CFrame.Angles(0, rad, 0);
        end
    end)
end

return npcPackage;