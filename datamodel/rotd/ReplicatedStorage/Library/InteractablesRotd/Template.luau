local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local interactablePackage = {};

function interactablePackage.init(super) -- Server/Client
    local Template = super.newPackage{
		Name = "Template";
        Type = "Template";

        IndicatorPresist = false;
        InteractableRange = 10;
    };

    function Template.new(interactable: InteractableInstance, player: Player)
        local config: Configuration = interactable.Config;
		local npcName = config:GetAttribute("NpcName") :: string;

        interactable.CanInteract = true;
        interactable.Label = `Talk to {npcName}`;

        interactable.Values.NpcName = npcName;
    end

    -- When interacting with interactable.
    function Template.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        if info.Player == nil then return end;
        if info.Action ~= info.ActionSource.Client then return end;

        local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);
        local dialogueWindow: InterfaceWindow = modClientGuis.getWindow("Dialogue");
        if dialogueWindow.Visible then return end;

        dialogueWindow:Open(interactable, info);
    end
    
    -- When interactable pops up on screen.
    function Template.BindPrompt(interactable: InteractableInstance, info: InteractInfo)

    end

    super.registerPackage(Template);
end

return interactablePackage;

