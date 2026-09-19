local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modProjectile = shared.require(game.ReplicatedStorage.Library.Projectile);

local treePackage = {
    LogicString = {
        Default = "BanditDefaultTree";
    };
};
--==
function treePackage.BanditDefaultTree(npcClass: NpcClass)
    return npcClass.BehaviorTree:RunTree("BanditDefaultTree", false);
end


function treePackage.HasEnemy(npcClass: NpcClass)
    local properties = npcClass.Properties;

    local enemyTargetData: NpcTargetData = properties.EnemyTargetData;
    return enemyTargetData ~= nil;
end


return treePackage;