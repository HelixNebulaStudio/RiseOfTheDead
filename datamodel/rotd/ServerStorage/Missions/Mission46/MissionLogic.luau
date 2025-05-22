local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local missionId = 46;
if RunService:IsServer() then
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
	shared.modEventService:OnInvoked("Interactables_OnTrigger", function(eventPacket: EventPacket, interactData, ...)
		local player: Player? = eventPacket.Player;
		if player == nil then return end;

		local profile = shared.modProfile:Get(player);
		local playerSave = profile:GetActiveSave();
		local inventory = playerSave.Inventory;

		local triggerId = interactData.TriggerTag;

		if triggerId ~= "ToggleFireplace" then return end

		local mission = modMission:Progress(player, missionId);
		if mission == nil then return end;

		if mission.ProgressionPoint == 1 then
			local quantity = 0;
			local itemsList = profile.ActiveInventory:ListByItemId("coal");
			for a=1, #itemsList do quantity = quantity +itemsList[a].Quantity; end

			if quantity >= 5 then
				local storageItem = inventory:FindByItemId("coal");
				inventory:Remove(storageItem.ID, 5);
				modMission:Progress(player, missionId, function(mission)
					mission.ProgressionPoint = 2;
				end)
				shared.Notify(player, "5 Coal removed from your Inventory.", "Negative");
				modAudio.Play("StorageItemDrop", interactData.Object);

			else
				shared.Notify(player, "Not enough Coal, need "..math.clamp(5-quantity, 0, 5).." more.", "Negative");

			end
			
		elseif mission.ProgressionPoint == 2 then
			modMission:Progress(player, missionId, function(mission)
				mission.ProgressionPoint = 3;
			end)
			
		end
	end)
end

return MissionLogic;