local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local PathfindingService = game:GetService("PathfindingService");
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);
local modTables = shared.require(game.ReplicatedStorage.Library.Util.Tables);

local TALK_ANIMATIONS = {"nodyes"; "nodno"; "shrug2"; "laugh"; "point"; "bored"; "PullLever"};

local treePackage = {
    LogicString = {
        Default = "!InCutscene & DefaultTree | [DoNothing]";
        DefaultTree = "HasEnemy & AlertTree | IdleTree";
        AlertTree = "EquipWeapon & IsInVision & (ShareIntel & IsUsingMelee & MeleeTree | RangeTree) | HuntTree";
        HuntTree = "KnowEnemyLastPosition & (IsAtLastKnownPosition & [InvestigateArea] | [MoveToLastKnownPosition]) | SeekTree";
        SeekTree = "[GuessEnemyLastPosition]";
        MeleeTree = "InMeleeRange & [SwingMelee] | [RunToMeleeRange]";
        RangeTree = "CanFireGun & (RunToFireRange & [FireGun]) | (RunToCover & [ReloadGun])";
        IdleTree = "SelfHealTree | PatrolTree";
        SelfHealTree = "IsHurt & [SelfHeal]";
        PatrolTree = "ConverseTree | [Patrol]";
        ConverseTree = "ShareIntel & IsSpokenTo & [Converse]";
    };
};

function treePackage.InCutscene(npcClass: NpcClass)
    return npcClass.Properties.CutsceneActive == true;
end

function treePackage.HasEnemy(npcClass: NpcClass)
    local properties = npcClass.Properties;

    local targetHandlerComp = npcClass:GetComponent("TargetHandler");
    if targetHandlerComp == nil then return false; end;

    local enemyTargetData: NpcTargetData? = targetHandlerComp:MatchFirstTarget(function(targetData: NpcTargetData)
        if targetData.HealthComp == nil then return end;
        local targetEntityClass: EntityClass = targetData.HealthComp.CompOwner :: EntityClass;

        local isAlive = targetEntityClass.HealthComp.IsDead ~= true;
        if not isAlive then return false; end;

		local canDamage = targetEntityClass.HealthComp:CanTakeDamageFrom(npcClass);
		if not canDamage then return false; end;
        
        if targetEntityClass.ClassName ~= "Destructible" then
            local targetCharacterClass: CharacterClass = (targetEntityClass :: CharacterClass);

            local woundedStatus = targetCharacterClass.StatusComp:GetOrDefault("Wounded");
            if woundedStatus then return false; end;

            if npcClass.HealthComp.LastDamagedBy == targetCharacterClass then
                targetData.IsInVision = true;
                return true;
            end;

            local isTargetPlayer = targetCharacterClass.HumanoidType == "Player";
            local isHostile = properties.IsHostile == true;
            if isTargetPlayer and not isHostile and targetData.Damage <= 0 then 
                return false;
            end;

            local visionTarget = targetCharacterClass.Head;
            if targetCharacterClass.Properties.IsCrouching then
                visionTarget = targetCharacterClass.RootPart;
            end

            local isInVision = npcClass:IsInVision(visionTarget, 75);
            targetData.IsInVision = isInVision;
            if not isInVision then
                if targetData.LastSeenTick and (tick()-targetData.LastSeenTick < properties.LastSeenMemDuration) then
                    return true;
                end
                if targetData.LastKnownPosition and (tick()-targetData.LastAddedTick < properties.LastPosMemDuration) then
                    return true;
                end

                return false;
            end;

            targetData.LastSeenTick = tick();
            targetData.LastKnownPosition = targetCharacterClass:GetCFrame().Position;
        end

        return true;
    end);

    if properties.EnemyTargetData then
        local oldEnemyTargetData = properties.EnemyTargetData;
        local oldEnemyHealthComp: HealthComp = oldEnemyTargetData.HealthComp

        if math.random(1, 4) == 1 
        and oldEnemyHealthComp.IsDead and oldEnemyHealthComp.LastDamageTaken+2 < tick()
        and oldEnemyHealthComp.CompOwner.ClassName ~= "Destructible" then
            local killPhrases = npcClass.NpcPackage.Chatter.KillPhrases;
            local enemyHumanoidType = (oldEnemyHealthComp.CompOwner :: CharacterClass).HumanoidType;

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
            
            properties.EnemyTargetData = nil;
        end

    else
        local wieldComp: WieldComp = npcClass.WieldComp;
        local equipmentClass: EquipmentClass? = wieldComp.EquipmentClass;
        if equipmentClass and (equipmentClass.Class == "Gun" or equipmentClass.Class == "Melee") then 
            wieldComp:Unequip();
        end

    end
    properties.EnemyTargetData = enemyTargetData;
    
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

