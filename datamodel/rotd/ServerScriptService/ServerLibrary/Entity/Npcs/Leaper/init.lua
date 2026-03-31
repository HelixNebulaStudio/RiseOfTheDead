local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Leaper";
    HumanoidType = "Zombie";
    
	Configurations = {
        AttackDamage = 5;
        AttackRange = 6;
        AttackSpeed = 2;

        MaxHealth = 50;
        
        LeapCooldownDuration = 5;
    };
    
    Properties = {
        BasicEnemy = true;
        IsHostile = true;

        TargetableDistance = 40;
        LockOnExpireDuration = NumberRange.new(5, 8);

        Level = 1;
        ExperiencePool = 30;
        DropRewardId = "leaper";
    };

    Audio = {};

    AddComponents = {
        "DropReward";
        "TargetHandler";
        "RandomClothing";
        "ZombieBasicMeleeAttack";
        "DynamicLevel";
    };
    AddBehaviorTrees = {
        "ZombieDefaultTree";
    };

    DynamicLevelScaling = {
        WalkSpeed = function(lvl) return math.clamp(16 + math.floor(lvl/15), 1, 30); end;
        MaxHealth = function(lvl) return 59+(math.max(40*lvl, 60)); end;
        AttackDamage = function(lvl) return math.min(10+(lvl/10), 100); end;
    };
};
--==

function npcPackage.Spawning(npcClass: NpcClass)
    npcClass:GetComponent("RandomClothing")();
end


return npcPackage;