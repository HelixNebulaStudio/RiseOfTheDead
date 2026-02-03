local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);

local treePackage = {
    LogicString = {
        Default = "InCutscene & Tree";
        Tree = "GoTo | LookAt";
    };
}

function treePackage.InCutscene(npcClass: NpcClass)
    local isInCutscene = npcClass.Properties.CutsceneActive == true;

    if not isInCutscene then
        npcClass.Properties.CutsceneAttractRange = nil;

    else
        local wieldComp = npcClass.WieldComp;
        if npcClass.Properties.CutsceneEquip then
            if npcClass.Properties.CutsceneEquip ~= wieldComp.ItemId then
                wieldComp:Equip{
                    ItemId = npcClass.Properties.CutsceneEquip;
                };
            end
        else
            wieldComp:Unequip();
        end

    end
    
    return isInCutscene;
end

function treePackage.GoTo(npcClass: NpcClass)
    local walkToPosition = npcClass.Properties.CutsceneWalkTo;

    local interactId = npcClass.Properties.CutsceneWalkToInteract;
    if interactId then
        local interactConfig: Configuration = modInteractables.getById(interactId);
        local interactable: InteractableInstance = modInteractables.getOrNew(interactConfig);
        if interactable == nil then
            npcClass.Properties.CutsceneWalkToInteract = nil;
        else
            local newWalkTo = interactable.Point;

            local pathToInteractAtt = interactable.Part:FindFirstChild("PathToInteract");
            if pathToInteractAtt then
                newWalkTo = pathToInteractAtt.WorldPosition;
            end
            npcClass.Properties.CutsceneWalkTo = newWalkTo;
            npcClass.Properties.CutsceneWalkToInteract = nil;
        end
    end

    if walkToPosition == nil then return false; end;

    if npcClass.Properties.LastCutsceneWalkTo ~= walkToPosition then
        npcClass.Properties.LastCutsceneWalkTo = walkToPosition;
        
        npcClass.Properties.CutsceneWalkToStart = tick();
    end

    local moveLapse = npcClass.Properties.CutsceneWalkToStart and tick()-npcClass.Properties.CutsceneWalkToStart or nil;

    if npcClass.Move:IsAtPosition(walkToPosition) then
        npcClass.Properties.CutsceneWalkToStart = tick();

        if npcClass.Properties.CutsceneWalkToInteract then
            npcClass.Properties.CutsceneWalkToInteract = nil;
        end

        npcClass.Move.OnMoveToEnded:Fire(walkToPosition);

        return false;

    elseif moveLapse and moveLapse >= 60 then
        npcClass:SetCFrame(CFrame.new(walkToPosition));
        npcClass.Properties.CutsceneWalkToStart = tick();
        Debugger:StudioWarn(`{npcClass.Name} cutscene stuck? Teleporting to CutsceneWalkTo:{walkToPosition}.`);
        return false;
    end

    local distance = modVector.DistanceSqrd(npcClass:GetCFrame().Position, walkToPosition);
    if distance >= 576 then -- 24^2
        local newSpeed = 18;
        if npcClass.Humanoid.WalkSpeed ~= newSpeed then
            npcClass.Move:SetMoveSpeed("set", "sprint", newSpeed, npcClass.Move.MoveSpeedPriority.Movement, 1);
        end
    else
        local newSpeed = 6;
        if npcClass.Humanoid.WalkSpeed ~= newSpeed then
            npcClass.Move:SetMoveSpeed("set", "walk", newSpeed, npcClass.Move.MoveSpeedPriority.Movement, 1);
        end
    end

    npcClass.Move:MoveTo(walkToPosition);
    return true;
end

function treePackage.LookAt(npcClass: NpcClass)
    local lookAtPosition = npcClass.Properties.CutsceneLookAt;
    if lookAtPosition == nil then return false; end;

    if npcClass.Properties.LastCutsceneLookAtTick == nil or tick() > npcClass.Properties.LastCutsceneLookAtTick then
        npcClass.Properties.LastCutsceneLookAtTick = tick() + math.random(3, 6);

        npcClass.Move:Face(lookAtPosition);
    end

    return true;
end

return treePackage;