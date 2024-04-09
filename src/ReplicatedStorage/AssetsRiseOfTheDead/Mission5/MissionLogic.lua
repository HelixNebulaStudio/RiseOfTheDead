local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modConfigurations = require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));
local modGuiHighlight = require(game.ReplicatedStorage.Library.UI.GuiHighlight);

if RunService:IsClient() then
	if not modBranchConfigs.IsWorld("TheWarehouse") then return {}; end;
	
	local modWaypoint = require(game.ReplicatedStorage.Library.Waypoint);

	local player = game.Players.LocalPlayer;
	local playerGui = player.PlayerGui;
	--local modGuiHighlight = require(playerGui:WaitForChild("GuiHighlight"));
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
		local highlight = modGuiHighlight.Set("MainInterface", workbenchFrame, "navBar", "Blueprints")
		highlight.Next("MainInterface", workbenchFrame, "pageFrame", "blueprints", "scrollList", "Damage Modslist", "list", "Pistol Damage Mod Blueprint")
		highlight.Next("MainInterface", workbenchFrame, "pageFrame", "customBuild", "scrollList", "BuildFrame", "ButtonFrame", "RequirementsFrame")
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