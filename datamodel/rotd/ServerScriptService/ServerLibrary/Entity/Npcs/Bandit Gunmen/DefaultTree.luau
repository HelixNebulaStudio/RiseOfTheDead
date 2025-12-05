local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modProjectile = shared.require(game.ReplicatedStorage.Library.Projectile);

local treePackage = {
    LogicString = {
        AggroTree = "HasEnemy & CanFireGun & [FireGun]";
        Default = "AggroTree | Idle";
    };
};
--==
function treePackage.HasEnemy(npcClass: NpcClass)
    local properties = npcClass.Properties;

    local spotlightTag = properties.SpotlightTarget and properties.SpotlightTarget.Value or nil;
    if spotlightTag == nil then return false end;

    local character = spotlightTag.Parent;
    local playerClass: PlayerClass = shared.modPlayers.getByModel(character);
    if playerClass == nil then return false end;
    if playerClass.HealthComp.IsDead then return false end;

    properties.EnemyTargetData = {
        HealthComp = playerClass.HealthComp;
        Distance = (playerClass.RootPart.Position - npcClass.RootPart.Position).Magnitude;
        Model = playerClass.Character;
        LastAddedTick = tick();
    };

    local enemyTargetData: NpcTargetData = properties.EnemyTargetData;
    return enemyTargetData ~= nil;
end

function treePackage.Idle(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local wieldComp: WieldComp = npcClass.WieldComp;

    properties.EnemyTargetData = nil;
    wieldComp.Controls.Mouse1Down = false;

    if wieldComp.EquipmentClass == nil then return end;
    if wieldComp.EquipmentClass.Properties.Ammo <= 0 then 
        wieldComp:InvokeToolAction("ReloadRequest");
    end;
end

--MARK: AggroTree
function treePackage.CanFireGun(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;
    if wieldComp.EquipmentClass == nil then return false end;
    if wieldComp.EquipmentClass.Properties.Ammo <= 0 then return false end;

    return true;
end

function treePackage.FireGun(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;
    local properties = npcClass.Properties;
    local enemyTargetData: NpcTargetData = properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    wieldComp:InvokeToolAction("PrimaryFireRequest", nil, enemyNpcClass.Humanoid);
end


return treePackage;