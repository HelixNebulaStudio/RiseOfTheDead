local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modStorageItem = shared.require(game.ReplicatedStorage.Library.StorageItem);

local interactablePackage = {};

function interactablePackage.init(super) -- Server/Client
    local MakeshiftBarricade = super.newPackage{
		Name = "MakeshiftBarricade";
        Type = "ButtonRotd";
    };

    function MakeshiftBarricade.new(interactable: InteractableInstance)
        local config: Configuration = interactable.Config;
    end

    function MakeshiftBarricade.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        MakeshiftBarricade.TypePackage.BindInteract(interactable, info);
        if info.Action == "Client" then return end;

        local player = info.Player;
        if player == nil then return; end

        local playerClass: PlayerClass = shared.modPlayers.get(player);

        return;
    end

    super.registerPackage(MakeshiftBarricade);


    --MARK: MakeshiftMaterial
    local MakeshiftMaterial = super.newPackage{
		Name = "MakeshiftMaterial";
        Type = "ButtonRotd";
        InteractDuration = 1;
    };

    function MakeshiftMaterial.new(interactable: InteractableInstance)
        local config: Configuration = interactable.Config;

    end

    function MakeshiftMaterial.BindPrompt(interactable: InteractableInstance)
        interactable.Label = `Pick up makeshift {interactable.Values.MaterialName}`;

    end

    function MakeshiftMaterial.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        MakeshiftMaterial.TypePackage.BindInteract(interactable, info);
        if info.Action == "Client" then return end;

        local player = info.Player;
        if player == nil then return; end

        local config: Configuration = interactable.Config;
        local handle = config.Parent and config.Parent:FindFirstChild("Handle");
        
        local matName = interactable.Values.MaterialName;

        local playerClass: PlayerClass = shared.modPlayers.get(player);
		playerClass.WieldComp:Equip{
			ItemId = "generic";
			ProxyEquip = true;
            ProxySiid = `w:{matName}`;
            ProxyEquipCallback = function(toolHandler: ToolHandlerInstance)
                local properties = toolHandler.EquipmentClass.Properties;
                properties.HandleTemplate = handle;

                local storageItem: StorageItem = toolHandler.StorageItem;
                storageItem:SetValues("MatName", matName);

                Debugger:StudioLog(`storageItem=`, storageItem, "HandleTemplate", handle);
            end
		};

        return;
    end

    super.registerPackage(MakeshiftMaterial);

end

return interactablePackage;

