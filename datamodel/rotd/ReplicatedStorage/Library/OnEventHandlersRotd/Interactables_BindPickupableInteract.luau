local RunService = game:GetService("RunService")
local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

return function(event: EventPacket, interactable: InteractableInstance) -- IsServer();
    if RunService:IsClient() then return end;
    if interactable.CanInteract == false then return end;
    
	local player: Player? = event.Player;
	if player == nil then return end;

    task.spawn(function()
        local playerClass: PlayerClass = shared.modPlayers.get(player);
        local profile = shared.modProfile:Get(player);

        local itemId: string = interactable.Values.ItemId;
        local itemLib = modItemsLibrary:Find(itemId);

        if itemId == "money" then 
            interactable.CanInteract = false;

            local gameSave = profile:GetActiveSave();
            gameSave:AddStat("Money", interactable.Values.Quantity or 1);
            modAudio.Play("MoneyPickup", playerClass.Head);

            Debugger.Expire(interactable.Part.Parent);

            event:SetCancelled(true);
            return;
        end;

        if modItemsLibrary:HasTag(itemId, "Weapon") 
        or modItemsLibrary:HasTag(itemId, "Mission")
        or modItemsLibrary:HasTag(itemId, "Blueprint") then
            profile:GuiAction("specialpickup", {itemId;});
        end
    end)

end;