local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modGuiHighlight = shared.require(game.ReplicatedStorage.Library.UI.GuiHighlight);

-- MARK: IsServer()
if RunService:IsServer() then
	local modOnGameEvents = shared.require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

	modOnGameEvents:ConnectEvent("OnFocusKill", function(npcModule, player)
		if npcModule.Name ~= "Zombie" then return end;
		if modMission:IsComplete(player, 27) then return end;

		modMission:Progress(player, 27, function(mission)
			if mission.ProgressionPoint == 2 then
				modMission:CompleteMission(player, 27);
			end;
		end)
	end)
end

-- MARK: IsClient()
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