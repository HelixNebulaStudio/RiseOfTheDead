local RunService = game:GetService("RunService")
local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Shadow";
    HumanoidType = "Zombie";
    
	Configurations = {
        AttackDamage = 5;
        AttackRange = 32;
        AttackSpeed = 0.5;

        MaxHealth = 100;
        WalkSpeed = 0;
    };
    Properties = {
        IsHostile = true;

        TargetableDistance = 75;
        Detectable = false;

        Level = 1;
        ExperiencePool = 80;
        MoneyReward = NumberRange.new(25, 30);

        KnockbackResistant = 1;
        SkipMoveInit = true;
    };

    AddComponents = {
        "TargetHandler";
        "ZombieBasicMeleeAttack";
        "BlinkTeleport";
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
        configurations.BaseValues.MaxHealth = math.max(500000 + 10000*level, 100);
        configurations.BaseValues.AttackDamage = 10;
    else
        configurations.BaseValues.MaxHealth = math.max(20000 + 4000*level, 100);
        configurations.BaseValues.AttackDamage = 5;
    end

    npcClass.Move:SetMoveSpeed("set", "default", 0);
end

function npcPackage.Spawned(npcClass: NpcClass)
    local templateShadowMist = game.ServerStorage.Prefabs.Objects:WaitForChild("ShadowMist");

    local mistTable = {
        {
            Part = templateShadowMist:Clone();
            SpinRate = 4;
            Scale = 2;
        };
        {
            Part = templateShadowMist:Clone();
            SpinRate = 2;
            Scale = 3;
        };
        {
            Part = templateShadowMist:Clone();
            SpinRate = -3.5;
            Scale = 1;
        };
    };

    for a=1, #mistTable do
        local mistData = mistTable[a];

        mistData.Part.Parent = workspace.Debris;
        mistData.Part.Size = mistData.Part.Size * mistData.Scale;

        npcClass.Garbage:Tag(mistData.Part);
    end

    task.spawn(function()
        local r = 0;
        while true do
            local delta = RunService.Heartbeat:Wait();
            if npcClass.HealthComp.IsDead then return end;

            r += delta;

            local rpCf = npcClass.RootPart.CFrame;

            for a=1, #mistTable do
                local mistData = mistTable[a];
                
                local newCf;
                local enemyTargetData = npcClass.Properties.EnemyTargetData;
                if enemyTargetData and enemyTargetData.HealthComp and enemyTargetData.HealthComp.CompOwner then
                    local enemyCf = enemyTargetData.HealthComp.CompOwner.Character:GetPivot();

                    newCf = CFrame.new((enemyCf.Position + rpCf.Position)/2);
                else
                    newCf = CFrame.new(rpCf.Position);
                end
                mistData.Part.CFrame = newCf * CFrame.Angles(0, r*mistData.SpinRate, 0);
            end
        end
    end)

    npcClass.HealthComp.OnIsDeadChanged:Connect(function()
        for a=1, #mistTable do
            mistTable[a].Part:Destroy();
        end
    end)

    npcClass.HealthComp.OnHealthChanged:Connect(function(newHealth, oldHealth, damageData)
        if newHealth > oldHealth then return end;
        if damageData.DamageType ~= nil then return end;
        npcClass.Character:SetAttribute("HitReveal", not npcClass.Character:GetAttribute("HitReveal"));
    end)

    local enemyTargetInstance = Instance.new("ObjectValue");
    enemyTargetInstance.Name = "EnemyTarget";
    enemyTargetInstance.Parent = npcClass.Character;

    npcClass.OnThink:Connect(function()
        local enemyTargetData = npcClass.Properties.EnemyTargetData;
        if enemyTargetData and enemyTargetData.HealthComp and enemyTargetData.HealthComp.CompOwner then
            enemyTargetInstance.Value = enemyTargetData.HealthComp.CompOwner.Character;
        else
            enemyTargetInstance.Value = nil;
        end
    end)
end

return npcPackage;