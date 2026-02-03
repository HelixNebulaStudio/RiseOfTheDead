local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");

local treePackage = {
    LogicString = {
        LaunchGrenadesTree = "HasEnemy & CanLaunchGrenades & ReloadGrenadeLauncher & [LaunchGrenades]";
        Default = "LaunchGrenadesTree | ZombieBossDefaultTree";
    };
};

function treePackage.ZombieBossDefaultTree(npcClass: NpcClass)
    return npcClass.BehaviorTree:RunTree("ZombieBossDefaultTree", false);
end

function treePackage.HasEnemy(npcClass: NpcClass)
    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;

    if enemyTargetData then
        npcClass.Move:Face(enemyTargetData.Model:GetPivot().Position);
    end

    return enemyTargetData ~= nil;
end


--MARK: LaunchGrenadesTree
function treePackage.CanLaunchGrenades(npcClass: NpcClass)
    local properties = npcClass.Properties;
    if properties.GrenadeLauncherCooldown and tick()-properties.GrenadeLauncherCooldown <= 8 then return false; end;
    
    return true;
end

function treePackage.ReloadGrenadeLauncher(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;
    if wieldComp.EquipmentClass == nil then return false; end;

    if wieldComp.EquipmentClass.Properties.Ammo <= 0 then
        wieldComp:InvokeToolAction("ReloadRequest");
        return false;
    end

    return true;
end

function treePackage.LaunchGrenades(npcClass: NpcClass)
    local properties = npcClass.Properties;
    properties.GrenadeLauncherCooldown = tick();

    local toolHandler: ToolHandlerInstance? = npcClass.WieldComp.ToolHandler;
    if toolHandler == nil then return; end;

    npcClass.Move:SetMoveSpeed("set", "shootingstop", 0, npcClass.Move.MoveSpeedPriority.Action, 5);

    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    local destructiblesModelsList = CollectionService:GetTagged("DestructibleModels");
    local explosiveBarrels = {};
    for _, obj in pairs(destructiblesModelsList) do
        if obj:GetAttribute("HostileDestructible") == nil then continue end;
        table.insert(explosiveBarrels, obj);
    end

    for a=-1, 1 do
        task.wait(0.3);

        npcClass.Move:Face(enemyNpcClass.RootPart, nil, 3);

        local targetCf = enemyNpcClass.RootPart.CFrame;
        
        if #explosiveBarrels > 0 then
            local closestBarrel, closestDist = nil, math.huge;
            for _, barrel in pairs(explosiveBarrels) do
                local dist = (barrel:GetPivot().Position - targetCf.Position).Magnitude;
                if dist < closestDist then
                    closestBarrel = barrel;
                    closestDist = dist;
                end
            end
            if closestBarrel and closestDist <= 16 then
                targetCf = closestBarrel:GetPivot();
            end
        end

        local tarPos = targetCf.Position;
        local tarDir = (tarPos - npcClass.RootPart.Position).Unit;

        if a ~= 0 then
            tarDir = ((tarPos + tarDir * a *3) - npcClass.RootPart.Position).Unit;
        end

        npcClass.WieldComp:InvokeToolAction("PrimaryFireRequest", tarDir);
    end
end


return treePackage;