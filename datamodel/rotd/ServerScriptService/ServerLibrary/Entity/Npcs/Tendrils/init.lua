local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modTables = shared.require(game.ReplicatedStorage.Library.Util.Tables);

local npcPackage = {
    Name = "Tendrils";
    HumanoidType = "Zombie";
    
	Configurations = {
        AttackDamage = 5;
        AttackRange = 5;
        AttackSpeed = 2;

        MaxHealth = 50;

        MeleeImmunity = 1;

        GrappleRange = 16;
        GrappleCooldown = 5;
    };
    
    Properties = {
        BasicEnemy = true;
        IsHostile = true;

        TargetableDistance = 30;
        LockOnExpireDuration = NumberRange.new(1, 2);

        Level = 1;
        ExperiencePool = 45;
        DropRewardId = "tendrils";

        JointsStrength = {
            RootStump = true; -- true = only breaks on lethal damage
            TorsoVoid = true;
            ArmVoid = true;
        };
    };

    Audio = {};

    AddComponents = {
        "DropReward";
        "TargetHandler";
        "ZombieBasicMeleeAttack";
        "TendrilsGrapple";
        "DynamicLevel";
    };
    AddBehaviorTrees = {};

    DynamicLevelScaling = {
        WalkSpeed = 0;
        MaxHealth = function(lvl) return (math.max(200*lvl, 200)); end;
        AttackDamage = function(lvl) return math.min(20+(lvl*2), 100); end;
    };
};
--==

function npcPackage.Spawning(npcClass: NpcClass)
end


return npcPackage;