local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local interactablePackage = {};

function interactablePackage.init(super) -- Server/Client
    local Template = {
		Name = "Shop";
        Type = "Shop";
    };

    function Template.new(interactable: InteractableInstance, player: Player)
        local config: Configuration = interactable.Config;
		local shopType = config:GetAttribute("ShopType") :: string;

        interactable.CanInteract = true;
        interactable.Label = `Open Shop`;
        interactable.Values.ShopType = shopType;
    end

    -- When interacting with interactable.
    function Template.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        if info.Player == nil then return end;
        if info.Action ~= info.ActionSource.Client then return end;

        local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);
        local shopWindow: InterfaceWindow = modClientGuis.getWindow("RatShopWindow");
        if shopWindow.Visible then return end;

        shopWindow:Open(interactable, info);
    end
    
    super.registerPackage(Template);
end

return interactablePackage;

