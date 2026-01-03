local RunService = game:GetService("RunService")
local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

return function(event: EventPacket, interactable: InteractableInstance) -- IsServer();
    if RunService:IsClient() then return end;
    if interactable.CanInteract == false then return end;
    
	local player: Player? = event.Player;
	if player == nil then return end;

    local playerClass: PlayerClass = shared.modPlayers.get(player);
    local profile = shared.modProfile:Get(player);

    local itemId: string = interactable.Values.ItemId;
    if itemId == "money" then 
        interactable.CanInteract = false;

        local gameSave = profile:GetActiveSave();
        gameSave:AddStat("Money", interactable.Values.Quantity or 1);
        modAudio.Play("MoneyPickup", playerClass.Head);

        Debugger.Expire(interactable.Part.Parent);

        event:SetCancelled(true);
        return
    end;
end;