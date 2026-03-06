local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

local interactablePackage = {};
--==
function interactablePackage.init(super) -- Server/Client
    local DoorRotd = super.newPackage{
		Name = "DoorRotd";
        Type = "Door";
    };
    
    function DoorRotd.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        DoorRotd.TypePackage.BindPrompt(interactable, info);
        if RunService:IsServer() then return end;

        local clientData = info.ClientData;
        if clientData == nil then return end;
        
        if interactable.Values.Locked then return; end

		local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);
        if playerClass.Properties.InBossBattle then
            interactable.CanInteract = false;
            interactable.Label = "Door's locked when you are in battle.";
            return;
        end

        if interactable.Id == "premiumOnlyDoor" then
            if clientData.Profile.Premium == false then
                interactable.CanInteract = false;
                interactable.Label = "Door's locked..";
                return;
            end

        elseif interactable.Id == "hiddenDoor" then
            interactable.InteractableRange = 5;
            interactable.Values.EnterSound = "";
            interactable.Label = interactable.Config:GetAttribute("Label") :: string;
        end

        interactable.CanInteract = true;
    end

    super.registerPackage(DoorRotd);

end

return interactablePackage;

