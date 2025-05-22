local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

local missionId = 3;

if RunService:IsServer() then
	if not modBranchConfigs.IsWorld("TheWarehouse") then return {}; end;
	
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	local modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	

	function MissionLogic.Init(missionProfile, mission)
		local player: Player = missionProfile.Player;
		
		if mission.Type == 3 then return end
		local function OnChanged(firstRun)
			if mission.Type ~= 1 then return end;
			
			local item = modStorage.FindItemIdFromStorages("oddbluebook", player);
			if item == nil then
				local oddBlueReplicated = modReplicationManager.GetReplicated(player, "OddBlueBook");
				if oddBlueReplicated == nil or #oddBlueReplicated <= 0 then
					local prefab = script:WaitForChild("OddBlueBook"):Clone();
					modReplicationManager.ReplicateIn(player, prefab, workspace.Interactables);
				end
			end
			
			mission.Changed:Disconnect(OnChanged);
		end
		
		mission.Changed:Connect(OnChanged);
		OnChanged(true);
	end
end

return MissionLogic;