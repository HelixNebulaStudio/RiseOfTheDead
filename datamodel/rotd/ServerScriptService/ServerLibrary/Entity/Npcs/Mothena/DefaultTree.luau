local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modProjectile = shared.require(game.ReplicatedStorage.Library.Projectile);

local treePackage = {
    LogicString = {
        PoisonIvyBarrageTree = "CanAttack & [PoisonIvyBarrage]";
        Default = "HasEnemy & PoisonIvyBarrageTree";
    };
};
--==

function treePackage.HasEnemy(npcClass: NpcClass)
    local hasEnemy = npcClass.BehaviorTree:RunTree("HasEnemy", false);
    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;

    return enemyTargetData ~= nil;
end

function treePackage.CanAttack(npcClass: NpcClass)
    local properties = npcClass.Properties;
    return properties.MoveState == "Attack";
end


--MARK: PoisonIvyBarrageTree
function treePackage.PoisonIvyBarrage(npcClass: NpcClass)
    local properties = npcClass.Properties;

    if properties.PoisonIvyBarrageCooldown and tick() < properties.PoisonIvyBarrageCooldown then
        return;
    end
    properties.PoisonIvyBarrageCooldown = tick() + 0.5;

    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;
    local enemyCharacterClass = enemyTargetData.HealthComp.CompOwner;
    local enemyPosition = enemyCharacterClass.RootPart.Position;

    local poisonLaunchAtt = npcClass.Character:WaitForChild("UpperTorso"):WaitForChild("PoisonLaunchOrigin");

    local originCf = poisonLaunchAtt.WorldCFrame;
    local projectileInstance: ProjectileInstance = modProjectile.fire("poisonivy", {
        OriginCFrame = originCf;
    });
    projectileInstance.Part.Parent = properties.PoisonIvyModel;

    local velocity = projectileInstance.ArcTracer:GetVelocityByTime(
        originCf.Position, 
        enemyPosition, 
        math.random(-45, 60)/100
    );
    modProjectile.serverSimulate(projectileInstance, {
        RayWhitelist = {workspace.Environment; workspace.Terrain};
        Velocity = velocity;
    });
end

return treePackage;