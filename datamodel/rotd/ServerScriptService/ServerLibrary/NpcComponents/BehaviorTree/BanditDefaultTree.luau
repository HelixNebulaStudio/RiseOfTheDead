local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

local TALK_ANIMATIONS = {"nodyes"; "nodno"; "shrug2"; "laugh"; "point"; "bored"; "PullLever"};

local treePackage = {
    LogicString = {
        Default = "HasEnemy & ShareIntel & EquipWeapon & AlertTree | IdleTree";
        AlertTree = "IsUsingMelee & MeleeTree | RangeTree";
        MeleeTree = "InMeleeRange & [SwingMelee] | [RunToMeleeRange]";
        RangeTree = "CanFireGun & (RunToFireRange & [FireGun]) | (RunToCover & [ReloadGun])";
        IdleTree = "SelfHealTree | PatrolTree";
        SelfHealTree = "IsHurt & [SelfHeal]";
        PatrolTree = "ConverseTree | [Patrol]";
        ConverseTree = "ShareIntel & IsSpokenTo & [Converse]";
    };
};

function treePackage.HasEnemy(npcClass: NpcClass)
    local targetHandlerComp = npcClass:GetComponent("TargetHandler");
    if targetHandlerComp == nil then return false; end;

    if npcClass.HealthComp.LastDamagedBy then
        npcClass.Properties.IsHostile = true;
    end

    local enemyTargetData: NpcTargetData? = targetHandlerComp:MatchFirstTarget(function(targetData: NpcTargetData)
        if targetData.HealthComp == nil then return end;
        local targetNpcClass: NpcClass = targetData.HealthComp.CompOwner;

        local isAlive = targetNpcClass.HealthComp.IsDead ~= true;
        if not isAlive then return false; end;

		local canDamage = targetNpcClass.HealthComp:CanTakeDamageFrom(npcClass);
		if not canDamage then return false; end;
        
        local woundedStatus = targetNpcClass.StatusComp:GetOrDefault("Wounded");
        if woundedStatus then return false; end;

        if npcClass.HealthComp.LastDamagedBy == targetNpcClass then return true; end;

        local isTargetPlayer = targetNpcClass.HumanoidType == "Player";
        local isHostile = npcClass.Properties.IsHostile == true;
        if isTargetPlayer and not isHostile then return false; end;

        local visionTarget = targetNpcClass.Head;
        if targetNpcClass.Properties.IsCrouching then
            visionTarget = targetNpcClass.RootPart;
        end

        local isInVision = npcClass:IsInVision(visionTarget, 75);
        if not isInVision then return false; end;

        return true;
    end);

    if npcClass.Properties.EnemyTargetData then
        local oldEnemyTargetData = npcClass.Properties.EnemyTargetData;
        local oldEnemyHealthComp: HealthComp = oldEnemyTargetData.HealthComp

        if math.random(1, 4) == 1 
        and oldEnemyHealthComp.IsDead and oldEnemyHealthComp.LastDamageTaken+2 < tick() then
            local killPhrases = npcClass.NpcPackage.Chatter.KillPhrases;
            local enemyHumanoidType = oldEnemyHealthComp.CompOwner.HumanoidType;

            local filteredKillPhrases = {};
            for a=1, #killPhrases do
                local killPhrase = killPhrases[a];
                if killPhrase.HumanoidType == nil or killPhrase.HumanoidType == enemyHumanoidType then
                    table.insert(filteredKillPhrases, killPhrase);
                end
            end

            if #filteredKillPhrases > 0 then
                local pickedPhrase = filteredKillPhrases[math.random(1, #filteredKillPhrases)];
                npcClass.Chat(nil, pickedPhrase.Say);
            end;
            
            npcClass.Properties.EnemyTargetData = nil;
        end
        if oldEnemyTargetData ~= enemyTargetData then
            npcClass.Properties.LastAlertShout = nil;
        end
    end
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

    local enemyHealthComp: HealthComp = enemyTargetData.HealthComp;
    local enemyNpcClass: NpcClass = enemyHealthComp.CompOwner;

    npcClass.Move:Face(enemyNpcClass.RootPart, nil, 0.5);
    npcClass.Move:HeadTrack(enemyNpcClass.Head, 2);

    local shootDirection = (enemyNpcClass.RootPart.Position - npcClass.RootPart.Position).Unit;
    
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
    local properties = npcClass.Properties;

    properties.LastAlertShout = nil;
    
    if math.random(1, 100) == 1 
    and not npcClass.Move:IsAtPosition(npcClass.SpawnPoint.Position) and npcClass.Properties.SpokeByMeData == nil then
        npcClass.Move:SetMoveSpeed("set", "walk", 8, 2, 2);
        npcClass.Move:MoveTo(npcClass.SpawnPoint.Position);

    else
        npcClass.Move:Stop();

        if math.random(1, 20) == 1 
        and npcClass.Properties.SpokeByMeData == nil 
        and (properties.PassiveTalkCooldown == nil or tick() > properties.PassiveTalkCooldown) then
            properties.PassiveTalkCooldown = tick() + math.random(20, 45);
            if modBranchConfigs.IsWorld("BioXResearch") then
                properties.PassiveTalkCooldown = tick() + 15;
            end

            local patrolConverse = npcClass.NpcPackage.Chatter.PatrolConverse;
            local pickedDialogue = patrolConverse[math.random(1, #patrolConverse)];
            if pickedDialogue then
                local nearbyBanditTargetData: NpcTargetData? = npcClass:GetComponent("TargetHandler"):MatchFirstTarget(function(targetData: NpcTargetData)
                    if targetData.HealthComp == nil then return end;
                    local targetNpcClass: NpcClass = targetData.HealthComp.CompOwner;
                    if targetNpcClass == npcClass then return false; end;

                    if targetNpcClass.HumanoidType ~= "Bandit" then return false; end;
                    if targetNpcClass.HealthComp.IsDead then return false; end;
                    if targetNpcClass.Properties.EnemyTargetData then return false; end;
                    if targetNpcClass.Properties.SpokeByMeData then return false; end;
                    if targetNpcClass.Properties.SpokenToMeData then return false; end;
                    if targetData.Distance > 20 then return false; end;
                    if not npcClass:IsInVision(targetNpcClass.RootPart) then return false; end;

                    return true;
                end)

                if nearbyBanditTargetData then
                    local targetNpcClass: NpcClass = nearbyBanditTargetData.HealthComp.CompOwner;

                    npcClass.Properties.SpokeByMeData = {
                        NpcClass = targetNpcClass;
                        Tick = tick();
                        Dialogue = pickedDialogue;
                    };

                    if nearbyBanditTargetData.Distance > 10 then
                        npcClass.Move:SetMoveSpeed("set", "walk", 8, 2, 3);

                        local dir = (targetNpcClass.RootPart.Position - npcClass.RootPart.Position).Unit;
                        npcClass.Move:MoveTo(npcClass.RootPart.Position + (dir * 8));
                    end
                    npcClass.Move:HeadTrack(targetNpcClass.Head, 5);
                    npcClass.Chat(nil, pickedDialogue.Say);

                    local aniList = pickedDialogue.SayAnimations or TALK_ANIMATIONS;
                    npcClass.PlayAnimation(aniList[math.random(1, #aniList)]);

                    targetNpcClass.Properties.SpokenToMeData = {
                        NpcClass = npcClass;
                        Tick = tick();
                        Dialogue = pickedDialogue;
                    };
                    targetNpcClass.OnThink:Fire();
                end
            end
        end

    end
end

--MARK: Social behavior

-- Share intel of enemies
function treePackage.ShareIntel(npcClass: NpcClass)
    local properties = npcClass.Properties;

    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData and enemyTargetData.HealthComp.CompOwner or nil;

    if properties.SpokenToMeData and properties.SpokenToMeData.NpcClass and enemyNpcClass then
        local allyNpcClass: NpcClass = properties.SpokenToMeData.NpcClass;
        allyNpcClass.Move:Face(enemyNpcClass.RootPart);

        properties.SpokenToMeData = nil;
    end

    if properties.SpokeByMeData and properties.SpokeByMeData.NpcClass then
        local targetNpcClass: NpcClass = properties.SpokeByMeData.NpcClass;

        if targetNpcClass.HealthComp.IsDead ~= true then
            if targetNpcClass and enemyNpcClass then -- I have enemy
                targetNpcClass.Move:Face(enemyNpcClass.RootPart);

                if targetNpcClass.RootPart then
                    npcClass.Move:Face(targetNpcClass.RootPart);
                end
            end
            if targetNpcClass and targetNpcClass.Properties.EnemyTargetData then
                local enemyTargetDataFromTarget = targetNpcClass.Properties.EnemyTargetData;
                local enemyNpcClassFromTarget: NpcClass = enemyTargetDataFromTarget.HealthComp.CompOwner;

                if enemyNpcClassFromTarget and enemyNpcClassFromTarget.RootPart then
                    npcClass.Move:Face(enemyNpcClassFromTarget.RootPart);
                end
            end
        end
    end

    local targetHandlerComp = npcClass:GetComponent("TargetHandler");
    if enemyNpcClass and (properties.LastAlertShout == nil or tick()-properties.LastAlertShout > 20) then
        npcClass.Properties.LastAlertShout = tick();

        local allies: {NpcTargetData} = targetHandlerComp:MatchTargets(function(targetData: NpcTargetData)
            if targetData.HealthComp == nil then return end;
            local targetNpcClass: NpcClass = targetData.HealthComp.CompOwner;

            local isAlive = targetNpcClass.HealthComp.IsDead ~= true;
            if not isAlive then return false; end;

            local isBandit = targetNpcClass.HumanoidType == "Bandit";
            if not isBandit then return false; end;

            local isMe = targetNpcClass == npcClass;
            if isMe then return false; end;

            return true;
        end)

        
        if math.random(1, 3) == 1 then
            local alertPhrases = npcClass.NpcPackage.Chatter.AlertPhrases;
            local filteredAlertPhrases = {};
            for a=1, #alertPhrases do
                local alertPhrase = alertPhrases[a];
                if alertPhrase.HumanoidType == nil or alertPhrase.HumanoidType == enemyNpcClass.HumanoidType then
                    table.insert(filteredAlertPhrases, alertPhrase);
                end
            end

            local alertPhrase = filteredAlertPhrases[math.random(1, #filteredAlertPhrases)];
            if alertPhrase then
                npcClass.Chat(nil, alertPhrase.Say);
            end
        end

        for a=1, #allies do
            local targetData: NpcTargetData = allies[a];
            local targetNpcClass: NpcClass = targetData.HealthComp.CompOwner;

            if targetNpcClass.Properties.EnemyTargetData ~= nil then continue end;
            targetNpcClass.Move:HeadTrack(enemyNpcClass.Head, 10);
        end
    end

    return true;
end

function treePackage.IsSpokenTo(npcClass: NpcClass)
    local spokeByMeData = npcClass.Properties.SpokeByMeData;
    if spokeByMeData then
        if tick()-spokeByMeData.Tick > 10 then
            npcClass.Properties.SpokeByMeData = nil;
        end
    end
    
    return npcClass.Properties.SpokenToMeData ~= nil;
end

function treePackage.Converse(npcClass: NpcClass)
    local properties = npcClass.Properties;

    local spokenToMeData = properties.SpokenToMeData;
    local targetNpcClass: NpcClass = spokenToMeData.NpcClass;

    if targetNpcClass.HealthComp.IsDead then
        properties.SpokenToMeData = nil;
        return;
    end

    if spokenToMeData.LastResponseTick then 
        if tick() > spokenToMeData.LastResponseTick then
            properties.SpokenToMeData = nil;
        end
        return;
    end;

    local sayLapse = tick()-spokenToMeData.Tick;
    local sayWords = string.split(spokenToMeData.Dialogue.Say, " ");
    local sayDuration = math.max(#sayWords/1.9, 5);
    if sayLapse <= sayDuration then
        if sayLapse > 1 then
            npcClass.Move:HeadTrack(targetNpcClass.Head, 5);
        end
        return;
    end

    spokenToMeData.LastResponseTick = tick() + math.random(10, 11);
    if modBranchConfigs.IsWorld("BioXResearch") then
        properties.LastResponseTick = tick() + 11;
    end

    npcClass.Move:Face(targetNpcClass.RootPart);
    npcClass.Move:HeadTrack(targetNpcClass.Head, 5);
    npcClass.Chat(nil, spokenToMeData.Dialogue.Reply);

    local aniList = spokenToMeData.Dialogue.ReplyAnimations or TALK_ANIMATIONS;
    npcClass.PlayAnimation(aniList[math.random(1, #aniList)]);
end

return treePackage;