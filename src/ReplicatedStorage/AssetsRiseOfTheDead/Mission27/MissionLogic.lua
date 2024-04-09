local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modGuiHighlight = require(game.ReplicatedStorage.Library.UI.GuiHighlight);

if RunService:IsClient() then
	local player = game.Players.LocalPlayer;
	local playerGui = player.PlayerGui;
	
	function MissionLogic.ProgressionPoint1()
		local highlight = modGuiHighlight.Set("MainInterface", "QuickButtons", "SocialMenu");
	end

	function MissionLogic.ProgressionPoint2()
		local highlight = modGuiHighlight.Set("MainInterface", "SocialMenu", "RightBackground", "ProfileFrame", "focusLevels");
	end

	function MissionLogic.Cancel()
		modGuiHighlight.Set();
	end
end

return MissionLogic;