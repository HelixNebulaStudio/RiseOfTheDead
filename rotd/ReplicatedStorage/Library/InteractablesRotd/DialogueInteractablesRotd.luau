local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local interactablePackage = {};
--==

function interactablePackage.init(super) -- Server/Client
    local DialogueRotd = super.newPackage{
        Name = "DialogueRotd";
        Type = "Dialogue";

        IndicatorPresist = false;
        InteractableRange = 10;
    };

    function DialogueRotd.new(interactable: InteractableInstance)
        local config: Configuration = interactable.Config;
        local npcName = config:GetAttribute("NpcName") :: string;

        interactable.CanInteract = true;
        interactable.Label = `Talk to {npcName}`;

        interactable.Values.NpcName = npcName;
    end

    -- When interacting with interactable.
    function DialogueRotd.BindInteract(interactable: InteractableInstance, info: InteractInfo)
        DialogueRotd.TypePackage.BindInteract(interactable, info);
    end

    -- When interactable pops up on screen.
    function DialogueRotd.BindPrompt(interactable: InteractableInstance, info: InteractInfo)
        DialogueRotd.TypePackage.BindPrompt(interactable, info);
        if RunService:IsServer() then return end;

        local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);
        if playerClass.Properties.InBossBattle then
            local npcName = interactable.Values.NpcName;
            interactable.CanInteract = false;
            interactable.Label = `Can not talk to {npcName} right now!`;
            return;
        end
    end

    super.registerPackage(DialogueRotd);
end

return interactablePackage;
