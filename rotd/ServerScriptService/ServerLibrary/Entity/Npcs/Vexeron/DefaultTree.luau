local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");

local treePackage = {
    LogicString = {
        HuntTree = "HasEnemy & IsHunting & [Hunt]";
        AttackTree = "HasEnemy & IsAttacking & [Attack]";
        Default = "HuntTree | AttackTree | Idle";
    };
};

--==
function treePackage.HasEnemy(npcClass: NpcClass)
    local properties = npcClass.Properties;

    local hasEnemy = npcClass.BehaviorTree:RunTree("HasEnemy", false);
    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;

    if hasEnemy and properties.State == "Idle" then
        properties.State = "Hunt";
        properties.StageChangedTick = tick();
    end

    return enemyTargetData ~= nil;
end

function treePackage.Idle(npcClass: NpcClass)
    local properties = npcClass.Properties;
    properties.State = "Idle";
    return true;
end

function treePackage.IsAttacking(npcClass: NpcClass)
    return npcClass.Properties.State == "Attack";
end

function treePackage.Attack(npcClass: NpcClass)
    local properties = npcClass.Properties;

    if tick()-properties.StageChangedTick >= 10 then
        properties.State = "Idle";
        properties.StageChangedTick = tick();
    end

    return true;
end

function treePackage.IsHunting(npcClass: NpcClass)
    return npcClass.Properties.State == "Hunt";
end

function treePackage.Hunt(npcClass: NpcClass)
    local properties = npcClass.Properties;

    if tick()-properties.StageChangedTick >= 6 then
        properties.State = "Attack";
        properties.StageChangedTick = tick();
    end
end

return treePackage;