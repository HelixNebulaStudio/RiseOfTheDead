local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionFunctions = {};
local RunService = game:GetService("RunService");
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modConfigurations = shared.require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));
local modGuiHighlight = shared.require(game.ReplicatedStorage.Library.UI.GuiHighlight);

if RunService:IsClient() then
	local modWaypoint = shared.require(game.ReplicatedStorage.Library.Waypoint);
	local modPlayers = shared.require(game.ReplicatedStorage.Library.Players);

	MissionFunctions.activeWaypoint = nil;
	local player = game.Players.LocalPlayer;
	local playerGui = player.PlayerGui;
	
	local compact = modConfigurations.CompactInterface;

	function SetWaypoint(w)
		if MissionFunctions.activeWaypoint ~= nil then
			MissionFunctions.activeWaypoint.Cancel();
			MissionFunctions.activeWaypoint = nil;
		end
		MissionFunctions.activeWaypoint = w;
	end

	function MissionFunctions.Checkpoint1()
		Debugger:Log("Checkpoint 1");
		modGuiHighlight.Set("MainInterface", "DialogueFrame", "BackgroundFrame", "QuestionList", "whereAmI_deniski");

	end
	function MissionFunctions.Checkpoint2()
		Debugger:Log("Checkpoint 2");
		modGuiHighlight.Set("MainInterface");
		SetWaypoint();
	end

	function MissionFunctions.Checkpoint3()
		Debugger:Log("Checkpoint 3");
		local character = player.Character or player.CharacterAdded:Wait();
		local rootPart = character:WaitForChild("HumanoidRootPart");

		modGuiHighlight.Set("MainInterface");
		if modBranchConfigs.IsWorld("TheWarehouse") then
			SetWaypoint(modWaypoint.NewWaypoint(rootPart, workspace:WaitForChild("Entity"):WaitForChild("Dr. Deniski"):WaitForChild("HumanoidRootPart") ));
		else
			SetWaypoint();
		end;
	end

	function MissionFunctions.Checkpoint4()
		Debugger:Log("Checkpoint 4");
		modGuiHighlight.Set("MainInterface");
		SetWaypoint();
	end

	function MissionFunctions.Checkpoint6()
		Debugger:Log("Checkpoint6");
		local character = player.Character or player.CharacterAdded:Wait();
		local rootPart = character:WaitForChild("HumanoidRootPart");
		RunService.Heartbeat:Wait();

		local highlight = modGuiHighlight.Set("MainInterface", "RatShopFrame", true);
		highlight.Next("MainInterface", "Inventory", "MainList"); --, "contains:p250", "p250"
		highlight.Next("MainInterface", "RatShopFrame", "PageFrame", "AmmoRefillOption");

		highlight.Text = `Select your pistol and refill ammunition`;
		highlight.TextLayout = "BCI";

		if modBranchConfigs.IsWorld("TheWarehouse") then
			SetWaypoint(modWaypoint.NewWaypoint(rootPart, workspace:WaitForChild("Interactables"):WaitForChild("ShopWaypoint") ));
		else
			SetWaypoint();
		end;
	end

	function MissionFunctions.Checkpoint7()
		Debugger:Log("Checkpoint 7");
		modGuiHighlight.Set("MainInterface");
		SetWaypoint();
	end

	function MissionFunctions.Cancel()
		modGuiHighlight.Set();
		SetWaypoint();
	end
end

return MissionFunctions;