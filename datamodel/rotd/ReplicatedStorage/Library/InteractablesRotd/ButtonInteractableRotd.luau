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

        if modBranchConfigs.IsWorld("TheWarehouse") then
            if interactable.Id == "PushStatue" then

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

