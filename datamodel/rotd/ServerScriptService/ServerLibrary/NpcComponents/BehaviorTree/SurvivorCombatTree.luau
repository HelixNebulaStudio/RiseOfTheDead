local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local treePackage = {
    LogicString = {
        Default = "HasEnemy & (InMeleeRange & MeleeTree | RangeTree) | UnequipWeapon";
        MeleeTree = "HaveMeleeAndEquip & [SwingMelee]";
        RangeTree = "HaveGunAndEquip & (CanFireGun & [FireGun] | [ReloadGun])";
    }
};

function treePackage.HasEnemy(npcClass: NpcClass)
    local targetHandlerComp = npcClass:GetComponent("TargetHandler");
    if targetHandlerComp == nil then
        return false;
    end
    local properties = npcClass.Properties;

    local enemyTargetData = targetHandlerComp:MatchFirstTarget(function(targetData)
        if targetData.HealthComp == nil then return end;
        local targetNpcClass: NpcClass = targetData.HealthComp.CompOwner;

        if targetNpcClass.HealthComp.IsDead then
            return false;
        end;

        local isEnemy = targetNpcClass.HumanoidType == "Zombie" 
                    or targetNpcClass.HumanoidType == "Cultist"
                    or targetNpcClass.HumanoidType == "Bandit";
        if not isEnemy then
            return false;
        end

        if not npcClass:IsInVision(targetNpcClass.RootPart) then
            return false;
        end

        return true;
    end)
    
    properties.EnemyTargetData = enemyTargetData;
    if enemyTargetData == nil then 

        if npcClass.Properties.IsProtectingPlayer then
            npcClass.BehaviorTree:RunTree("FollowPlayer", false);
        end
        
        return false;
    end;

    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;
    local enemyStatusComp: StatusComp = enemyNpcClass.StatusComp;
    if enemyStatusComp:GetOrDefault("Wounded") then return false end;

    npcClass.Properties.Cache.NextRestTick = nil;
    return true;
end

function treePackage.InMeleeRange(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    if enemyTargetData.Distance <= 20 then
        npcClass.Move:SetMoveSpeed("set", "sprint", 18, 2, 5);
        npcClass.Move:Follow(enemyNpcClass.RootPart, 2);
        return true;
    end

    npcClass.Move:Follow(enemyNpcClass.RootPart, 16, 24);
    return false;
end

function treePackage.HaveMeleeAndEquip(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;
    if wieldComp.EquipmentClass and wieldComp.EquipmentClass.Class == "Melee" then return true end;
    
    local meleeItemId = npcClass.Properties.MeleeItemId;
    if meleeItemId == nil then return false end;
    if wieldComp.ItemId == meleeItemId then return true end;

    wieldComp:Equip{
        ItemId = meleeItemId;
    };

    return true;
end

function treePackage.SwingMelee(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;

    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    npcClass.Move:HeadTrack(enemyNpcClass.RootPart, 2);
    npcClass.Move:Face(enemyNpcClass.RootPart.Position);

    wieldComp:InvokeToolAction("PrimarySwingRequest");
end

function treePackage.HaveGunAndEquip(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;
    if wieldComp.EquipmentClass and wieldComp.EquipmentClass.Class == "Gun" then return true end;

    local primaryGunItemId = npcClass.Properties.PrimaryGunItemId;
    if primaryGunItemId == nil then return false end;

    wieldComp:Equip{
        ItemId = primaryGunItemId;
    };

    return true;
end

function treePackage.CanFireGun(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;
    if wieldComp.EquipmentClass == nil then return false end;
    if wieldComp.EquipmentClass.Properties.Ammo <= 0 then return false end;

    return true;
end

function treePackage.FireGun(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;
    
    local enemyTargetData = npcClass.Properties.EnemyTargetData;

    local healthComp: HealthComp = enemyTargetData.HealthComp;
    local enemyNpcClass: NpcClass = healthComp.CompOwner;

    npcClass.Move:HeadTrack(enemyNpcClass.RootPart, 2);
    npcClass.Move:Face(enemyNpcClass.RootPart.Position);

    local shootDirection = (enemyNpcClass.RootPart.Position - npcClass.RootPart.Position).Unit;
    
    wieldComp:InvokeToolAction(
        "PrimaryFireRequest", 
        shootDirection, 
        enemyNpcClass.Humanoid
    );
end

function treePackage.ReloadGun(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;
    if wieldComp.EquipmentClass == nil then return end;

    wieldComp:InvokeToolAction("ReloadRequest");
end

function treePackage.UnequipWeapon(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;

    if npcClass.Properties.IsProtectingPlayer then 
        wieldComp:InvokeToolAction("ToggleIdle", true);
        return false;
    end;

    if wieldComp.EquipmentClass == nil then return false; end;
    if wieldComp.EquipmentClass.Class == "Gun" or wieldComp.EquipmentClass.Class == "Melee" then
        wieldComp:Unequip();
    end

    return false;
end

return treePackage;