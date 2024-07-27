local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modGuiHighlight = require(game.ReplicatedStorage.Library.UI.GuiHighlight);

if RunService:IsClient() then
	local modPlayers = require(game.ReplicatedStorage.Library.Players);

	local player = game.Players.LocalPlayer;
	local playerGui = player.PlayerGui;
	modGuiHighlight.HideBackground = true;

	function MissionLogic.ProgressionPoint2()
		local highlight = modGuiHighlight.Set("MainInterface", "MissionPinHud");
	end

	function MissionLogic.ProgressionPoint3()
		modGuiHighlight.FrameWorldObject(workspace.Interactables:WaitForChild("Mission1Pickup"));
		local highlight = modGuiHighlight.Set("MainInterface", "Mission1Pickup");
	end

	function MissionLogic.ProgressionPoint4()
		local highlight = modGuiHighlight.Set("MainInterface", "Hotbar", "search:p250", "p250");
	end

	function MissionLogic.ProgressionPoint5()
		local highlight = modGuiHighlight.Set("MainInterface", "MissionPinHud");
	end

	function MissionLogic.Cancel()
		modGuiHighlight.Set();
	end
end

return MissionLogic;