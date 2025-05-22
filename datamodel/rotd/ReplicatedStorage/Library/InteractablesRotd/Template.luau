local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local interactablePackage = {};

function interactablePackage.init(super) -- Server/Client
    local Template = {
		Name = "Template";
        Type = "Template";

        IndicatorPresist = false;
        InteractableRange = 10;
    };

    function Template.new(interactable: InteractableInstance, npcName: string)
        local scr: ModuleScript = interactable.Script;
		npcName = (scr:GetAttribute("NpcName") :: string) or npcName;

        interactable.CanInteract = true;
        interactable.Label = `Talk to {npcName}`;

        interactable.Values.NpcName = npcName;
    end

    -- When interacting with interactable.
    function Template.ActionEvent(interactable: InteractableInstance, info: InteractInfo)
        if info.Player == nil then return end;
        if info.Action ~= info.ActionTypes.ClientInteract then return end;

        local interface = info.ClientInterface;
        if interface == nil or interface:IsVisible("Dialogue") then return end;

        interface.Object = interactable.Object;
        interface:OpenWindow("Dialogue", interactable, info);
    end
    
    -- When interactable pops up on screen.
    function Template.PromptEvent(interactable: InteractableInstance, info: InteractInfo)

    end

    super.register(Template);
end

return interactablePackage;

