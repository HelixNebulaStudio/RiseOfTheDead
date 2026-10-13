local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local interactablePackage = {};

function interactablePackage.init(super) -- Server/Client
    local ThrowableJunkPickup = super.newPackage{
		Name = "ThrowableJunkPickup";
        Type = "ButtonRotd";

        IndicatorPresist = false;
    };

    function ThrowableJunkPickup.new(interactable: InteractableInstance)
        local config: Configuration = interactable.Config;

        interactable.CanInteract = true;
        interactable.Label = `Pick up Junk`;
    end

    -- When interacting with interactable.
    function ThrowableJunkPickup.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        ThrowableJunkPickup.TypePackage.BindInteract(interactable, info);
        if info.Player == nil then return end;
        if info.Action == "Client" then return end;

        local player = info.Player;
        if player == nil then return; end

        local config: Configuration = interactable.Config;
        local model = config.Parent;
        
        local playerClass: PlayerClass = shared.modPlayers.get(player);
		playerClass.WieldComp:Equip{
			ItemId = "throwablejunk";
			ProxyEquip = true;
            ProxyEquipCallback = function(toolHandler: ToolHandlerInstance)
                local properties = toolHandler.EquipmentClass.Properties;
                properties.PickupableJunk = true;
            end
		};

        Debugger.Expire(model);

        return;
    end
    
    super.registerPackage(ThrowableJunkPickup);
end

return interactablePackage;

