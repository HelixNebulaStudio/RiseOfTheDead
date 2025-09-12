local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");

local modProjectile = shared.require(game.ReplicatedStorage.Library.Projectile);
local modMath = shared.require(game.ReplicatedStorage.Library.Util.Math);

local treePackage = {
    LogicString = {
        Default = "BurpConfusionGas | ZombieDefaultTree";
    };
};

--==
function treePackage.BurpConfusionGas(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    if enemyTargetData == nil then return false; end;
    if enemyTargetData.Distance > 16 then return false; end;

    local configurations = npcClass.Configurations;
    local properties = npcClass.Properties;

    if properties.LastBurpTick and properties.LastBurpTick > tick() then
        return false;
    end;
    properties.LastBurpTick = tick() + configurations.BurpCooldown;

    local targetRootPart = enemyTargetData.HealthComp.CompOwner.RootPart;

    npcClass.Move:SetMoveSpeed("set", "burp", 0, 9);
    task.wait(0.1);
    npcClass.Move:Face(targetRootPart);
    
    npcClass.PlayAnimation("Burp");
    task.wait(math.random(350,450)/1000);
    
    local level = (properties.Level-1);
    for a=1, math.random(4,6) do
        local headCframe = npcClass.Head.CFrame;
        local origin = headCframe.Position + headCframe.LookVector;
        
        local aimDir = (targetRootPart.Position-origin).Unit;
        local burpSpeed = 10 + (level/25);
        local velocity = modMath.CFrameSpread(aimDir, 5) * (burpSpeed+ math.random(0,2));

        local projectile: ProjectileInstance = modProjectile.fire("burpgas", {
            OriginCFrame = CFrame.new(origin);
        });

        modProjectile.serverSimulate(projectile, {
            Velocity = velocity;
            RayWhitelist = {CollectionService:GetTagged("PlayerCharacters")};
        });

        npcClass.Move:Face(targetRootPart);
        
        task.wait(math.random(500,700)/1000);
        if npcClass.HealthComp.IsDead then break end;
    end
    if npcClass.HealthComp.IsDead then
        return false;
    end;

    task.wait(math.random(250,350)/1000);
    npcClass.Move:SetMoveSpeed("remove", "burp");

    return false;
end

function treePackage.ZombieDefaultTree(npcClass: NpcClass)
    return npcClass.BehaviorTree:RunTree("ZombieDefaultTree", false);
end

return treePackage;