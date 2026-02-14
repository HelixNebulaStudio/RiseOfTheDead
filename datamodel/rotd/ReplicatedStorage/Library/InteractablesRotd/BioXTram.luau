local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

if RunService:IsServer() then
    modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
    modAnalyticsService = shared.require(game.ServerScriptService.ServerLibrary.AnalyticsService);

end

local interactablePackage = {};
--==

function interactablePackage.init(super) -- Server/Client
    local BioXTram = super.newPackage{
		Name = "BioXTram";
        Type = "Button";
    };

    function BioXTram.new(interactable: InteractableInstance, player: Player)
        interactable.Values.ScreenText = [[BioX Personnel & Cargo Monorail

Operations: Disabled

Please activate power levers to re-enabled BioX monorail.]];
    end

    function BioXTram.BindDestroy(interactable: InteractableInstance, player: Player)
        Debugger:Warn(`destroying i`, interactable, `p`, player);
    end

    function BioXTram.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        local config = interactable.Config;
        BioXTram.TypePackage.BindInteract(interactable, info);
        if info.Action == "Client" then return end;

        local isActive = interactable.Values.IsActive;
        if isActive then
            config:SetAttribute("ActiveSpeed", 0);
        else
            config:SetAttribute("ActiveSpeed", 15);
        end
    end
    
    -- When interactable pops up on screen.
    function BioXTram.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        if RunService:IsServer() then return end;
        
        local clientData = info.ClientData;
        if clientData == nil then return end;

        if interactable.Values.IsActive then
            interactable.Label = "Deactivate Monorail";
            return;
        end
        interactable.CanInteract = true;
        interactable.Label = "Activate Monorail";
    end


    super.registerPackage(BioXTram);

end

return interactablePackage;

