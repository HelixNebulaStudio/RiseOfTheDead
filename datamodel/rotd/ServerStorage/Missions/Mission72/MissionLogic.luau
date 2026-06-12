local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local localPlayer = game.Players.LocalPlayer;

local MISSION_ID = 72;

local MissionLogic = {};
--==

function MissionLogic.onRequire()
	if shared.WorldName ~= "TheWarehouse" and shared.WorldName ~= "BioXResearch" then return end;

	if RunService:IsServer() then
		local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

		shared.modEventService:OnInvoked("Shop_BindActionEvent", function(event: EventPacket, ...)
			local action: string, packet: anydict = ...;
			local player = event.Player;
			if player == nil then return end;
			
			task.spawn(function()
				if action ~= "BuyItem" then return end;
				if packet.ItemId ~= "cz75bp" then return end;
		
				if not modMission:Progress(player, MISSION_ID) then return end;

				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint <= 2 then
						mission.ProgressionPoint = 2;
					end
				end)
			end)
		end)

		shared.modEventService:OnInvoked("WorkbenchService_BindStartBuild", function(eventPacket: EventPacket, ...)
			local player = eventPacket.Player;
			if player == nil then return end;

			local userWorkbench, processPacket = ...;

			task.spawn(function()
				local itemId = processPacket.ItemId;
				if itemId ~= "cz75bp" then return end;
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint <= 3 then
						mission.ProgressionPoint = 3;
					end
				end)

				task.wait(120);
				if not game.Players:IsAncestorOf(player) then return end;
				
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint <= 4 then
						mission.ProgressionPoint = 4;
					end
				end)
			end)
		end)
		
		shared.modEventService:OnInvoked("WorkbenchService_BindClaimBuild", function(eventPacket: EventPacket, ...)
			local player = eventPacket.Player;
			if player == nil then return end;

			local bpLib = ...;

			task.spawn(function()
				if bpLib.Product ~= "cz75" then return end;
				if not modMission:Progress(player, MISSION_ID) then return end

				modMission:CompleteMission(player, MISSION_ID);
			end)
		end)

		function MissionLogic.Init(missionProfile, mission)
			local player = missionProfile.Player;
			local profile = shared.modProfile:Get(player);

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

			local highlight = modGuiHighlight.Set("MainInterface", "RatShopFrame", "PageFrame", "WeaponBpPage");
			highlight.Next("MainInterface", "RatShopFrame", "PageFrame", "cz75bp");

		end

		function MissionLogic.Cancel()
			modGuiHighlight.Set();
			SetWaypoint();
		end

	end
end
return MissionLogic;