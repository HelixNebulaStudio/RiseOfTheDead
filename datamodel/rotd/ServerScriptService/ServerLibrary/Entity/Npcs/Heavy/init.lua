local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local npcPackage = {
    Name = "Heavy";
    HumanoidType = "Zombie";
    
	Configurations = {
        AttackDamage = 5;
        AttackRange = 4;
        AttackSpeed = 2.3;

        MaxHealth = 100;
        
        ThrowCooldown = 7;
        
        CripplingHit = 0.5;
    };
    
    Properties = {
        BasicEnemy = true;
        IsHostile = true;

        TargetableDistance = 40;
        LockOnExpireDuration = NumberRange.new(5, 10);

        Level = 1;
        BaseExperience = 30;
        DropRewardId = "heavy";
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
        WalkSpeed = function(lvl) return math.clamp(8 + math.floor(lvl/20), 1, 25); end;
        MaxHealth = function(lvl) return 99+(math.max(100*lvl, 100)); end;
        AttackDamage = function(lvl) return math.min(30+(lvl*3), 150); end;
        Immunity = function(lvl, maxLvl) return math.clamp(lvl/maxLvl, 0.1, 0.65); end;
        CripplingHit = function(lvl, maxLvl) return math.clamp(lvl/(maxLvl/2), 0.5, 1); end;
    };
};
--==

function npcPackage.Spawning(npcClass: NpcClass)
    npcClass:GetComponent("RandomClothing"){
        AddHair = false;
    };
end


return npcPackage;