local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local MISSION_ID = 46;

if RunService:IsServer() then
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

	shared.modEventService:OnInvoked("Interactables_BindButtonInteract", function(event: EventPacket, ...)
		local player: Player? = event.Player;
		if player == nil then return end;

		local interactable: InteractableInstance = ...;
		if interactable.Name ~= "XmasFireplace" then return end
		
		local mission = modMission:Progress(player, MISSION_ID);
		if mission == nil then return end;

		local profile = shared.modProfile:Get(player);
		local playerSave = profile:GetActiveSave();
		local inventory = playerSave.Inventory;

		if mission.ProgressionPoint == 1 then
			local quantity = 0;
			local itemsList = profile.ActiveInventory:ListByItemId("coal");
			for a=1, #itemsList do quantity = quantity +itemsList[a].Quantity; end

			if quantity >= 5 then
				local storageItem = inventory:FindByItemId("coal");
				inventory:Remove(storageItem.ID, 5);
				modMission:Progress(player, MISSION_ID, function(mission)
					mission.ProgressionPoint = 2;
				end)
				shared.Notify(player, "5 Coal removed from your Inventory.", "Negative");
				modAudio.Play("StorageItemDrop", interactable.Part);

			else
				shared.Notify(player, `Not enough Coal, need {math.clamp(5-quantity, 0, 5)} more.`, "Negative");

			end
			
		elseif mission.ProgressionPoint == 2 then
			modMission:Progress(player, MISSION_ID, function(mission)
				mission.ProgressionPoint = 3;
			end)
			
		end
	end)

end

return MissionLogic;