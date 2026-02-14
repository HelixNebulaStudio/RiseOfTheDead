local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local interactablePackage = {};

function interactablePackage.init(super) -- Server/Client
    local WorkbenchInteractable = super.newPackage{
		Name = "Workbench";
        Type = "Workbench";

        IndicatorPresist = false;
        InteractableRange = 10;
    };

    function WorkbenchInteractable.new(interactable: InteractableInstance)
        local config = interactable.Config;
        local workbenchType = config:GetAttribute("WorkbenchType") :: string;

        interactable.Values.WorkbenchType = workbenchType;
        interactable.CanInteract = true;
        interactable.Label = `Use Workbench`;
    end

    -- When interacting with interactable.
    function WorkbenchInteractable.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        if info.Player == nil then return end;
        if info.Action ~= info.ActionSource.Client then return end;

        local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);
        local workbenchWindow: InterfaceWindow = modClientGuis.getWindow("Workbench");
        if workbenchWindow.Visible then return end;

        workbenchWindow:Open({
            Interactable = interactable;
        });
    end


    super.registerPackage(WorkbenchInteractable);
end

return interactablePackage;

