local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local CollectionService = game:GetService("CollectionService");

local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);

local treePackage = {
    LogicString = {
        Default = "AlertTree | PreLogic | RestTree | IdleTree";
        AlertTree = "HasEnemy & SurvivorCombatTree";
        RestTree = "ShouldRest & [WalkToRest]";
        IdleTree = "HasIdleTask & [WalkToIdleTask]";
    };
    ActiveUse = {};
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
    return true;
end

function treePackage.SurvivorCombatTree(npcClass: NpcClass)
    return npcClass.BehaviorTree:RunTree("SurvivorCombatTree", false);
end

function treePackage.PreLogic(npcClass: NpcClass)
    local npcPackage = npcClass.NpcPackage;
    if npcPackage.SurvivorIdleData == nil then
        return;
    end
    
    local mapLocation = npcClass:GetMapLocation();
    if mapLocation == nil or npcPackage.SurvivorIdleData[mapLocation] == nil then
        return;
    end

    npcClass.Properties.MapIdleTable = npcPackage.SurvivorIdleData[mapLocation];

    return false;
end

function treePackage.ShouldRest(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local cache = properties.Cache;

    if properties.IdleTask then
        return false;
    end

    if cache.NextRestTick == nil or tick() > cache.NextRestTick then
        return true;
    end

    if cache.RestFinishTick == nil or tick() >= cache.RestFinishTick then
        properties.ProximityChatMessage = nil;
        return false;
    end
    
    return true;
end

function treePackage.WalkToRest(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local cache = properties.Cache;

    local idleData = properties.MapIdleTable.Data;
    local restPoint = idleData.RestPoint or npcClass.SpawnPoint;

    if idleData.RestingSeatName then
        local seatPart = workspace.Environment:FindFirstChild(idleData.RestingSeatName);
        if seatPart then
            local dir = (npcClass.RootPart.Position - seatPart.Position).Unit;
            restPoint = seatPart.CFrame + (dir * (seatPart.Size.Magnitude));
            idleData.SeatPart = seatPart;
        end
    end
    
    if not npcClass.Move:IsAtPosition(restPoint.Position) then
        npcClass.Move:SetMoveSpeed("set", "default", 5);
        npcClass.Move:MoveTo(restPoint.Position);
        return;
    end

    if cache.RestFinishTick and tick() < cache.RestFinishTick then
        return;
    end
    
    local restDuration = math.random(idleData.RestDuration.Min, idleData.RestDuration.Max);
    cache.RestFinishTick = tick() + restDuration;

    local nextRestTime = math.random(idleData.RestTimeInterval.Min, idleData.RestTimeInterval.Max);
    cache.NextRestTick = tick() + nextRestTime;

    npcClass.Move:Face(restPoint.Position + restPoint.LookVector*10);

    if idleData.RestSay then
        properties.ProximityChatMessage = idleData.RestSay[math.random(1, #idleData.RestSay)];
    end

    if idleData.SeatPart then
        npcClass:Sit(idleData.SeatPart);
    else
        npcClass.PlayAnimation("Idle");
    end
    if idleData.RestFunctionName then
        local restFunction = npcClass.Properties[idleData.RestFunctionName];
        if restFunction then
            restFunction();
        end
    end
end

function treePackage.HasIdleTask(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local cache = properties.Cache;

    local mapIdleTable = properties.MapIdleTable;

    if properties.IdleTask then
        return true;
    end

    local rollTable = {};
    local totalChance = 0;
    for _, config in pairs(CollectionService:GetTagged("Interactable")) do
        local id = config:GetAttribute("_Id");
        if id == nil or mapIdleTable[id] == nil then continue end;
        if cache.prevTaskConfig == config then continue end;
        if treePackage.ActiveUse[config] then continue end;

        local taskTable = {
            Config = config;
        };
        for k, v in pairs(mapIdleTable[id]) do
            taskTable[k] = v;
        end
        
        totalChance = totalChance + taskTable.Chance;
        taskTable.TotalChance = totalChance;

        table.insert(rollTable, taskTable);
    end

    local rollValue = math.random(0, totalChance*1000)/1000;
    local rolledTable = nil;

    for a=1, #rollTable do
        if rollTable[a].TotalChance < rollValue then continue end;
        rolledTable = rollTable[a];
        break;
    end
    if rolledTable == nil then
        return false;
    end

    properties.IdleTask = rolledTable;
    treePackage.ActiveUse[rolledTable.Config] = true;
    cache.prevTaskConfig = rolledTable.Config;

    return true;
end

function treePackage.WalkToIdleTask(npcClass: NpcClass)
    local properties = npcClass.Properties;
    local cache = properties.Cache;

    local idleTask = properties.IdleTask;
    if idleTask == nil then
        return;
    end
    
    local interactable: InteractableInstance = modInteractables.getOrNew(idleTask.Config);
    if interactable == nil then
        return;
    end

    local interactPart = interactable.Part;
    local pathFindAtt = interactPart:FindFirstChild("PathFind");

    local walkTargetPoint = nil;
    if pathFindAtt then
        walkTargetPoint = pathFindAtt.WorldPosition;
    end
    if walkTargetPoint == nil then
        walkTargetPoint = modVector.GetClosestPointToPartFace(interactPart, npcClass.RootPart.Position, {
            GapFromPoint = 2;
            ClampBoundary = NumberRange.new(0.3, 0.6);
        });
    end
    
    if not npcClass.Move:IsAtPosition(walkTargetPoint) then
        npcClass.Move:SetMoveSpeed("set", "default", 5);
        npcClass.Move:MoveTo(walkTargetPoint);
        cache.IdleTaskFinishTick = nil;
        return;
    end

    if cache.IdleTaskFinishTick then
        if tick() > cache.IdleTaskFinishTick then
            treePackage.ActiveUse[idleTask.Config] = nil;
            properties.IdleTask = nil;
            properties.ProximityChatMessage = nil;
        end
        return;
    end


    local durationRange: NumberRange = idleTask.Duration or {Min=5; Max=10};
    local taskDuration = math.random(durationRange.Min, durationRange.Max);
    local finishTick = tick() + taskDuration;
    cache.IdleTaskFinishTick = finishTick;

    npcClass.Move:Face(interactPart.Position);

    if idleTask.Say then
        properties.ProximityChatMessage = idleTask.Say[math.random(1, #idleTask.Say)];
    end

    if idleTask.InteractTime then
        local delayDuration = math.abs(idleTask.InteractTime);
        
        local function interact()
            if cache.IdleTaskFinishTick ~= finishTick then return end;

            local values = {};
            npcClass:UseInteractable(interactable.Id, values);
            task.wait(1);
            Debugger:StudioLog(`{npcClass.Name} use interactable values`, values);
            
            if idleTask.InteractSay then
                local sayMsg = idleTask.InteractSay[math.random(1, #idleTask.InteractSay)];

                for k, v in pairs(values) do
                    if typeof(v) == "string" then
                        if k == "ItemId" then
                            local itemLib = modItemsLibrary:Find(v);
                            if itemLib then
                                v = itemLib.Name;
                            end
                        end
                        sayMsg = sayMsg:gsub(`${k}`, v);
                    end
                end

                npcClass.Chat(npcClass.Player or game.Players:GetPlayers(), sayMsg);
            end
        end

        if idleTask.InteractTime < 0 then
            delayDuration = taskDuration-delayDuration;
        end
        task.delay(delayDuration, interact);
    end

    if interactable and interactable.Animation then
        npcClass.PlayAnimation(interactable.Animation);
    end
end

return treePackage;