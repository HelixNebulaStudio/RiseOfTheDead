local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);

local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);
local modTables = shared.require(game.ReplicatedStorage.Library.Util.Tables);

local TALK_ANIMATIONS = {"nodyes"; "nodno"; "shrug2"; "laugh"; "point"; "bored"; "PullLever"};

local treePackage = {
    LogicString = {
        Default = "PreLogic | !InCutscene & (InVehicle & VehicleTree | GroundTree) | [DoNothing]";

        
        GroundTree = "HasEnemy & (FleeTree | AlertTree) | IdleTree";
        AlertTree = "EquipWeapon & IsInVision & (ShareIntel & IsUsingMelee & MeleeTree | RangeTree) | HuntTree";
        HuntTree = "KnowEnemyLastPosition & (IsAtLastKnownPosition & [InvestigateArea] | [MoveToLastKnownPosition]) | SeekTree";
        SeekTree = "GuessEnemyLastPosition";
        MeleeTree = "InMeleeRange & [SwingMelee] | [RunToMeleeRange]";
        RangeTree = "CanFireGun & (RunToFireRange & [FireGun]) | (RunToCover & [ReloadGun])";

        IdleTree = "IdleUpdate | (HasDistraction & CheckDistraction) | ZarkTree | DeadbodyReaction | SelfHealTree | IdleInteractTree | PatrolTree";
        ZarkTree = "IsZarkNear & GreetZark";
        SelfHealTree = "IsHurt & [SelfHeal]";
        IdleInteractTree = "CanIdleInteract & DoIdleInteract";
        PatrolTree = "ConverseTree | [Patrol]";
        ConverseTree = "ShareIntel & IsSpokenTo & [Converse]";
        FleeTree = "!CanEquip & [Flee]";


        VehicleTree = "[DoNothing]";
    };

    OnAlertShout = shared.EventSignal.new("BanditOnAlertShout");
    AlertShoutQuota = 3;
    AlertShoutRefreshTick = tick();

    SharedInteractablesInUse = {};
};

function treePackage.PreLogic(npcClass: NpcClass)
    local processStatusesComp = npcClass:GetComponent("ProcessStatuses");
    if processStatusesComp then
        return processStatusesComp();
    end
    
    return false;
end

function treePackage.InCutscene(npcClass: NpcClass)
    return npcClass.Properties.CutsceneActive == true;
end

function treePackage.InVehicle(npcClass: NpcClass)
    return npcClass.Properties.IsOnVehicle == true;
end

