local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--
local MissionLogic = {};

local RunService = game:GetService("RunService");
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modConfigurations = shared.require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));
local modSyncTime = shared.require(game.ReplicatedStorage.Library:WaitForChild("SyncTime"));
local modGuiHighlight = shared.require(game.ReplicatedStorage.Library.UI.GuiHighlight);

local MISSION_ID = 5;
-- MARK: IsServer()
if RunService:IsServer() then
	if not RunService:IsStudio() then
		if not modBranchConfigs.IsWorld("TheWarehouse") then return {}; end;
	end

	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	local modOnGameEvents = shared.require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	local modAnalyticsService = shared.require(game.ServerScriptService.ServerLibrary.AnalyticsService);

	shared.modEventService:OnInvoked("WorkbenchService_BindInterfaceToggle", function(event: EventPacket, ...)
		local player = event.Player;
		if player == nil or not modMission:Progress(player, MISSION_ID) then return end;

		local visible = ...;
		modMission:Progress(player, MISSION_ID, function(mission)
			if mission.ProgressionPoint == 1 and visible then
				mission.ProgressionPoint = 2;
			end;
		end)
	end)

	modOnGameEvents:ConnectEvent("OnCheckBlueprintCost", function(player, eventData)
		if not modMission:Progress(player, MISSION_ID) then return end;

		local fulfilled = true;
		for a=1, #eventData do
			if not eventData[a].Fulfilled then fulfilled = false; end;
		end

		modMission:Progress(player, MISSION_ID, function(mission)
			if mission.ProgressionPoint == 2 or mission.ProgressionPoint == 3 then

				modAnalyticsService:LogOnBoarding{
					Player=player;
					OnBoardingStep=modAnalyticsService.OnBoardingSteps.Mission5_CheckBlueprintCost;
				};

			end;
			if mission.ProgressionPoint == 2 then
				mission.ProgressionPoint = 3;
			end
		end)
	end)
	
	modOnGameEvents:ConnectEvent("OnBlueprintBuild", function(player, userWorkbench, processPacket)
		local itemId = processPacket.ItemId;
		if itemId ~= "pistoldamagebp" then return end;
		if not modMission:Progress(player, MISSION_ID) then return end;

		modMission:Progress(player, MISSION_ID, function(mission)
			if mission.ProgressionPoint == 3 or mission.ProgressionPoint == 4 then
				mission.ProgressionPoint = 5;
				
				local buildDuration = 10;
				processPacket.BT=modSyncTime.GetTime()+buildDuration;
				userWorkbench:Sync();
				
				task.delay(buildDuration-1, function()
					modMission:Progress(player, MISSION_ID, function(mission)
						if mission.ProgressionPoint == 4 or mission.ProgressionPoint == 5 then
							mission.ProgressionPoint = 6;
						end
					end)
				end)
				
				modAnalyticsService:LogOnBoarding{
					Player=player;
					OnBoardingStep=modAnalyticsService.OnBoardingSteps.Mission5_BuildDamageMod;
				};
			end;
		end)
	end)

	modOnGameEvents:ConnectEvent("OnItemBuilt", function(player, blueprintLibrary)
		if blueprintLibrary.Product ~= "pistoldamagemod" then return end;
		if not modMission:Progress(player, MISSION_ID) then return end

		modMission:Progress(player, MISSION_ID, function(mission)
			if mission.ProgressionPoint == 5 or mission.ProgressionPoint == 6 then
				mission.ProgressionPoint = 7;
			end;

			modAnalyticsService:LogOnBoarding{
				Player=player;
				OnBoardingStep=modAnalyticsService.OnBoardingSteps.Mission5_CollectDamageMod;
			};
		end)
			
	end);

	modOnGameEvents:ConnectEvent("OnModEquipped", function(player, mod, item)
		if mod.ItemId ~= "pistoldamagemod" then return end;
		if not modMission:Progress(player, MISSION_ID) then return end

		modMission:Progress(player, MISSION_ID, function(mission)
			if mission.ProgressionPoint == 7 then
				--mission.ProgressionPoint = 8;
				modMission:CompleteMission(player, MISSION_ID);

				modAnalyticsService:LogOnBoarding{
					Player=player;
					OnBoardingStep=modAnalyticsService.OnBoardingSteps.Mission5_Complete;
				};
			end;
		end)
	end)
	
end

