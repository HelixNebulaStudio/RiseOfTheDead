local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local localPlayer = game.Players.LocalPlayer;

local interactablePackage = {};
--==
function interactablePackage.init(super) -- Server/Client
    local StorageRotd = super.newPackage{
		Name = "StorageRotd";
        Type = "Storage";
    };
    
    function StorageRotd.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        StorageRotd.TypePackage.BindPrompt(interactable, info);
        -- Defaulting to can interact = true;
        if RunService:IsServer() then return end;

        local clientData = info.ClientData;
        if clientData == nil then return; end;

        local modData = shared.require(localPlayer:WaitForChild("DataModule"));
        local localplayerStats = modData.GetStats();
        
        local levelRequired = interactable.Values.LevelRequired;
        if not (levelRequired and localplayerStats and localplayerStats.Level and localplayerStats.Level >= levelRequired) then
            interactable.CanInteract = false;
            interactable.Label = `Mastery Level {levelRequired} Required`;
            return;
        end
    end

    super.registerPackage(StorageRotd);
end

return interactablePackage;