function treePackage.HasEnemy(npcClass: NpcClass)
    local properties = npcClass.Properties;

    local targetHandlerComp = npcClass:GetComponent("TargetHandler");
    if targetHandlerComp == nil then return false; end;

    local myPos = npcClass:GetCFrame().Position;

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

            local disguisedStatus: StatusClassInstance = targetCharacterClass.StatusComp:GetOrDefault("Disguised");
            
            if not npcClass.HealthComp.IsDead and npcClass.HealthComp.LastDamagedBy == targetCharacterClass then
                targetData.IsInVision = true;
                targetData.LastAlertedTick = tick();

                if disguisedStatus then
                    properties.DangerDisguiseId = disguisedStatus.Values.DisguiseId;
                end

                return true;
            end;

            local isZark = targetCharacterClass.Name == "Zark";
            
            local isFriendlyDisguise = disguisedStatus and disguisedStatus.Values.DistractionType == "Friendly";
            if isZark
            or isFriendlyDisguise and disguisedStatus.Values.Name == "Zark" then
                properties.ZarkCharacterClass = targetCharacterClass;
            end

            local deadbodyData = properties.SeenDeadbodyData;

            local isTargetPlayer = targetCharacterClass.HumanoidType == "Player";
            local isHostile = properties.IsHostile == true;
            if isTargetPlayer and not isHostile and targetData.Damage <= 0 and deadbodyData == nil then 
                return false;
            end;

            if isFriendlyDisguise and properties.DangerDisguiseId ~= disguisedStatus.Values.DisguiseId then
                return false;
            end

            local targetProperties = targetCharacterClass.Properties;

            local visionTarget = targetCharacterClass.Head;
            if targetProperties.IsCrouching 
            or (targetProperties.LastIsCrouching and tick()-targetProperties.LastIsCrouching <= 0.3)
            or targetProperties.IsSliding
            or (targetProperties.LastIsSliding and tick()-targetProperties.LastIsSliding <= 0.5) then
                visionTarget = targetCharacterClass.RootPart;
            end

            local tarPos = targetCharacterClass:GetCFrame().Position;
            local isInVision = npcClass:IsInVision(visionTarget, 75) and not npcClass.HealthComp.IsDead;
            local isHostileDisguise = disguisedStatus and disguisedStatus.Values.DistractionType == "Hostile";

            if not isInVision and (targetCharacterClass.HumanoidType == "Zombie" or isHostileDisguise) then
                if modVector.distanceSqrdXZ(tarPos, myPos) <= 200 --14^2
                and math.abs(tarPos.Y-myPos.Y) <= 7 then
                    isInVision = true;
                end
            end 

            local isKillerOfDeadbody = deadbodyData and deadbodyData.KillerCharacter == targetData.Model;

            local isInanimateDisguise = disguisedStatus and disguisedStatus.Values.DistractionType == "Inanimate";
            if isInanimateDisguise and disguisedStatus then
                if isInVision then
                    if (tick() - (targetCharacterClass :: PlayerClass).LastCharacterMoved) <= 10 then
                        if properties.Distraction == nil then
                            properties.Distraction = {};
                        end
                        properties.Distraction.Tick = tick();
                        local dir = (tarPos - myPos).Unit; 
                        properties.Distraction.Position = tarPos - (dir*4);
                        properties.Distraction.Disguise = disguisedStatus.Values.Name;
                    end

                    if isKillerOfDeadbody and tick()-deadbodyData.SeenTick <= 1 then
                        properties.DangerDisguiseId = disguisedStatus.Values.DisguiseId;
                        targetData.IsInVision = true;
                        targetData.LastAlertedTick = tick();

                        return true;
                    else
                        isInVision = false;
                    end
                end
                
            end

            targetData.IsInVision = isInVision;
            if not isInVision then

                local npcCombatComp = targetCharacterClass:GetComponent("NpcCombat");
                if npcCombatComp then
                    return npcCombatComp:CanBeFaughtBy(npcClass);
                end

                if targetData.LastSeenTick and (tick()-targetData.LastSeenTick < properties.LastSeenMemDuration) then
                    return true;
                end
                if targetData.LastKnownPosition and (tick()-targetData.LastAddedTick < properties.LastPosMemDuration) then
                    return true;
                end

                return false;
            end;

        else
            -- Is Destructible
            targetData.IsInVision = true;
            
        end

        properties.CanDistract = false;
        targetData.LastSeenTick = tick();
        targetData.LastAlertedTick = tick();
        targetData.LastKnownPosition = targetEntityClass:GetCFrame().Position;

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
    
    local hasEnemy = enemyTargetData ~= nil;

    npcClass.Character:SetAttribute("LookAtClient", enemyTargetData 
        and enemyTargetData.LastAlertedTick 
        and enemyTargetData.HealthComp
        and enemyTargetData.HealthComp.CompOwner
        and enemyTargetData.HealthComp.CompOwner.ClassName == "PlayerClass" or false);
        
    return hasEnemy;
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

    local enemyEntityClass: EntityClass = enemyTargetData.HealthComp.CompOwner;
    if enemyEntityClass.ClassName == "PlayerClass" then
        local npcCombatComp = (enemyEntityClass :: PlayerClass):GetComponent("NpcCombat");
        if npcCombatComp then
            return npcCombatComp:CanBeFaughtBy(npcClass);
        end
    end

    return true;
end