-- MARK: IsClient()
if RunService:IsClient() then
	if not RunService:IsStudio() then
		if not modBranchConfigs.IsWorld("TheWarehouse") then return {}; end;
	end
	
	local modWaypoint = shared.require(game.ReplicatedStorage.Library.Waypoint);

	local player = game.Players.LocalPlayer;
	local playerGui = player.PlayerGui;
	--local modGuiHighlight = shared.require(playerGui:WaitForChild("GuiHighlight"));
	local compact = modConfigurations.CompactInterface;

	local workbenchFrame = compact and "MobileWorkbench" or "WorkbenchFrame";

	MissionLogic.activeWaypoint = nil;

	function SetWaypoint(w)
		if MissionLogic.activeWaypoint ~= nil then
			MissionLogic.activeWaypoint.Cancel();
			MissionLogic.activeWaypoint = nil;
		end
		MissionLogic.activeWaypoint = w;
	end

	function MissionLogic.Checkpoint2()
		SetWaypoint();
		local highlight = modGuiHighlight.Set("MainInterface", workbenchFrame, "navBar", "Blueprints")
		highlight.Next("MainInterface", workbenchFrame, "pageFrame", "blueprints", "scrollList", "Damage Modslist", "list", "Pistol Damage Mod Blueprint")
		highlight.Next("MainInterface", workbenchFrame, "pageFrame", "customBuild", "scrollList", "BuildFrame", "ButtonFrame", "RequirementsFrame")
	end

	function MissionLogic.Checkpoint3()
		SetWaypoint();
		local highlight = modGuiHighlight.Set("MainInterface", "MissionPinHud");
		highlight.Next("MainInterface", workbenchFrame, "navBar", "Blueprints");
		highlight.Next("MainInterface", workbenchFrame, "pageFrame", "blueprints", "scrollList", "Damage Modslist", "list", "Pistol Damage Mod Blueprint")
		highlight.Next("MainInterface", workbenchFrame, "pageFrame", "customBuild", "scrollList", "BuildFrame", "ButtonFrame", "BuildButton")

	end

	function MissionLogic.Checkpoint4()
		SetWaypoint();
		local highlight = modGuiHighlight.Set("MainInterface", workbenchFrame, "navBar", "Blueprints")
		highlight.Next("MainInterface", workbenchFrame, "pageFrame", "blueprints", "scrollList", "Damage Modslist", "list", "Pistol Damage Mod Blueprint")
		highlight.Next("MainInterface", workbenchFrame, "pageFrame", "customBuild", "scrollList", "BuildFrame", "ButtonFrame", "BuildButton")
	end

	function MissionLogic.Checkpoint5()
		SetWaypoint();
		local highlight = modGuiHighlight.Set("MainInterface", workbenchFrame, "navBar", "Processes")
		highlight.Next("MainInterface", workbenchFrame, "pageFrame", "processList", "scrollList", "Buildinglist")
		highlight.Next("MainInterface", workbenchFrame, "pageFrame", "processList", "scrollList", "BuildCompletelist")
	end

	function MissionLogic.Checkpoint6()
		SetWaypoint();
		local highlight = modGuiHighlight.Set("MainInterface", workbenchFrame, "navBar", "Processes")
		highlight.Next("MainInterface", workbenchFrame, "pageFrame", "processList", "scrollList", "Buildinglist")
		highlight.Next("MainInterface", workbenchFrame, "pageFrame", "processList", "scrollList", "Buildinglist")
		highlight.Next("MainInterface", workbenchFrame, "pageFrame", "processList", "scrollList", "BuildCompletelist")
		highlight.Next("MainInterface", workbenchFrame, "pageFrame", "processList", "scrollList", "BuildCompletelist");
	end

	function MissionLogic.Checkpoint7()
		SetWaypoint();

		local highlight = compact and modGuiHighlight.Set("MainInterface", "MobileInventory", "Inventory", "MainList", "1")
			or modGuiHighlight.Set("MainInterface", "Inventory", "MainList", "1");

		highlight.Next("MainInterface", workbenchFrame, "navBar", "Upgrades")
		highlight.Next("MainInterface", workbenchFrame, "pageFrame", "upgradeMenu", "scrollList", "AddModuleFrame")
		highlight.Next("MainInterface", workbenchFrame, "pageFrame", "modsList", "scrollList", "Damage Modslist", "list", "Pistol Damage")
	end

	function MissionLogic.Checkpoint8()
		SetWaypoint();

		local highlight = compact and modGuiHighlight.Set("MainInterface", "MobileInventory", "Inventory", "MainList", "1")
			or modGuiHighlight.Set("MainInterface", "Inventory", "MainList", "1");

		highlight.Next("MainInterface", workbenchFrame, "navBar", "Upgrades")
		highlight.Next("MainInterface", workbenchFrame, "pageFrame", "upgradeMenu", "scrollList", "Pistol Damage")
		highlight.Next("MainInterface", workbenchFrame, "pageFrame", "upgradeMenu", "scrollList", "Pistol Damage", "Upgrades", "DamageUpgradeButton")
	end

	function MissionLogic.Cancel()
		modGuiHighlight.Set();
		SetWaypoint();
	end

end

return MissionLogic;