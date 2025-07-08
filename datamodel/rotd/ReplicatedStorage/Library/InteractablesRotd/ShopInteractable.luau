local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local interactablePackage = {};
--==

function interactablePackage.init(super) -- Server/Client
    local Shop = {
		Name = "Shop";
        Type = "Shop";
    };

    function Shop.new(interactable: InteractableInstance, player: Player)
        local config: Configuration = interactable.Config;
		local shopType = config:GetAttribute("ShopType") :: string;
        local itemId = config:GetAttribute("ItemId") :: string;

        interactable.CanInteract = true;
        interactable.Label = `Open Shop`;
        interactable.Values.ShopType = shopType;
        interactable.Values.ItemId = itemId;
    end

    -- When interacting with interactable.
    function Shop.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        if info.Player == nil then return end;
        if info.Action ~= info.ActionSource.Client then return end;

        local shopType = interactable.Values.ShopType;

        if shopType == "GoldShop" then
            local goldShopWindow: InterfaceWindow = modClientGuis.getWindow("GoldMenu");
            if goldShopWindow.Visible then return end;

            goldShopWindow:Open(interactable.Values.ItemId);
            return;
        end

        local shopWindow: InterfaceWindow = modClientGuis.getWindow("RatShopWindow");
        if shopWindow.Visible then return end;

        shopWindow:Open(interactable, info);
    end
    
    super.registerPackage(Shop);
end

return interactablePackage;

