local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local interactablePackage = {};

function interactablePackage.init(super) -- Server/Client
    local Template = {
		Name = "Workbench";
        Type = "Workbench";

        IndicatorPresist = false;
        InteractableRange = 10;
    };

    function Template.new(interactable: InteractableInstance)
        interactable.CanInteract = true;
        interactable.Label = `Use Workbench`;
    end

    -- When interacting with interactable.
    function Template.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        if info.Player == nil then return end;
        if info.Action ~= info.ActionSource.Client then return end;

        local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);
        local workbenchWindow: InterfaceWindow = modClientGuis.getWindow("Workbench");
        if workbenchWindow.Visible then return end;

        workbenchWindow:Open({
            InteractObject = interactable.Object;
        });
    end


    super.registerPackage(Template);
end

return interactablePackage;

