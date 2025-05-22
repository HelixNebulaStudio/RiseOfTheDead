local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modMarkers = shared.require(game.ReplicatedStorage.Library.Markers);
local modConfigurations = shared.require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));
local modGuiHighlight = shared.require(game.ReplicatedStorage.Library.UI.GuiHighlight);

local missionId = 49;

if RunService:IsServer() then
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

	function MissionLogic.Init(missionProfile, mission)
		local player = missionProfile.Player;
		local profile = shared.modProfile:Get(player);

		if mission.Type == 1 then -- OnActive
			if mission.ProgressionPoint == 4 and profile.Collectibles.vrm == true then
				modMission:Progress(player, missionId, function(mission)
					mission.ProgressionPoint = 5;
				end)
			end
		end
	end

else
	local modWaypoint = shared.require(game.ReplicatedStorage.Library.Waypoint);
	local modPlayers = shared.require(game.ReplicatedStorage.Library.Players);

	MissionLogic.activeWaypoint = nil;
	local player = game.Players.LocalPlayer;
	local playerGui = player.PlayerGui;
	--local modGuiHighlight = shared.require(playerGui:WaitForChild("GuiHighlight"));
	local compact = modConfigurations.CompactInterface;

	function SetWaypoint(w)
		if MissionLogic.activeWaypoint ~= nil then
			MissionLogic.activeWaypoint.Cancel();
			MissionLogic.activeWaypoint = nil;
		end
		MissionLogic.activeWaypoint = w;
	end

	function MissionLogic.Checkpoint1()
		local character = player.Character or player.CharacterAdded:Wait();
		local rootPart = character:WaitForChild("HumanoidRootPart");
		task.wait(0.5);

		local highlight = modGuiHighlight.Set("MainInterface", "RatShopFrame", "PageFrame", "AccessoriesPage");
		highlight.Next("MainInterface", "RatShopFrame", "PageFrame", "gps");

		if modBranchConfigs.IsWorld("TheWarehouse") then
			SetWaypoint(modWaypoint.NewWaypoint(rootPart, workspace:WaitForChild("Interactables"):WaitForChild("ShopWaypoint") ));
		end
	end

	function MissionLogic.Checkpoint2()
		task.wait(0.5);

		local highlight = modGuiHighlight.Set("MainInterface", "Inventory", "MainList", "search:gps", "gps");
		highlight.Next("MainInterface", "GpsInterface", "ScrollingFrame", "w1office");
		SetWaypoint();
	end

	function MissionLogic.Checkpoint3()
		task.wait(0.5);

		local highlight = modGuiHighlight.Set("MainInterface", "Inventory", "MainList", "search:gps", "gps");
		highlight.Next("MainInterface", "GpsInterface", "ScrollingFrame", "w1office");
		SetWaypoint();
	end

	function MissionLogic.Checkpoint4()
		modGuiHighlight.Set();
		SetWaypoint();
	end

	function MissionLogic.Cancel()
		modGuiHighlight.Set();
		SetWaypoint();
	end
end

return MissionLogic;