local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modInteractables = require(game.ReplicatedStorage.Library.Interactables);

--==
return function(event: EventPacket, playerClass: PlayerClass)
    if playerClass == nil or playerClass.ClassName ~= "PlayerClass" then return end;

    local player: Player = playerClass:GetInstance();
    if player == nil then return end;

    local humanoid = playerClass.Humanoid;
    humanoid.Touched:Connect(function(touchPart: BasePart)
        if playerClass.HealthComp.IsDead then return end; 

        local objectModel = touchPart.Parent and touchPart.Parent:IsA("Model") and touchPart.Parent or nil;
        local interactObject = objectModel and objectModel.PrimaryPart or nil;
        local interactModule = objectModel and objectModel:FindFirstChild("Interactable");

        if interactObject == nil or interactModule == nil or not interactModule:IsA("ModuleScript") then return end;

        local interactData = require(interactModule);
        interactData.Object = interactObject;
        interactData.Script = interactModule;

        if interactData == nil or interactData.TouchInteract ~= true then return end;
        if interactData.TouchPickUp == false then return end;
        
        if interactData.Type == modInteractables.Types.Pickup then
            shared.modEventService:ServerInvoke("Skills.OnResourceGatherers", {ReplicateTo={player}}, player, interactData);
        end
    end)
end;