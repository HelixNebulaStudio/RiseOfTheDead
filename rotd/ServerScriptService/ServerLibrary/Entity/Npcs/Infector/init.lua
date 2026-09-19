local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");

local npcPackage = {
    Name = "Infector";
    HumanoidType = "Zombie";
    
	Configurations = {
        AttackDamage = 10;
        AttackRange = 3;
        AttackSpeed = 3.5;

        MaxHealth = 50;
    };
    
    Properties = {
        BasicEnemy = false;
        IsHostile = true;
        Infector = true;

        TargetableDistance = 128;

        Level = 1;
        BaseExperience = 20;
        DropRewardId = "zombie";
    };

    Audio = {};

    AddComponents = {
        "Chat";
        "DropReward";
        "TargetHandler";
        "DynamicLevel";
    };

    DynamicLevelScaling = {
        WalkSpeed = 22;
        MaxHealth = function(lvl) return 49999+(math.max(1000*lvl, 50)); end;
        AttackDamage = function(lvl) return math.min(5+(lvl/2), 100); end;
    };
};

function npcPackage.Spawning(npcClass: NpcClass)
    CollectionService:AddTag(npcClass.Character, "TargetableEntities");
    CollectionService:AddTag(npcClass.RootPart, "Enemies");
    CollectionService:AddTag(npcClass.Character, "Zombies");

    task.spawn(function()
        local face = npcClass.Head:WaitForChild("face");
        face.Texture = "rbxassetid://5195838286";
    end)
end

return npcPackage;