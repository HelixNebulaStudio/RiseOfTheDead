local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modTables = shared.require(game.ReplicatedStorage.Library.Util.Tables);

local npcPackage = {
    Name = "Dr. Sinister";
    HumanoidType = "Zombie";
    
	Configurations = {
        AttackDamage = 5;
        AttackRange = 8;
        AttackSpeed = 1;

        MaxHealth = 50;

        SinisterScanRange = 16;
        SinisterScanCooldown = 5;
    };
    
    Properties = {
        BasicEnemy = true;
        IsHostile = true;

        TargetableDistance = 70;

        Level = 1;
        BaseExperience = 50;
    };

    Audio = {};

    AddComponents = {
        "TargetHandler";
        "ZombieBasicMeleeAttack";
        "DynamicLevel";
    };
    AddBehaviorTrees = {
        "ZombieDefaultTree";
    };

    DynamicLevelScaling = {
        WalkSpeed = 15;
        MaxHealth = function(lvl) return 499+(math.max(1500*lvl, 50)); end;
        AttackDamage = function(lvl) return math.min(25+(lvl*2), 100); end;
    };
};
--==
function npcPackage.Spawning(npcClass: NpcClass)
    npcClass.Character:SetAttribute("EntityHudHealth", true);
end


return npcPackage;