local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

local MISSION_ID = 11;

local MissionLogic = {};
--==

function MissionLogic.onRequire()
	if not modBranchConfigurations.IsWorld("TheWarehouse") then return end;

	if RunService:IsServer() then
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
		
        shared.modEventService:OnInvoked("Interactables_BindButtonInteract", function(eventPacket: EventPacket, ...)
			local player = eventPacket.Player;
			if player == nil then return end;

            local interactable: InteractableInstance = ...;
            local interactId = interactable.Id;

            if interactId == "RepairSatellite" then
				local mission = modMission:Progress(player, MISSION_ID);
				if mission == nil or mission.ProgressionPoint ~= 1 then return end;
					
				local profile: ProfileRotd = shared.modProfile:Get(player) :: ProfileRotd;
				local inventory: Storage = profile.ActiveInventory;

				local total, _itemList = inventory:ListQuantity("metal", mission.Redo and 1 or 100);
				
				local requiredQuantity = mission.Redo and 1 or 100;
				if total >= requiredQuantity then

					local storageItem: StorageItem = inventory:FindByItemId("metal");
					inventory:Remove(storageItem.ID, requiredQuantity);

					modMission:Progress(player, MISSION_ID, function(mission)
						mission.ProgressionPoint = 2;
					end)

					shared.Notify(player, `{requiredQuantity} Metal Scraps removed from your Inventory.`, "Negative");
					modAudio.Play("Repair", interactable.Part);
				else
					shared.Notify(player,`Not enough Metal Scraps, need {math.clamp(requiredQuantity-total, 0, requiredQuantity)} more.`, "Negative");
				
				end
            end
        end)


	elseif RunService:IsClient() then
		shared.modEventService:OnInvoked("Interactables_BindButtonPrompt", function(eventPacket: EventPacket, ...)
			local interactable: InteractableInstance, info: InteractInfo = ...;

			local clientData = info.ClientData;
			if clientData == nil then return; end;

			if interactable.Id ~= "RepairSatellite" then return end;

			local mission11 = clientData:GetMission(MISSION_ID);

			if mission11 == nil or mission11.Type ~= 1 then
				interactable.Label = `Damaged satellite dish. Talk to Jane.`;
				interactable.CanInteract = false;
				return;
			end

			if mission11.ProgressionPoint == 2 then
				interactable.CanInteract = false;
				interactable.Label = "Satellite is fixed now.";
				return;
			end

			if mission11.Redo then
				interactable.Label = "Repair Satellite with 1 Metal Scrap.";
			else
				interactable.Label = "Repair Satellite with 100 Metal Scraps.";
			end
			interactable.CanInteract = true;
		end)

		
	end
end

return MissionLogic;