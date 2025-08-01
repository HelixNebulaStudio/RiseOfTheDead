local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local treePackage = {
    LogicString = {
        Default = "HasEnemy & EquipWeapon & AlertTree | IdleTree";
        AlertTree = "IsUsingMelee & MeleeTree | RangeTree";
        MeleeTree = "InMeleeRange & [SwingMelee] | [RunToMeleeRange]";
        RangeTree = "CanFireGun & (RunToFireRange & [FireGun]) | (RunToCover & [ReloadGun])";
        IdleTree = "SelfHealTree | [Patrol]";
        SelfHealTree = "IsHurt & [SelfHeal]";
    };
}

function treePackage.HasEnemy(npcClass: NpcClass)
    local targetHandlerComp = npcClass:GetComponent("TargetHandler");
    if targetHandlerComp == nil then return false; end;

    local enemyTargetData = targetHandlerComp:MatchFirstTarget(function(targetData)
        if targetData.HealthComp == nil then return end;
        local targetNpcClass: NpcClass = targetData.HealthComp.CompOwner;

        local isAlive = targetNpcClass.HealthComp.IsDead ~= true;
        local isInVision = npcClass:IsInVision(targetNpcClass.RootPart);
        local woundedStatus = targetNpcClass.StatusComp:GetOrDefault("Wounded");

        return isAlive and isInVision and not woundedStatus;
    end);
    npcClass.Properties.EnemyTargetData = enemyTargetData;
    
    return enemyTargetData ~= nil;
end

function treePackage.EquipWeapon(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;
    local equipmentClass: EquipmentClass? = wieldComp.EquipmentClass;
    if equipmentClass and (equipmentClass.Class == "Gun" or equipmentClass.Class == "Melee") then 
        return true;
    end;

    local primaryWeaponItemId = npcClass.Properties.PrimaryWeaponItemId;
    wieldComp:Equip{
        ItemId = primaryWeaponItemId;
        OnSuccessFunc = npcClass.Binds.EquipSuccessFunc;
    };

    return true;
end

function treePackage.IsUsingMelee(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;
    if wieldComp.EquipmentClass and wieldComp.EquipmentClass.Class == "Melee" then return true end;
    return false;
end

function treePackage.InMeleeRange(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    return enemyTargetData.Distance <= 10;
end

function treePackage.RunToMeleeRange(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    npcClass.Move:SetMoveSpeed("set", "sprint", 18, 2, 5);
    npcClass.Move:Follow(enemyNpcClass.RootPart, 2);
end


function treePackage.SwingMelee(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;

    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    npcClass.Move:HeadTrack(enemyNpcClass.RootPart, 2);
    npcClass.Move:Face(enemyNpcClass.RootPart.Position);

    wieldComp:InvokeToolAction("PrimarySwingRequest");
end

function treePackage.CanFireGun(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;
    if wieldComp.EquipmentClass == nil then return false end;
    if wieldComp.EquipmentClass.Properties.Ammo <= 0 then return false end;

    return true;
end

function treePackage.RunToFireRange(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    npcClass.Move:SetMoveSpeed("set", "sprint", 14, 2, 5);
    npcClass.Move:Follow(enemyNpcClass.RootPart, 16, 24);

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
    
    if not npcClass:IsInVision(enemyTargetData.Model.PrimaryPart, 45) then return end;

    wieldComp:InvokeToolAction(
        "PrimaryFireRequest", 
        shootDirection, 
        enemyNpcClass.Humanoid
    );
end

function treePackage.RunToCover(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    npcClass.Move:SetMoveSpeed("set", "sprint", 18, 2, 5);
    npcClass.Move:Follow(enemyNpcClass.RootPart, 24, 32);

    return true;
end

function treePackage.ReloadGun(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;
    if wieldComp.EquipmentClass == nil then return end;
    
    if wieldComp.EquipmentClass.Class == "Gun" 
    and wieldComp.EquipmentClass.Properties.MaxAmmo <= 0 then

        wieldComp:Equip{
            ItemId = "machete";
            OnSuccessFunc = npcClass.Binds.EquipSuccessFunc;
        };
        return;
    end

    wieldComp:InvokeToolAction("ReloadRequest");
end

function treePackage.IsHurt(npcClass: NpcClass)
    local healthComp: HealthComp = npcClass.HealthComp;
    return healthComp.CurHealth < healthComp.MaxHealth;
end

function treePackage.SelfHeal(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;

    npcClass.Move:Stop();

    if wieldComp.EquipmentClass == nil or wieldComp.EquipmentClass.ItemId ~= "medkit" then
        wieldComp:Equip{
            ItemId = "medkit";
        };
        
    elseif wieldComp.EquipmentClass.ItemId == "medkit" then
        wieldComp:InvokeToolAction("UseRequest");

    end
end

function treePackage.Patrol(npcClass: NpcClass)
    if npcClass:DistanceFrom(npcClass.SpawnPoint.Position) > 5 then
        npcClass.Move:SetMoveSpeed("set", "walk", 8, 2, 2);
        npcClass.Move:MoveTo(npcClass.SpawnPoint.Position);
    else
        npcClass.Move:Stop();
    end
end

return treePackage;