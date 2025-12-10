local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local MissionLogic = {};
local RunService = game:GetService("RunService");
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);

local MISSION_ID = 15;
if RunService:IsServer() then
	if not modBranchConfigs.IsWorld("TheWarehouse") then return {}; end;

	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	local modEvents = shared.require(game.ServerScriptService.ServerLibrary.Events);
	local modItemDrops = shared.require(game.ServerScriptService.ServerLibrary.ItemDrops);

	shared.modEventService:OnInvoked("Generic_BindItemPickup", function(event: EventPacket, ...)
		local player: Player? = event.Player;
		if player == nil then return end;
		
		local interactData, storageItem: StorageItem = ...;

		task.spawn(function()
			if interactData.Type ~= modInteractables.Types.Pickup then return end;
			local itemId = interactData.ItemId;
			
			if itemId == "battery" then
				if modMission:Progress(player, MISSION_ID) then
					modEvents:NewEvent(player, {Id="mission15Battery"});
				end
				
			elseif itemId == "wires" then
				if modMission:Progress(player, MISSION_ID) then
					modEvents:NewEvent(player, {Id="mission15Wires"});
				end

			end
		end)
	end)

	shared.modEventService:OnInvoked("WorkbenchService_BindClaimBuild", function(eventPacket: EventPacket, ...)
		local player = eventPacket.Player;
		if player == nil then return end;

		local bpLib = ...;
		task.spawn(function()
			if bpLib.Product ~= "electricmod" then return end;
			if not modMission:Progress(player, MISSION_ID) then return end;
			modMission:CompleteMission(player, MISSION_ID);
		end)
	end)

	function MissionLogic.Init(missionProfile, mission)
		local player: Player = missionProfile.Player;

		local function OnChanged(firstRun)
			if mission.Type == 1 then -- OnActive
				if modEvents:GetEvent(player, "mission15Battery") == nil then
					local dropPrefab = modItemDrops.spawn{
                        ItemId = "battery";
                        Quantity = 1;
                        SpawnCFrame = CFrame.new(-9.9, 72.5, -41.9);
						CanInteractNames = {player.Name};
						DespawnDuration = false;
					};
					dropPrefab.PrimaryPart.Anchored = true;
				end
				if modEvents:GetEvent(player, "mission15Wires") == nil then
					local dropPrefab = modItemDrops.spawn{
                        ItemId = "wires";
                        Quantity = 1;
                        SpawnCFrame = CFrame.new(42.8, 63.3, 191.9);
						CanInteractNames = {player.Name};
						DespawnDuration = false;
					};
					dropPrefab.PrimaryPart.Anchored = true;
				end
				mission.Changed:Disconnect(OnChanged);

			end
		end
		
		mission.Changed:Connect(OnChanged);
		OnChanged(true);
	end
end

return MissionLogic;