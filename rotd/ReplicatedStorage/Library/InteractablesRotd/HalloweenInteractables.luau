local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local interactablePackage = {};

function interactablePackage.init(super) -- Server/Client
    if not modConfigurations.SpecialEvent.Halloween then return end;

    local Cauldron = super.newPackage{
		Name = "HalloweenCauldron";
        Type = "HalloweenCauldron";
    };

    function Cauldron.new(interactable: InteractableInstance, player: Player)
        interactable.CanInteract = true;
        interactable.Label = `Open Cauldron`;
    end

    -- When interacting with interactable.
    function Cauldron.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        if info.Player == nil then return end;
        if info.Action ~= info.ActionSource.Client then return end;

        local halloweenWindow: InterfaceWindow = modClientGuis.getWindow("HalloweenWindow");
        if halloweenWindow.Visible then return end;

        halloweenWindow:Open(interactable, info);
    end
    
    -- When interactable pops up on screen.
    function Cauldron.BindPrompt(interactable: InteractableInstance, info: InteractInfo)

    end

    super.registerPackage(Cauldron);
end

return interactablePackage;

