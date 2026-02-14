local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

local MISSION_ID = 49;

local MissionLogic = {};
--==

function MissionLogic.onRequire()
	if not modBranchConfigurations.IsWorld("TheWarehouse") then return end;

	if RunService:IsServer() then
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		shared.modEventService:OnInvoked("Interactables_BindCollectibleInteract", function(eventPacket: EventPacket, ...)
			local player: Player? = eventPacket.Player;
			if player == nil then return end;

			local interactable: InteractableInstance = ...;

			if interactable.Id == "vrm" then
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint <= 4 then
						mission.ProgressionPoint = 5;
					end;
				end)
			end
		
		end)

		function MissionLogic.Init(missionProfile, mission)
			local player = missionProfile.Player;
			local profile = shared.modProfile:Get(player);

			if mission.Type == 1 then -- OnActive
				if mission.ProgressionPoint == 4 and profile.Collectibles.vrm == true then
					modMission:Progress(player, MISSION_ID, function(mission)
						mission.ProgressionPoint = 5;
					end)
				end
			end
		end

	elseif RunService:IsClient() then
		local modGuiHighlight = shared.require(game.ReplicatedStorage.Library.UI.GuiHighlight);
		local modWaypoint = shared.require(game.ReplicatedStorage.Library.Waypoint);

		MissionLogic.activeWaypoint = nil;

		local function SetWaypoint(w)
			if MissionLogic.activeWaypoint ~= nil then
				MissionLogic.activeWaypoint.Cancel();
				MissionLogic.activeWaypoint = nil;
			end
			MissionLogic.activeWaypoint = w;
		end

		function MissionLogic.Checkpoint1()
			local character = localPlayer.Character or localPlayer.CharacterAdded:Wait();
			local rootPart = character:WaitForChild("HumanoidRootPart");
			task.wait(0.5);

			local highlight = modGuiHighlight.Set("MainInterface", "RatShopFrame", "PageFrame", "AccessoriesPage");
			highlight.Next("MainInterface", "RatShopFrame", "PageFrame", "gps");

			if modBranchConfigurations.IsWorld("TheWarehouse") then
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
end
return MissionLogic;