--MARK: Investigate behavior
function treePackage.IsInVision(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    return enemyTargetData and enemyTargetData.IsInVision == true or false;
end

function treePackage.KnowEnemyLastPosition(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local lastKnownPos = enemyTargetData.LastKnownPosition;

    if lastKnownPos == nil then return false; end;

    return true;
end

function treePackage.IsAtLastKnownPosition(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local lastKnownPos = enemyTargetData.LastKnownPosition;

    local isAtLastKnowPos = modVector.DistanceSqrd(lastKnownPos, npcClass:GetCFrame().Position) < 36; --6 units
    
    if isAtLastKnowPos then
        if properties.ArriveSeekPositionTick == nil or tick()-properties.ArriveSeekPositionTick > 40 then
            properties.ArriveSeekPositionTick = tick();

            npcClass.PlayAnimation("Idle");

            local huntSpeech = npcClass.NpcPackage.Chatter.HuntSpeech;
            local huntPhrase = huntSpeech and huntSpeech[math.random(1, #huntSpeech)] or nil;
            if huntPhrase then
                npcClass.Chat(nil, huntPhrase.Say);
            end
        end
    end
    
    return isAtLastKnowPos;
end

function treePackage.MoveToLastKnownPosition(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local lastKnownPos = enemyTargetData.LastKnownPosition;
    local timeSinceLastAdd = tick()-enemyTargetData.LastAddedTick;
    
    npcClass.Move:MoveTo(lastKnownPos);

    if timeSinceLastAdd <= 10 then
        npcClass.Move:SetMoveSpeed(
            "set", "sprint", properties.SprintSpeed or 18, npcClass.Move.MoveSpeedPriority.Movement, 5);
    end
end

function treePackage.InvestigateArea(npcClass: NpcClass)
    local properties = npcClass.Properties;
    if properties.LastSeekTurnTick == nil or tick() > properties.LastSeekTurnTick then
        properties.LastSeekTurnTick = tick() + math.random(1, 9);

        local lookDir = modVector.RandomUnitVector(2);
        lookDir = Vector3.new(lookDir.X, 0, lookDir.Y);

        npcClass.Move:Face(npcClass:GetCFrame().Position + (lookDir * 100));
    end
end

function treePackage.GuessEnemyLastPosition(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;
    local enemyPosition = enemyTargetData.Model and enemyTargetData.Model:GetPivot().Position or nil;

    if enemyPosition then
        enemyPosition = enemyPosition + Vector3.new(
            math.random(-1, 1) * math.random(20, 40), 
            0, 
            math.random(-1, 1) * math.random(20, 40)
        );
    else
        enemyPosition = npcClass:GetCFrame().Position + Vector3.new(
            math.random(-1, 1) * math.random(40, 100), 
            0, 
            math.random(-1, 1) * math.random(40, 100)
        );
    end

    enemyTargetData.LastKnownPosition = enemyPosition;
end

--MARK: Combat behavior
function treePackage.IsUsingMelee(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;
    if wieldComp.EquipmentClass and wieldComp.EquipmentClass.Class == "Melee" then return true end;
    return false;
end

function treePackage.InMeleeRange(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    return enemyTargetData.Distance <= 6;
end

function treePackage.RunToMeleeRange(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    npcClass.Move:SetMoveSpeed("set", "sprint", properties.SprintSpeed or 18, npcClass.Move.MoveSpeedPriority.Movement, 5);
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
    local properties = npcClass.Properties;
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    npcClass.Move:SetMoveSpeed("set", "sprint", properties.SprintSpeed or 14, npcClass.Move.MoveSpeedPriority.Movement, 5);
    npcClass.Move:Follow(enemyNpcClass.RootPart, 16, 24);

    return true;
end

function treePackage.FireGun(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;
    
    local enemyTargetData = npcClass.Properties.EnemyTargetData;

    local enemyHealthComp: HealthComp = enemyTargetData.HealthComp;
    local enemyNpcClass: EntityClass = enemyHealthComp.CompOwner :: EntityClass;

    npcClass.Move:Face(enemyNpcClass.RootPart, nil, 0.5);
    npcClass.Move:HeadTrack((enemyNpcClass :: CharacterClass).Head, 2);

    local shootDirection = (enemyNpcClass.RootPart.Position - npcClass.RootPart.Position).Unit;
    
    wieldComp:InvokeToolAction(
        "PrimaryFireRequest", 
        shootDirection, 
        (enemyNpcClass :: CharacterClass).Humanoid
    );
end

function treePackage.RunToCover(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    npcClass.Move:SetMoveSpeed("set", "sprint", properties.SprintSpeed or 18, npcClass.Move.MoveSpeedPriority.Movement, 5);
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
    
    local patrolPositions = properties.PatrolPositions;
    if patrolPositions == nil then
        patrolPositions = {};
        properties.PatrolPositions = patrolPositions;
        properties.PatrolIndex = 1;

        task.spawn(function() 
            local curPos = npcClass:GetCFrame().Position;

            local patrolRng = Random.new(math.floor(curPos.X) + math.floor(curPos.Y) + math.floor(curPos.Z));

            local path: Path = PathfindingService:CreatePath(npcClass.PathAgent);
            for a=1, patrolRng:NextInteger(5, 9) do
                local startPos = curPos;
                local rngX = patrolRng:NextInteger(-1, 1);
                local rngZ = patrolRng:NextInteger(-1, 1);
                if rngX == 0 and rngZ == 0 then
                    rngZ = 1;
                end
                local endPos = startPos + Vector3.new(
                    rngX * patrolRng:NextInteger(12, 45),
                    0,
                    rngZ * patrolRng:NextInteger(12, 45)
                );

                local rayParams = RaycastParams.new();
                rayParams.IncludeInstances = {workspace.Environment; workspace.Terrain};
                rayParams.IgnoreWater = true;

                local floorRayResult = workspace:Blockcast(CFrame.new(endPos + Vector3.new(0, 6, 0)), Vector3.one*2, Vector3.yAxis*-10, rayParams);
                if floorRayResult == nil then Debugger:Warn("Patrol no floor"); continue end;
                endPos = floorRayResult.Position + Vector3.new(0, 1.35, 0);

                local pathS, pathE = pcall(function()
                    path:ComputeAsync(startPos, endPos)
                end)
                if not pathS then Debugger:Warn("Patrol pathE", pathE); continue end;
                if path.Status ~= Enum.PathStatus.Success then Debugger:Warn("Patrol no path", path.Status); continue end;

                local wayPoints = path:GetWaypoints();
                for _, waypoint: PathWaypoint in pairs(wayPoints) do
                    if waypoint.Action ~= Enum.PathWaypointAction.Walk then continue end;

                    local waypointPos = waypoint.Position;
                    table.insert(patrolPositions, waypointPos);
                end

                break;
            end
        end)
    end

    local patrolFrequency = properties.IsHostile and 30 or 60;
    if math.random(1, 100) == 1 
    and npcClass.Properties.SpokeByMeData == nil
    and #patrolPositions <= 0 
    and not npcClass.Move:IsAtPosition(npcClass.SpawnCFrame.Position) then
        -- Walk back to spawn;
        npcClass.Move:MoveTo(npcClass.SpawnCFrame.Position);

    elseif math.random(1, patrolFrequency) == 1 
    and npcClass.Properties.SpokeByMeData == nil
    and #patrolPositions > 0 then
        -- Walk to random spot;
        local patrolPos = patrolPositions[properties.PatrolIndex];
        if not npcClass.Move:IsAtPosition(patrolPos) then
            npcClass.Move:MoveTo(patrolPos);

        else
            properties.PatrolIndex +=1;
            if properties.PatrolIndex > #patrolPositions then
                modTables.Reverse(patrolPositions);
                properties.PatrolIndex = 1;
            end

            patrolPos = patrolPositions[properties.PatrolIndex];
            npcClass.Move:MoveTo(patrolPos);
        end
        
    else
        -- Converse
        
        if math.random(1, 20) == 1 
        and npcClass.Properties.SpokeByMeData == nil 
        and (properties.PassiveTalkCooldown == nil or tick() > properties.PassiveTalkCooldown) then
            properties.PassiveTalkCooldown = tick() + math.random(20, 45);
            if modBranchConfigurations.IsWorld("BioXResearch") then
                properties.PassiveTalkCooldown = tick() + 15;
            end

            local patrolConverse = npcClass.NpcPackage.Chatter.PatrolConverse;
            local pickedDialogue = patrolConverse and patrolConverse[math.random(1, #patrolConverse)] or nil;
            if pickedDialogue then
                local nearbyAllyTargetData: NpcTargetData? = npcClass:GetComponent("TargetHandler"):MatchFirstTarget(function(targetData: NpcTargetData)
                    if targetData.HealthComp == nil then return end;
                    local targetNpcClass: NpcClass = targetData.HealthComp.CompOwner :: NpcClass;
                    if targetNpcClass == npcClass then return false; end;
                    if targetNpcClass.ClassName ~= "NpcClass" then return false; end;

                    if targetNpcClass.HumanoidType ~= npcClass.HumanoidType then return false; end;
                    if targetNpcClass.HealthComp.IsDead then return false; end;
                    if targetNpcClass.Properties.EnemyTargetData then return false; end;
                    if targetNpcClass.Properties.SpokeByMeData then return false; end;
                    if targetNpcClass.Properties.SpokenToMeData then return false; end;
                    if targetData.Distance > 20 then return false; end;
                    if not npcClass:IsInVision(targetNpcClass.RootPart) then return false; end;

                    return true;
                end)

                if nearbyAllyTargetData then
                    npcClass.Move:Stop();

                    local targetNpcClass: NpcClass = nearbyAllyTargetData.HealthComp.CompOwner :: NpcClass;

                    npcClass.Properties.SpokeByMeData = {
                        NpcClass = targetNpcClass;
                        Tick = tick();
                        Dialogue = pickedDialogue;
                    };

                    if nearbyAllyTargetData.Distance > 10 then
                        npcClass.Move:SetMoveSpeed("set", "walk", properties.WalkSpeed or 8, npcClass.Move.MoveSpeedPriority.Movement, 3);

                        local dir = (targetNpcClass:GetCFrame().Position - npcClass:GetCFrame().Position).Unit;
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

    if npcClass.Move.IsMoving then
        npcClass.Move:SetMoveSpeed("set", "walk", properties.WalkSpeed or 8, npcClass.Move.MoveSpeedPriority.Movement, 2);
    end

end

--MARK: Social behavior

-- Share intel of enemies
function treePackage.ShareIntel(npcClass: NpcClass)
    local properties = npcClass.Properties;

    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;
    local enemyEntityClass: EntityClass? = enemyTargetData and (enemyTargetData.HealthComp.CompOwner :: EntityClass) or nil;

    if properties.SpokenToMeData and properties.SpokenToMeData.NpcClass and enemyEntityClass then
        local allyNpcClass: NpcClass = properties.SpokenToMeData.NpcClass;
        allyNpcClass.Move:Face(enemyEntityClass.RootPart);

        properties.SpokenToMeData = nil;
    end

    if properties.SpokeByMeData and properties.SpokeByMeData.NpcClass then
        local targetNpcClass: NpcClass = properties.SpokeByMeData.NpcClass;

        if targetNpcClass.HealthComp.IsDead ~= true then
            if targetNpcClass and enemyEntityClass then -- I have enemy
                targetNpcClass.Move:Face(enemyEntityClass.RootPart);

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
    if enemyEntityClass and (properties.LastAlertShout == nil or tick()-properties.LastAlertShout > 20) then
        npcClass.Properties.LastAlertShout = tick();

        local allies: {NpcTargetData} = targetHandlerComp:MatchTargets(function(allyTargetData: NpcTargetData)
            if allyTargetData.HealthComp == nil then return end;
            local allyNpcClass: NpcClass = allyTargetData.HealthComp.CompOwner :: NpcClass;
            if allyNpcClass.ClassName ~= "NpcClass" then return end;

            local isAlive = allyNpcClass.HealthComp.IsDead ~= true;
            if not isAlive then return false; end;

            local isAlly = allyNpcClass.HumanoidType == npcClass.HumanoidType;
            if not isAlly then return false; end;

            local isMe = allyNpcClass == npcClass;
            if isMe then return false; end;

            return true;
        end)

        
        if math.random(1, 3) == 1 then
            local alertPhrases = npcClass.NpcPackage.Chatter.AlertPhrases;
            local filteredAlertPhrases = {};
            for a=1, #(alertPhrases or {}) do
                local alertPhrase = alertPhrases[a];
                if alertPhrase.HumanoidType == nil 
                or alertPhrase.HumanoidType == (enemyEntityClass :: CharacterClass).HumanoidType then
                    table.insert(filteredAlertPhrases, alertPhrase);
                end
            end

            local alertPhrase = #filteredAlertPhrases >0 and filteredAlertPhrases[math.random(1, #filteredAlertPhrases)] or nil;
            if alertPhrase then
                npcClass.Chat(nil, alertPhrase.Say);
            end
        end

        for a=1, #allies do
            local allyTargetData: NpcTargetData = allies[a];
            local allyNpcClass: NpcClass = allyTargetData.HealthComp.CompOwner :: NpcClass;
            if allyNpcClass.HealthComp.IsDead then continue end;

            local allyActiveEnemyTargetData: NpcTargetData = allyNpcClass.Properties.EnemyTargetData;
            if allyActiveEnemyTargetData == nil then
                local allyTargetHandlerComp = allyNpcClass:GetComponent("TargetHandler");
                if allyTargetHandlerComp then
                    local targetData = allyTargetHandlerComp:AddTarget(enemyEntityClass.Character);
                    if targetData then
                        targetData.LastKnownPosition = enemyEntityClass:GetCFrame().Position;
                    end
                end

            elseif allyActiveEnemyTargetData.HealthComp == enemyEntityClass.HealthComp then
                allyActiveEnemyTargetData.LastKnownPosition = enemyTargetData.LastKnownPosition;
                allyActiveEnemyTargetData.LastAddedTick = tick();
                allyActiveEnemyTargetData.LastSeenTick = (tick()-3);

            end

            allyNpcClass.Move:Face(enemyEntityClass:GetCFrame().Position);
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
    if modBranchConfigurations.IsWorld("BioXResearch") then
        properties.LastResponseTick = tick() + 11;
    end

    npcClass.Move:Face(targetNpcClass.RootPart);
    npcClass.Move:HeadTrack(targetNpcClass.Head, 5);
    npcClass.Chat(nil, spokenToMeData.Dialogue.Reply);

    local aniList = spokenToMeData.Dialogue.ReplyAnimations or TALK_ANIMATIONS;
    npcClass.PlayAnimation(aniList[math.random(1, #aniList)]);
end

function treePackage.DoNothing(npcClass: NpcClass)
    return true;
end

return treePackage;