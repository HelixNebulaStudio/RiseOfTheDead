local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

local interactablePackage = {};
--==
function interactablePackage.init(super) -- Server/Client
    local DoorRotd = {
		Name = "DoorRotd";
        Type = "Door";
    };
    
    function DoorRotd.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        interactable.TypePackage.BindPrompt(interactable, info);
        if RunService:IsServer() then return end;

        local clientData = info.ClientData;
        if clientData == nil then return end;

        if interactable.Id == "premiumOnlyDoor" then
            if clientData.Profile.Premium == false then
                interactable.CanInteract = false;
                interactable.Label = "Door's locked..";
                return;
            end

        elseif interactable.Id == "hiddenDoor" then
            interactable.InteractableRange = 5;
            interactable.Values.EnterSound = "";
            interactable.Label = interactable.Config:GetAttribute("Label") :: string;
        end

        --MARK: TheWarehouse Doors
        if modBranchConfigs.IsWorld("TheWarehouse") then
            if interactable.Id == "bedroomdoorMain" then
                local mission2 = clientData:GetMission(2);
                if mission2 and mission2.Type == 1 and mission2.ProgressionPoint < 2 then
                    interactable.CanInteract = false;
                    interactable.Label = "I should talk to Mason first.";
                    return;
                end

            elseif interactable.Id == "warehouseBalconyEnter" then
                local mission10 = clientData:GetMission(10);
                if mission10 and mission10.Type == 3 then
                    interactable.CanInteract = false;
                    interactable.Label = "Door's locked from the outside..";
                    return;
                end

            elseif interactable.Id == "warehouseBalconyExit" then
                interactable.InteractableRange = 8;

            elseif interactable.Id == "warehouseFenceExit" then
                local mission2 = clientData:GetMission(2);
                if mission2 and mission2.Type == 1 then
                    interactable.CanInteract = false;
                    interactable.Label = `Door is locked, complete "Where am I" mission to unlock.`;
                    return;
                end

            elseif interactable.Id == "lockedFactorydoor" then
                local mission7 = clientData:GetMission(7);
                if mission7 and mission7.Type == 3 then
                    interactable.CanInteract = false;
                    interactable.Label = `Door is locked, complete "The Prisoner" mission to unlock.`;
                    return;
                end

            elseif interactable.Id == "securityRoomEntrance" then
                local mission7 = clientData:GetMission(7);
                if mission7 == nil or (mission7.Type == 1 and mission7.ProgressionPoint < 4) then
                    interactable.CanInteract = false;
                    interactable.Label = "Door is locked from the inside...";
                    return;
                end

            end

        elseif modBranchConfigs.IsWorld("TheUnderground") then

        end

        interactable.CanInteract = true;
    end

    super.registerPackage(DoorRotd);

end

return interactablePackage;

