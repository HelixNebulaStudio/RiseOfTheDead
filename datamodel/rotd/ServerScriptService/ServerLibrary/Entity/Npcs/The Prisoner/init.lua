local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "The Prisoner";
    HumanoidType = "Zombie";
    
	Configurations = {
        --AttackDamage = 10;
        AttackRange = 8;
        AttackSpeed = 2.3;

        MaxHealth = 100;
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
        "ZombieBasicMeleeAttack";
    };
    AddBehaviorTrees = {
        "ZombieBossDefaultTree";
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;

    local level = math.max(properties.Level, 0);

    if properties.HardMode then
        configurations.BaseValues.MaxHealth = math.max(123000 + 4000*level, 100);
        configurations.BaseValues.AttackDamage = 30;
        configurations.BaseValues.WalkSpeed = 16;
    else
        configurations.BaseValues.MaxHealth = math.max(1000 + 500*level, 100);
        configurations.BaseValues.AttackDamage = 10;
        configurations.BaseValues.WalkSpeed = 10;
    end

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

    npcClass.OnThink:Connect(function() 
        if npcClass.HealthComp.CurHealth <= npcClass.HealthComp.MaxHealth*0.5 then
            if npcClass.WieldComp.EquipmentClass == nil then
                npcClass.WieldComp:Equip{
                    ItemId = "survivalknife";
                    OnSuccessFunc = function(toolHandler: ToolHandlerInstance)
                        if toolHandler.EquipmentClass == nil then return end;
                        local equipmentClass: EquipmentClass = toolHandler.EquipmentClass;

                        local modifier = equipmentClass.Configurations.newModifier("PrisonerMelee");
                        modifier.SetValues.Damage = 25;
                        modifier.SetValues.NpcPercentHealthDamage = 0.35;
                        equipmentClass.Configurations:AddModifier(modifier, true);
                    end;
                };
            end
        else
            if npcClass.WieldComp.EquipmentClass then
                npcClass.WieldComp:Unequip();
            end
        end
    end)
end

return npcPackage;