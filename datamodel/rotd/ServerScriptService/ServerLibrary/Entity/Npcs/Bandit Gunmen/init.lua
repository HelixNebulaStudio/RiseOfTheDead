local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Bandit Gunmen";
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
        "RandomClothing";
    };
    AddBehaviorTrees = {
        "HasEnemy";
    };

    ThinkCycle = 1;
};

function npcPackage.Spawning(npcClass: NpcClass)
    local configurations: ConfigVariable = npcClass.Configurations;
    local properties: PropertiesVariable<{}> = npcClass.Properties;

    local level = math.max(properties.Level, 0);

    if properties.HardMode then
        configurations.BaseValues.MaxHealth = math.max(3000 + 200*level, 100);
        configurations.BaseValues.AttackDamage = 30;

        properties.KnockbackResistant = 1;
    else
        configurations.BaseValues.MaxHealth = 64000;
        configurations.BaseValues.AttackDamage = 10;

        properties.KnockbackResistant = 0.5;
    end
    
    npcClass.Humanoid.HealthDisplayDistance = 512;

    task.delay(0.5, function()
        npcClass.RootPart.Anchored = false;
        if properties.Seat == nil then return end;

        local seatPart = properties.Seat;
        npcClass:Sit(seatPart);

        -- if seatPart.Name == "Seat7" then
        --     local track = npcClass.AnimationController.Animator:LoadAnimation(script:WaitForChild("HeliGunmen1"));
        --     track:Play();
        -- else
        --     local track = npcClass.AnimationController.Animator:LoadAnimation(script:WaitForChild("HeliGunmen2"));
        --     track:Play();
        -- end
    end)

    npcClass:GetComponent("RandomClothing")();
end

function npcPackage.Spawned(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local isHard = properties.HardMode;

    npcClass.WieldComp:Equip{
        ItemId = "fnfal";
        OnSuccessFunc = function(toolHandler: ToolHandlerInstance)
            local equipmentClass: EquipmentClass? = toolHandler.EquipmentClass;
            if equipmentClass == nil then return end;

            equipmentClass.Properties.InfiniteAmmo = 1;
            
            local modifier = equipmentClass.Configurations.newModifier("BanditGun");
            modifier.SetValues.Damage = isHard and 4 or 2;
            modifier.SetValues.NpcPercentHealthDamage = 0.1;
            modifier.SetValues.MagazineSize = 45;
            equipmentClass.Configurations:AddModifier(modifier, true);
        end
    };

    for _, obj in pairs(npcClass.Character:GetDescendants()) do
        if not obj:IsA("BasePart") then continue end;
        obj.CollisionGroup = "CollisionOff";
    end
end

return npcPackage;