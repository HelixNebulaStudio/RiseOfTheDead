local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local localPlayer = game.Players.LocalPlayer;

local interactablePackage = {};
--==
function interactablePackage.init(super) -- Server/Client
    local PickupableRotd = super.newPackage{
		Name = "PickupableRotd";
        Type = "Pickupable";
    };
    
    function PickupableRotd.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        PickupableRotd.TypePackage.BindPrompt(interactable, info);
        -- Defaulting to can interact = true;
        if RunService:IsServer() then return end;

        local clientData = info.ClientData;
        if clientData == nil then return; end;

        local modData = shared.require(localPlayer:WaitForChild("DataModule"));
        local localplayerStats = modData.GetStats();
        
        local levelRequired = interactable.Values.LevelRequired;
        if levelRequired and not (localplayerStats and localplayerStats.Level and localplayerStats.Level >= levelRequired) then
            interactable.CanInteract = false;
            interactable.Label = `Mastery Level {levelRequired} Required`;
            return;
        end
    end

    super.registerPackage(PickupableRotd);
end

return interactablePackage;

