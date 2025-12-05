local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local interactablePackage = {};

function interactablePackage.init(super) -- Server/Client
    local ViewSafehome = super.newPackage{
		Name = "ViewSafehome";
        Type = "ViewSafehome";
    };

    function ViewSafehome.new(interactable: InteractableInstance, player: Player)
        interactable.CanInteract = true;
        interactable.Label = `View Safehome`;
    end

    -- When interacting with interactable.
    function ViewSafehome.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        if info.Player == nil then return end;
        if info.Action ~= info.ActionSource.Client then return end;

        local halloweenWindow: InterfaceWindow = modClientGuis.getWindow("Safehome");
        if halloweenWindow.Visible then return end;

        halloweenWindow:Open(interactable, info);
    end
    
    super.registerPackage(ViewSafehome);


    local SafehomeSoundSystem = {
		Name = "SafehomeSoundSystem";
        Type = "SafehomeSoundSystem";
    };

    function SafehomeSoundSystem.new(interactable: InteractableInstance, player: Player)
        interactable.CanInteract = true;
        interactable.Label = `Use Sound System`;
    end

    -- When interacting with interactable.
    function SafehomeSoundSystem.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        if info.Player == nil then return end;
        if info.Action ~= info.ActionSource.Client then return end;

        local halloweenWindow: InterfaceWindow = modClientGuis.getWindow("SafehomeSoundSystem");
        if halloweenWindow.Visible then return end;

        halloweenWindow:Open(interactable, info);
    end
    
    super.registerPackage(SafehomeSoundSystem);

end

return interactablePackage;

