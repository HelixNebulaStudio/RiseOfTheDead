local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modExplosionHandler = shared.require(game.ReplicatedStorage.Library.ExplosionHandler);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local treePackage = {
    LogicString = {
        PlantExplosiveTree = "HasEnemy & CanPlantExplosive & [PlantExplosive]";
        Default = "PlantExplosiveTree | ZombieBossDefaultTree";
    };
};

function treePackage.onRequire()
    templateExplosiveBarrel = game.ServerStorage.Prefabs.Objects:WaitForChild("ExplosiveBarrel");
end

function treePackage.ZombieBossDefaultTree(npcClass: NpcClass)
    return npcClass.BehaviorTree:RunTree("ZombieBossDefaultTree", false);
end

function treePackage.HasEnemy(npcClass: NpcClass)
    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;
    return enemyTargetData ~= nil;
end


--MARK: PlantExplosiveTree
function treePackage.CanPlantExplosive(npcClass: NpcClass)
    local properties = npcClass.Properties;
    if properties.PlantExplosiveCooldown and tick()-properties.PlantExplosiveCooldown <= 10 then return false; end;
    return true;
end


function treePackage.PlantExplosive(npcClass: NpcClass)
    local properties = npcClass.Properties;
    properties.PlantExplosiveCooldown = tick();

    local newExplosive = templateExplosiveBarrel:Clone();
    npcClass.Garbage:Tag(newExplosive);

    local destructibleConfig = modDestructibles.createDestructible();
    destructibleConfig:SetAttribute("DebrisName", "GenericBarrel");
    destructibleConfig.Parent = newExplosive;

    local destructible: DestructibleInstance = modDestructibles.getOrNew(destructibleConfig);
    destructible.HealthComp:SetMaxHealth(1);
    destructible:SetEnabled(false);
    destructible.NetworkOwners = {};

    destructible.OnDestroy:Connect(function()
        newExplosive:SetAttribute("HostileDestructible", nil);
        local explosionPoint = newExplosive:GetPivot().Position;

        local hitLayers = modExplosionHandler:Cast(explosionPoint, {
            Radius = 16;
        });

        modExplosionHandler:Process(explosionPoint, hitLayers, {
            ExplosionBy = npcClass;
            TargetableTags = npcClass.WieldComp.TargetableTags;

            Damage = 25;
            MinDamage = 5;
            ExplosionStun = 1;

            DamageOrigin = explosionPoint;
            OnPartHit = modExplosionHandler.GenericOnPartHit;
        });

        local dbPoint = Debugger:Point(explosionPoint);
        Debugger.Expire(dbPoint, 2);
        modAudio.Play("VechicleExplosion", dbPoint);
        modAudio.Play("Explosion4", dbPoint);
    end)

    npcClass.Move:SetMoveSpeed("set", "placingstop", 0, 9, 2);
    
    task.wait(0.2);
    if npcClass.HealthComp.IsDead then return end;

    local rpLookVector = npcClass.RootPart.CFrame.LookVector;
    local rayOrigin = npcClass.RootPart.Position + rpLookVector*2;

    local raycastParams = RaycastParams.new();
    raycastParams.FilterType = Enum.RaycastFilterType.Include;
    raycastParams.FilterDescendantsInstances = {workspace.Environment; workspace.Terrain};

    local raycastResult = workspace:Raycast(rayOrigin, Vector3.new(0, -16, 0), raycastParams);
    if raycastResult == nil then return false; end;

    local floorPosition = raycastResult.Position;
    local floorNormal = raycastResult.Normal;

    npcClass.PlayAnimation("Placing");
    task.wait(0.3);
    if npcClass.HealthComp.IsDead then return end;

    modAudio.Play("MetalBarrelHit", npcClass.RootPart);
    task.wait(0.3);
    if npcClass.HealthComp.IsDead then return end;

    newExplosive:PivotTo(CFrame.lookAlong(floorPosition + Vector3.new(0, 0.75, 0), floorNormal) * CFrame.Angles(-math.pi/2, 0, 0));
    newExplosive.Parent = workspace.Environment;

    task.wait(0.6);
    if npcClass.HealthComp.IsDead then return end;
    destructible:SetEnabled(true);
    newExplosive:SetAttribute("HostileDestructible", true);

    return true;

end

return treePackage;