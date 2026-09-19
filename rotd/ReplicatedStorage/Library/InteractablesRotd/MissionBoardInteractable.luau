local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local interactablePackage = {};

function interactablePackage.init(super) -- Server/Client
    local MissionsBoard = super.newPackage{
		Name = "MissionsBoard";
        Type = "MissionsBoard";

        IndicatorPresist = false;
    };

    function MissionsBoard.new(interactable: InteractableInstance)
        local config: Configuration = interactable.Config;
        interactable.CanInteract = true;
        interactable.Label = "Check Missions";
    end

    -- When interacting with interactable.
    function MissionsBoard.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        if info.Player == nil then return end;
        if info.Action ~= info.ActionSource.Client then return end;

        local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);
        local missionWindow: InterfaceWindow = modClientGuis.getWindow("Missions");
        if missionWindow.Visible then return end;

        missionWindow:Open(interactable, info);
    end
    
    -- When interactable pops up on screen.
    function MissionsBoard.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
    end

    super.registerPackage(MissionsBoard);
end

return interactablePackage;

