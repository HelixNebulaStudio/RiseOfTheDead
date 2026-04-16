local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local interactablePackage = {};

function interactablePackage.init(super) -- Server/Client
    local WaterTap = super.newPackage{
		Name = "WaterTap";
        Type = "ButtonRotd";
        InteractDuration = 5;
    };

    function WaterTap.new(interactable: InteractableInstance)
        local config: Configuration = interactable.Config;
        config:SetAttribute("_EquipItemId", "wateringcan");

        interactable.Label = `Refill Watering Can`;
    end

    function WaterTap.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        WaterTap.TypePackage.BindInteract(interactable, info);
        if info.Action == "Client" then return end;

        local player = info.Player;
        if player == nil then return; end

        local playerClass: PlayerClass = shared.modPlayers.get(player);

        if playerClass.WieldComp.ItemId ~= "wateringcan" then return end;
        
        local storageItem: StorageItem? = playerClass.WieldComp.StorageItem;
        if storageItem and storageItem.ItemId == "wateringcan" then
            storageItem:SetValues("Water", 100);
            storageItem:Sync({"Water"});
        end
        
        return;
    end

    super.registerPackage(WaterTap);
end

return interactablePackage;

