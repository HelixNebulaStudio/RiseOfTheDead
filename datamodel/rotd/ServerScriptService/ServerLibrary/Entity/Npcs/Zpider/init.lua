local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

local npcPackage = {
    Name = "Zpider";
    HumanoidType = "Zombie";
    
	Configurations = {
        AttackDamage = 20;
        AttackRange = 6;
        AttackSpeed = 2;

        MaxHealth = 100;
        WalkSpeed = 18;
    };
    Properties = {
        IsHostile = true;

        TargetableDistance = 75;

        Level = 1;
        ExperiencePool = 40;
        MoneyReward = NumberRange.new(15, 20);

        KnockbackResistant = 1;
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
        configurations.BaseValues.MaxHealth = math.max(500000 + 10000*level, 100);
        configurations.BaseValues.AttackDamage = 45;
        configurations.BaseValues.WalkSpeed = 20;
    else
        configurations.BaseValues.MaxHealth = math.max(16000 + 3000*level, 100);
        configurations.BaseValues.AttackDamage = 25;
        configurations.BaseValues.WalkSpeed = 16;
    end
end

function npcPackage.Spawned(npcClass: NpcClass)
    local properties = npcClass.Properties;

    properties.LastZpiderlingSpawn = tick();
    npcClass.HealthComp.OnHealthChanged:Connect(function(curHealth, oldHealth)
        if curHealth <= 0 then return end;
        if curHealth > oldHealth then return end;

        if tick()-properties.LastZpiderlingSpawn <= 1 then return end;
        properties.LastZpiderlingSpawn = tick();

        local zpiderlingNpcClass: NpcClass = shared.modNpcs.spawn2{
            Name = "Zpiderling";
            CFrame = npcClass.RootPart.CFrame;
            BindSetup = function(npcClass: NpcClass)
                npcClass.Properties.Level = properties.Level;
                npcClass.Properties.HardMode = properties.HardMode;
            end;
        };
        local zpiderlingHealthComp = zpiderlingNpcClass.HealthComp;
        npcClass.HealthComp.OnIsDeadChanged:Connect(function(isDead)
            if not isDead then return end;
            if zpiderlingHealthComp.IsDead then return end;

            task.spawn(function()
                if zpiderlingHealthComp.IsDead then return end;

                for a=1, 20 do
                    zpiderlingHealthComp:TakeDamage(DamageData.new{
                        Damage = zpiderlingHealthComp.MaxHealth*0.201;
                    });

                    task.wait(1);
                    if zpiderlingHealthComp.IsDead then break end;
                end
            end)
        end)

        local targetHandlerComp = zpiderlingNpcClass:GetComponent("TargetHandler");
        targetHandlerComp:AddTarget(npcClass.Character);
    end)
end

return npcPackage;