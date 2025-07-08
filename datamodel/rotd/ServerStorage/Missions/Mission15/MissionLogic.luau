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

	shared.modEventService:OnInvoked("Generic_BindItemPickup", function(
		event: EventPacket, 
		interactData, 
		storageItem: StorageItem
	)
		local player: Player? = event.Player;
		if player == nil then return end;
		
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


	function MissionLogic.Init(missionProfile, mission)
		local player: Player = missionProfile.Player;

		local function OnChanged(firstRun)
			if mission.Type == 1 then -- OnActive
				if modEvents:GetEvent(player, "mission15Battery") == nil then
					modItemDrops.Spawn({Name="Battery"; Type=modItemDrops.Types.Battery; Quantity=1}, CFrame.new(-9.9, 72.5, -41.9), player, false);
				end
				if modEvents:GetEvent(player, "mission15Wires") == nil then
					modItemDrops.Spawn({Name="Wires"; Type=modItemDrops.Types.Wires; Quantity=1}, CFrame.new(42.8, 63.3, 191.9), player, false);
				end
				mission.Changed:Disconnect(OnChanged);

			end
		end
		
		mission.Changed:Connect(OnChanged);
		OnChanged(true);
	end
end

return MissionLogic;