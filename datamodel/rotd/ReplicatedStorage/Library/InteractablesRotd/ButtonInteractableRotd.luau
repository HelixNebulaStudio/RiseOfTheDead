local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

local interactablePackage = {};
--==
function interactablePackage.init(super) -- Server/Client
    local ButtonRotd = {
		Name = "ButtonRotd";
        Type = "Button";
    };
    
    function ButtonRotd.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        interactable.TypePackage.BindPrompt(interactable, info);
        if RunService:IsServer() then return end;

        local clientData = info.ClientData;
        if clientData == nil then return; end;

        --MARK: TheWarehouse Doors
        if modBranchConfigs.IsWorld("TheWarehouse") then
            if interactable.Id == "PushStatue" then

            elseif interactable.Id == "BloxmartGateButton" then
                local mission7 = clientData:GetMission(7);

                if mission7 and (mission7.Type == 3 or mission7.ProgressionPoint >= 6) then
                    local buttonPart = interactable.Part;
                    buttonPart.ButtonPanel.button.Color = Color3.fromRGB(107, 59, 59);
                    buttonPart.ButtonPanel.button.Position = Vector3.new(303.242, 73.349, 10.282);
                    interactable.Label = "Bloxmart gates are now opened.";

                    return;
                end

                interactable.Label = `Open Bloxmart Gates`;

            elseif interactable.Id == "RepairSatellite" then
                local mission11 = clientData:GetMission(11);

                if mission11 == nil then
                    interactable.CanInteract = false;
                    interactable.Label = `Damaged satellite dish. Require mission "Radio Signal" from Jane.`;
                    return;
                end
                if mission11 and mission11.ProgressionPoint == 2 then
                    interactable.CanInteract = false;
                    interactable.Label = "Satellite is fixed now.";
                    return;
                end

                if mission11 then
                    if mission11.Redo then
                        interactable.Label = "Repair Satellite with 1 Metal Scrap.";
                    else
                        interactable.Label = "Repair Satellite with 100 Metal Scraps.";
                    end
                end

            end
        end

        interactable.CanInteract = true;
    end

    super.registerPackage(ButtonRotd);

end

return interactablePackage;

