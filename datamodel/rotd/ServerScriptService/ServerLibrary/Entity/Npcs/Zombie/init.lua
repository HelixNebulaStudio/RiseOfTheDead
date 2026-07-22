local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local npcPackage = {
    Name = "Zombie";
    HumanoidType = "Zombie";
    
	Configurations = {
        AttackDamage = 5;
        AttackRange = 5;
        AttackSpeed = 2;

        MaxHealth = 50;
    };
    
    Properties = {
        PositionOctrees = {"Zombie"};
        BasicEnemy = true;
        IsHostile = true;

        TargetableDistance = 50;

        Level = 1;
        BaseExperience = 20;
        DropRewardId = "zombie";
    };

    Audio = {};

    AddComponents = {
        "DropReward";
        "TargetHandler";
        "RandomClothing";
        "ZombieBasicMeleeAttack";
        "DynamicLevel";
        "ImmunitySkin";
    };
    AddBehaviorTrees = {
        "ZombieDefaultTree";
    };

    DynamicLevelScaling = {
        WalkSpeed = function(lvl) return math.clamp(20 + math.floor(lvl/10), 1, 30); end;
        MaxHealth = function(lvl) return 49+(math.max(50*lvl, 50)); end;
        AttackDamage = function(lvl) return math.min(10+(lvl/2), 100); end;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
    npcClass.Garbage:Tag(npcClass.OnThink:Connect(function()
        npcClass.BehaviorTree:RunTree("ZombieDefaultTree", true);
    end));

    npcClass:GetComponent("RandomClothing")();
end

function npcPackage.onRequire()
    Debugger:StudioWarn(`Zombie OnRequire`);

    task.spawn(function()
        while true do
            task.wait(math.random(5, 10));

            local zombiesList = shared.modNpcs.listNpcClasses(function(npcClass: NpcClass)
                return npcClass.HumanoidType == "Zombie" and math.random(1, 2) == 1;
            end)
            if #zombiesList <= 0 then continue end;

            local zombieNpcClass = zombiesList[math.random(1, #zombiesList)];
            if zombieNpcClass == nil then continue end;

            local zCf = zombieNpcClass:GetCFrame();

            local npcsInBundle = shared.modNpcs.listInRange(zCf.Position, 20);
            local zombiesInBundle = {};
            for a=1, #npcsInBundle do
                if npcsInBundle[a].HumanoidType ~= "Zombie" then continue end;
                table.insert(zombiesInBundle, npcsInBundle[a]);
            end

            for a=1, #zombiesInBundle do
                local bundleZombieNpcClass: NpcClass = zombiesInBundle[a];
                bundleZombieNpcClass.Properties.HordeBundleSize = #zombiesInBundle;
                bundleZombieNpcClass.Properties.LastInHordeBundleTick = tick();
            end
        end
    end)
end

return npcPackage;