local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
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

return npcPackage;