local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local MissionLogic = {};
local RunService = game:GetService("RunService");
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modInteractables = require(game.ReplicatedStorage.Library.Interactables);

local missionId = 15;
if RunService:IsServer() then
	if not modBranchConfigs.IsWorld("TheWarehouse") then return {}; end;

	local modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	local modEvents = require(game.ServerScriptService.ServerLibrary.Events);
	local modItemDrops = require(game.ServerScriptService.ServerLibrary.ItemDrops);
	local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	
	modOnGameEvents:ConnectEvent("OnItemPickup", function(player, interactData)
		if interactData.Type ~= modInteractables.Types.Pickup then return end;
		local itemId = interactData.ItemId;
		
		if itemId == "battery" then
			if modMission:Progress(player, missionId) then
				modEvents:NewEvent(player, {Id="mission15Battery"});
			end
			
		elseif itemId == "wires" then
			if modMission:Progress(player, missionId) then
				modEvents:NewEvent(player, {Id="mission15Wires"});
			end

		end

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