function treePackage.IsAtLastKnownPosition(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local lastKnownPos = enemyTargetData.LastKnownPosition;

    local isAtLastKnowPos = modVector.DistanceSqrd(lastKnownPos, npcClass:GetCFrame().Position) < 36; --6 units
    
    if isAtLastKnowPos then
        if (properties.ArriveSeekPositionTick == nil or tick()-properties.ArriveSeekPositionTick > 40) then
            properties.ArriveSeekPositionTick = tick();

            npcClass.PlayAnimation("Idle");
            npcClass:GetComponent("NpcEmote"){
                Players = game.Players:GetPlayers();
                EmoteId = "question";
            };

            if math.random(1, 6) == 1 then
                local huntSpeech = npcClass.NpcPackage.Chatter.HuntSpeech;
                local huntPhrase = huntSpeech and huntSpeech[math.random(1, #huntSpeech)] or nil;
                if huntPhrase then
                    npcClass.Chat(nil, huntPhrase.Say);
                end
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
    local enemyTargetData = npcClass.Properties.EnemyTargetData;

    if properties.LastSeekTurnTick == nil or tick() > properties.LastSeekTurnTick then
        properties.LastSeekTurnTick = tick() + math.random(1, 9);

        local lookDir = modVector.RandomUnitVector(2);
        lookDir = Vector3.new(lookDir.X, 0, lookDir.Y);

        npcClass.Move:Face(npcClass:GetCFrame().Position + (lookDir * 100));
    end

    if enemyTargetData then
        enemyTargetData.LastKnownPosition = nil;
    end
end

function treePackage.GuessEnemyLastPosition(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;
    local enemyPosition = enemyTargetData.Model and enemyTargetData.Model:GetPivot().Position or nil;

    if enemyTargetData.LastAlertedTick == nil then
        return false;

    elseif properties.LastGuessTick == nil or tick() > properties.LastGuessTick then
        properties.LastGuessTick = tick() + math.random(3, 12);

        local moveDir = Vector3.new(
            math.random(-1, 1) * math.random(5, 15), 
            0, 
            math.random(-1, 1) * math.random(5, 15)
        );

        if enemyPosition then
            local path: Path = npcClass.Move:ComputePath(npcClass:GetCFrame().Position, enemyPosition);
            if path.Status == Enum.PathStatus.Success then
                local waypoints = path:GetWaypoints();
                if #waypoints > 1 then
                    local waypoint: PathWaypoint = waypoints[2];

                    local myPos = npcClass:GetCFrame().Position;
                    local wpPos = Vector3.new(waypoint.Position.X, myPos.Y, waypoint.Position.Z);

                    local newDir = (wpPos - myPos).Unit * math.random(5, 15);
                    if not shared.IsNan(newDir) then
                        moveDir = newDir;
                    end
                end
            end
        end

        enemyTargetData.LastKnownPosition = npcClass:GetCFrame().Position +moveDir;
    end

    return true;
end

--MARK: Combat behavior
function treePackage.IsUsingMelee(npcClass: NpcClass)
    local wieldComp: WieldComp = npcClass.WieldComp;
    if wieldComp.EquipmentClass and wieldComp.EquipmentClass.Class == "Melee" then return true end;
    return false;
end

function treePackage.InMeleeRange(npcClass: NpcClass)
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    return enemyTargetData.Distance <= 4;
end

function treePackage.RunToMeleeRange(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local enemyEntityClass: EntityClass = enemyTargetData.HealthComp.CompOwner;

    npcClass.Move:SetMoveSpeed("set", "sprint", properties.SprintSpeed or 18, npcClass.Move.MoveSpeedPriority.Movement, 5);
    npcClass.Move:Follow(enemyEntityClass.RootPart, 3, 2);
end


function treePackage.SwingMelee(npcClass: NpcClass)
    local properties = npcClass.Properties;
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
    local properties = npcClass.Properties;
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

    local setMs = false;
    if npcClass.Move.IsMoving then
        npcClass.Move:SetMoveSpeed("set", "walk", properties.WalkSpeed or 8, npcClass.Move.MoveSpeedPriority.Movement, 2);
        setMs = true;
    end

    if properties.PatrolCooldownTick and tick() < properties.PatrolCooldownTick then
        return;
    end

    properties.LastAlertShout = tick()-math.random(10, 15);
    
    local patrolPositions = properties.PatrolPositions;
    if patrolPositions == nil then
        patrolPositions = {};
        properties.PatrolPositions = patrolPositions;
        properties.PatrolIndex = 1;

        task.spawn(function() 
            local curPos = npcClass:GetCFrame().Position;

            local patrolRng = Random.new(math.floor(curPos.X) + math.floor(curPos.Y) + math.floor(curPos.Z));

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

                local locationName = npcClass:GetMapLocation(endPos);
                if locationName ~= nil and properties.SpawnLocationName ~= nil
                and properties.SpawnLocationName ~= locationName then
                    Debugger:Warn(`Patrol pos outside spawn location ({properties.SpawnLocationName}) ~= {locationName}`);
                    continue;
                end

                local rayParams = RaycastParams.new();
                rayParams.IncludeInstances = {workspace.Environment; workspace.Terrain};
                rayParams.IgnoreWater = true;

                local floorRayResult = workspace:Blockcast(CFrame.new(endPos + Vector3.new(0, 6, 0)), Vector3.one*2, Vector3.yAxis*-10, rayParams);
                if floorRayResult == nil then continue end;
                endPos = floorRayResult.Position + Vector3.new(0, 1.35, 0);

                local path: Path = npcClass.Move:ComputePath(startPos, endPos);
                if path.Status ~= Enum.PathStatus.Success then continue end;

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

    local patrolFrequency = properties.PatrolFrequency or (properties.IsHostile and 30 or 60);

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

        if properties.PatrolIndex == nil then properties.PatrolIndex = 1; end;
        local patrolPos = patrolPositions[properties.PatrolIndex];

        if not npcClass.Move:IsAtPosition(patrolPos) then
            npcClass.Move:MoveTo(patrolPos);

        else
            properties.PatrolIndex +=1;
            properties.PatrolCooldownTick = tick() + (properties.PatrolCooldown or math.random(5, 10));

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
            if shared.WorldName == "BioXResearch" then
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

        else
            npcClass.Move:Stop();

        end
    end

    if npcClass.Move.IsMoving and setMs == false then
        npcClass.Move:SetMoveSpeed("set", "walk", properties.WalkSpeed or 8, npcClass.Move.MoveSpeedPriority.Movement, 2);
    end

end

--MARK: Social behavior

-- Share intel of enemies
function treePackage.ShareIntel(npcClass: NpcClass)
    local properties = npcClass.Properties;

    local enemyTargetData: NpcTargetData = npcClass.Properties.EnemyTargetData;
    local enemyEntityClass: EntityClass? = enemyTargetData and (enemyTargetData.HealthComp.CompOwner :: EntityClass) or nil;

    if enemyEntityClass and enemyEntityClass.ClassName == "PlayerClass" then
        local npcCombatComp = (enemyEntityClass :: PlayerClass):GetComponent("NpcCombat");
        if npcCombatComp then
            npcCombatComp:UpdateFighting(npcClass);
        end
    end

    if properties.SpokenToMeData and properties.SpokenToMeData.NpcClass and enemyEntityClass then
        local allyNpcClass: NpcClass = properties.SpokenToMeData.NpcClass;
        allyNpcClass.Move:Face(enemyEntityClass.RootPart);

        properties.SpokenToMeData = nil;
    end

    if properties.SpokeByMeData and properties.SpokeByMeData.NpcClass then
        local targetNpcClass: NpcClass = properties.SpokeByMeData.NpcClass;

        if targetNpcClass.HealthComp.IsDead ~= true then
            if targetNpcClass and enemyEntityClass and enemyTargetData.LastAlertedTick then -- I have enemy
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

    if tick() > treePackage.AlertShoutRefreshTick then
        treePackage.AlertShoutQuota = math.clamp(treePackage.AlertShoutQuota + 1, 0, 3);
        treePackage.AlertShoutRefreshTick = tick() + math.random(3, 5);
    end

    local targetHandlerComp = npcClass:GetComponent("TargetHandler");
    if enemyEntityClass
    and not npcClass.HealthComp.IsDead
    and (enemyTargetData.LastAlertedTick and tick()-enemyTargetData.LastAlertedTick <= 10)
    and (properties.LastAlertShout == nil or tick()-properties.LastAlertShout > 20)
    and treePackage.AlertShoutQuota > 0 then
        treePackage.AlertShoutQuota -= 1;
        properties.LastAlertShout = tick();

        if enemyEntityClass.ClassName == "PlayerClass" then
            npcClass:GetComponent("NpcEmote"){
                Players = {(enemyEntityClass :: PlayerClass):GetInstance()};
                EmoteId = "alert";
                SndId = "NpcAlert";
                SndSpeed = math.random(90, 110)/100;
            };

            if math.random(1, 100) == 1 then
                npcClass:GetComponent("NpcEmote"){
                    Players = game.Players:GetPlayers();
                    EmoteId = "help";
                };
            end
        end

        treePackage.OnAlertShout:Fire(npcClass, enemyEntityClass);

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

        
        local disguisedStatus = enemyEntityClass.ClassName ~= "Destructible" 
                            and (enemyEntityClass :: CharacterClass).StatusComp:GetOrDefault("Disguised")
                            or nil;
        local disguiseAlerted = false;

        if math.random(1, 5) == 1 then
            local alertPhrases = npcClass.NpcPackage.Chatter.AlertPhrases;
            local filteredAlertPhrases = {};
            for a=1, #(alertPhrases or {}) do
                local alertPhrase = alertPhrases[a];
                if alertPhrase.HumanoidType == nil 
                or alertPhrase.HumanoidType == (enemyEntityClass :: CharacterClass).HumanoidType then
                    table.insert(filteredAlertPhrases, alertPhrase);
                end
            end

            local disguiseAlertPhrases = npcClass.NpcPackage.Chatter.DisguisedAlertSpeech;
            if disguiseAlertPhrases 
            and disguisedStatus and disguisedStatus.Values.DisguiseId == properties.DangerDisguiseId then
                local disguiseAlertPhrase = disguiseAlertPhrases and disguiseAlertPhrases[math.random(1, #disguiseAlertPhrases)] or nil;
                local sayStr = disguiseAlertPhrase.Say;
                local disName = string.gsub(disguisedStatus.Values.Name, "%d", "");
                sayStr = string.gsub(sayStr, `$DisguiseName`, string.lower(disName));
                sayStr = sayStr:gsub("^%l", string.upper);
                npcClass.Chat(nil, sayStr);

                disguiseAlerted = true;

            else
                local alertPhrase = #filteredAlertPhrases >0 and filteredAlertPhrases[math.random(1, #filteredAlertPhrases)] or nil;
                if alertPhrase then
                    npcClass.Chat(nil, alertPhrase.Say);
                    
                end

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
            if disguisedStatus and disguiseAlerted then
                allyNpcClass.Properties.DangerDisguiseId = disguisedStatus.Values.DisguiseId;
            end
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
    if spokenToMeData == nil then
        properties.SpokenToMeData = nil;
        return;
    end

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
    if shared.WorldName == "BioXResearch" then
        properties.LastResponseTick = tick() + 11;
    end

    npcClass.Move:Face(targetNpcClass.RootPart);
    npcClass.Move:HeadTrack(targetNpcClass.Head, 5);
    npcClass.Chat(nil, spokenToMeData.Dialogue.Reply);

    local aniList = spokenToMeData.Dialogue.ReplyAnimations or TALK_ANIMATIONS;
    npcClass.PlayAnimation(aniList[math.random(1, #aniList)]);
end


function treePackage.DeadbodyReaction(npcClass: NpcClass)
    local properties = npcClass.Properties;

    local deadbodyData = npcClass.Properties.SeenDeadbodyData;
    if deadbodyData then
        local lastDbState = deadbodyData.State;
        local lastDbSeen = deadbodyData.SeenTick;
        local dBPosition = deadbodyData.Position;

        if lastDbState == nil or tick()-lastDbSeen <= 1 then

            if npcClass.Move:IsAtPosition(dBPosition) then
                deadbodyData.State = 2;
                deadbodyData.CheckTick = tick() + math.random(1, 5)/10;

                npcClass.Move:LookAt(deadbodyData.Position);

            else
                npcClass.Move:MoveTo(dBPosition);
                
            end

        elseif lastDbState == 2 and tick() > deadbodyData.CheckTick then
            local deadbodySpeech = npcClass.NpcPackage.Chatter.DeadbodySpeech;
            local deadbodyPhrase = deadbodySpeech and deadbodySpeech[math.random(1, #deadbodySpeech)] or nil;
            if deadbodyPhrase then
                npcClass.Chat(nil, deadbodyPhrase.Say);

                npcClass:GetComponent("NpcEmote"){
                    Players = game.Players:GetPlayers();
                    EmoteId = "question";
                    SndSpeed = math.random(90, 110)/100;
                };
            end

            deadbodyData.State = 3;

        elseif lastDbState == 3 and tick()-deadbodyData.CheckTick >= 7 then
            properties.SeenDeadbodyData = nil;

        end

        return true;
    end

    return false;
end


--MARK: ZarkTree
function treePackage.IsZarkNear(npcClass: NpcClass)
    local properties = npcClass.Properties;

    local myPos = npcClass:GetCFrame().Position;

    local zarkCharacterClass: CharacterClass = properties.ZarkCharacterClass; -- could be player disguised as Zark;
    if zarkCharacterClass 
    and not zarkCharacterClass.HealthComp.IsDead 
    and zarkCharacterClass:DistanceFrom(myPos) <= 16 then
        local isInVision = npcClass:IsInVision(zarkCharacterClass.RootPart, 75);
        if isInVision then
            if properties.DangerDisguiseId ~= "zar" then
                return true;

            else
                if properties.LastAlertFakeZarkTick == nil or tick()-properties.LastAlertFakeZarkTick >= 20 then
                    properties.LastAlertFakeZarkTick = tick();
                
                    local zarkDisguiseSpeech = npcClass.NpcPackage.Chatter.ZarkDisguiseSpeech;
                    local zarkDisguisePhrase = zarkDisguiseSpeech and zarkDisguiseSpeech[math.random(1, #zarkDisguiseSpeech)] 
                                            or {Say="You're not the real Zark!";};
                    npcClass.Chat(nil, zarkDisguisePhrase.Say);
                end
            end
        end
    end

    return false;
end

function treePackage.GreetZark(npcClass: NpcClass)
    local properties = npcClass.Properties;

    local zarkCharacterClass: CharacterClass = properties.ZarkCharacterClass;

    if properties.LastGreetZark == nil or tick()-properties.LastGreetZark > 300 then
        properties.LastGreetZark = tick();

        npcClass.Move:SetMoveSpeed("set", "saluteZark", 0, npcClass.Move.MoveSpeedPriority.Action, 1);
        npcClass.Move:Face(zarkCharacterClass.RootPart);

        local zarkGreetSpeech = npcClass.NpcPackage.Chatter.ZarkGreetSpeech;
        local zarkGreetPhrase = zarkGreetSpeech and zarkGreetSpeech[math.random(1, #zarkGreetSpeech)]
                                or nil;
        if zarkGreetPhrase and math.random(1, 10) > 1 then
            npcClass.Chat(nil, zarkGreetPhrase.Say);
        end

        if math.random(1, 5) == 1 then
            npcClass.PlayAnimation("salute");
        end

        return true;

    elseif properties.LastGreetZark and tick()-properties.LastGreetZark <= 1.5 then
        return true;

    end

    return false;
end

--MARK: FleeTree
function treePackage.CanEquip(npcClass: NpcClass)
    return npcClass.WieldComp.CanEquip;
end

function treePackage.Flee(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local enemyTargetData = npcClass.Properties.EnemyTargetData;
    local enemyNpcClass: NpcClass = enemyTargetData.HealthComp.CompOwner;

    npcClass.Move:SetMoveSpeed("set", "sprint", properties.SprintSpeed or 18, npcClass.Move.MoveSpeedPriority.Movement, 5);
    npcClass.Move:Follow(enemyNpcClass.RootPart, 64, 128);

    if (properties.FleeSpeechTick == nil or tick()-properties.FleeSpeechTick > 60) and math.random(1, 3) == 1 then
        properties.FleeSpeechTick = tick();

        npcClass.PlayAnimation("Surrender");

        local fleeSpeech = npcClass.NpcPackage.Chatter.FleeSpeech;
        local fleePhrase = fleeSpeech and fleeSpeech[math.random(1, #fleeSpeech)] or nil;
        if fleePhrase then
            npcClass.Chat(nil, fleePhrase.Say);
        end
    end

    if properties.KnockoutInteractConfig == nil then
        local knockoutInteractConfig = modInteractables.createInteractable("Knockout");
        knockoutInteractConfig.Parent = npcClass.Character;
        properties.KnockoutInteractConfig = knockoutInteractConfig;
    end

    return true;
end

--MARK: IdleInteractTree
function treePackage.IdleUpdate(npcClass: NpcClass)
    local properties = npcClass.Properties;
    properties.CanDistract = true;

    return;
end

function treePackage.CanIdleInteract(npcClass: NpcClass)
    local properties = npcClass.Properties;
    return properties.NextIdleInteract == nil or tick() > properties.NextIdleInteract;
end

function treePackage.DoIdleInteract(npcClass: NpcClass)
    if npcClass.HealthComp.IsDead then return end;

    local properties = npcClass.Properties;
    local myPosition = npcClass:GetCFrame().Position;


    local activeInteractConfig: Configuration? = properties.ActiveIdleInteractConfig;
    if activeInteractConfig == nil 
    and (properties.IdleInteractScanCooldown == nil or tick() > properties.IdleInteractScanCooldown) then
        properties.IdleInteractScanCooldown = tick() + 1;
        
        local idleInteractables = {};
        local totalChance = 0;

        for _, interactable: InteractableInstance in ipairs(modInteractables.getAllInteractables()) do
			local config = interactable.Config;
			if config:GetAttribute("IdleInteract") == nil then continue end;
            
            local interactPoint = interactable.PointAtt.WorldPosition;
            if modVector.distanceSqrdXZ(interactPoint, myPosition) > 1000 then continue end; -- ~32^2
            if math.abs(interactPoint.Y - myPosition.Y) > 6 then continue end;
            
            local locationName = npcClass:GetMapLocation(interactPoint);
            if locationName ~= properties.SpawnLocationName then continue end;

            if treePackage.SharedInteractablesInUse[config]
            and tick()-treePackage.SharedInteractablesInUse[config] <= 30 then
                continue;
            end

            local chance = config:GetAttribute("IdleInteract") or 1;
            totalChance += chance;
            table.insert(idleInteractables, {I=interactable; C=chance; TC=totalChance;});
		end

        local roll = math.random(0, math.max(totalChance, 1)*1000)/1000;
        for a=1, #idleInteractables do
            local iiInfo = idleInteractables[a];
            if roll >= (iiInfo.TC - iiInfo.C) and roll < iiInfo.TC then
                activeInteractConfig = iiInfo.I.Config;
                break;
            end
        end

        if activeInteractConfig then
            properties.ActiveIdleInteractConfig = activeInteractConfig;
            treePackage.SharedInteractablesInUse[activeInteractConfig] = tick();

            properties.IdleInteractScanCooldown = tick() + 15;
        end
    end
    if activeInteractConfig == nil then return end;


    local activeInteractable: InteractableInstance = modInteractables.getOrNew(activeInteractConfig);
    if activeInteractable == nil then
        properties.ActiveIdleInteractConfig = nil;
        return;
    end

    local interactPart = activeInteractable.Part;
    local pathFindAtt = interactPart and interactPart:FindFirstChild("PathToInteract");
    local interactPoint = activeInteractable.PointAtt.WorldPosition;

    local walkTargetPoint = nil;
    if pathFindAtt then
        walkTargetPoint = pathFindAtt.WorldPosition;
    end
    if walkTargetPoint == nil and interactPart then
        walkTargetPoint = modVector.GetClosestPointToPartFace(interactPart, npcClass.RootPart.Position, {
            GapFromPoint = 2;
            ClampBoundary = NumberRange.new(0.3, 0.6);
        });
    end
    if walkTargetPoint == nil then
        walkTargetPoint = interactPoint;
    end
    
    if not npcClass.Move:IsAtPosition(walkTargetPoint) or tick()-properties.IdleInteractScanCooldown <= 16 then
        npcClass.Move:SetMoveSpeed("set", "walk", 5, npcClass.Move.MoveSpeedPriority.Movement);
        npcClass.Move:MoveTo(walkTargetPoint);

        properties.ArriveIdleInteractState = nil;
        properties.IdleInteractStartTick = nil;

        return true;
    end

    local idleInteractState = properties.ArriveIdleInteractState;
    if idleInteractState == nil then
        idleInteractState = 1;
        properties.IdleInteractStartTick = tick() + math.random(10, 30)/10;
        npcClass.Move:Face(interactPoint);

    elseif idleInteractState == 1 then
        if tick() > properties.IdleInteractStartTick then
            idleInteractState = 2;
            properties.IdleInteractStartTick = tick() + math.random(600, 1500)/100;

            local interactNpcEmote = activeInteractConfig:GetAttribute("InteractNpcEmote");
            if interactNpcEmote then
                npcClass:GetComponent("NpcEmote"){
                    Players = game.Players:GetPlayers();
                    EmoteId = interactNpcEmote;
                };
            end
        end

    elseif idleInteractState == 2 then
        if tick() > properties.IdleInteractStartTick then
            properties.IdleInteractScanCooldown = tick() + 15;
            properties.ActiveIdleInteractConfig = nil;
            treePackage.SharedInteractablesInUse[activeInteractConfig] = nil;

            return;
        end
    end
    properties.ArriveIdleInteractState = idleInteractState;

    return true;
end


--MARK: Distractions
function treePackage.HasDistraction(npcClass: NpcClass)
    local properties = npcClass.Properties;

    local distractionData = properties.Distraction;

    if distractionData then
        if distractionData.Alert == nil then
            distractionData.Alert = true;
            npcClass:GetComponent("NpcEmote"){
                Players = game.Players:GetPlayers();
                EmoteId = "question";
            };
        end

        if tick()-distractionData.Tick >= 30 then
            properties.Distraction = nil;
        end
    end


    return properties.Distraction ~= nil;
end

function treePackage.CheckDistraction(npcClass: NpcClass)
    local properties = npcClass.Properties;

    local distractionData = properties.Distraction;
    local distractionPos = distractionData.Position;

    if not npcClass.Move:IsAtPosition(distractionPos) or tick()-distractionData.Tick <= 1 then
        npcClass.Move:SetMoveSpeed("set", "walk", 5, npcClass.Move.MoveSpeedPriority.Movement);
        npcClass.Move:MoveTo(distractionPos);
        properties.CheckDistractionState = nil;
        properties.CheckDistractionStartTick = nil;
        
    else
        if properties.CheckDistractionState == nil then
            properties.CheckDistractionState = 1;
            properties.CheckDistractionStartTick = tick() + math.random(5, 20)/10;

        elseif properties.CheckDistractionState == 1 then
            if tick() > properties.CheckDistractionStartTick then
                properties.CheckDistractionState = 2;
                properties.CheckDistractionStartTick = tick() + math.random(20, 30);

                npcClass:GetComponent("NpcEmote"){
                    Players = game.Players:GetPlayers();
                    EmoteId = "hmm";
                };

                if distractionData.Disguise and distractionData.DisguiseConfusionSay ~= true then
                    distractionData.DisguiseConfusionSay = true;

                    local confusedSpeech = npcClass.NpcPackage.Chatter.InanimateDisguiseConfusionSpeech;
                    local confusedPhrase = confusedSpeech and confusedSpeech[math.random(1, #confusedSpeech)] or nil;
                    if confusedPhrase then
                        local sayStr = confusedPhrase.Say;
                        local disName = string.gsub(distractionData.Disguise, "%d", "");
                        sayStr = string.gsub(sayStr, `$DisguiseName`, string.lower(disName));
                        sayStr = sayStr:gsub("^%l", string.upper);
                        npcClass.Chat(nil, sayStr);
                    end
                end
            end

        elseif properties.CheckDistractionState == 2 then
            if tick() > properties.CheckDistractionStartTick then
                properties.Distraction = nil;
            end
        end

    end

    return true;
end

function treePackage.DoNothing(npcClass: NpcClass)
    return true;
end

return treePackage;