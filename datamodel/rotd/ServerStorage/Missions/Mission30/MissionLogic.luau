local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

local missionId = 30;
if RunService:IsServer() then
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
	function MissionLogic.Init(missionProfile, mission)
		local player: Player = missionProfile.Player;

		local function OnChanged(firstRun)
			if mission.Type == 3 then -- OnComplete
				
			else
				if modBranchConfigs.IsWorld("TheMall") then
					local patrickPrefab = workspace.Entity:FindFirstChild("Patrick");
					if patrickPrefab then
						modReplicationManager.SetClientParent(player, patrickPrefab, workspace.Entity);
					end
				end
				
			end
		end
		
		mission.Changed:Connect(OnChanged);
		OnChanged(true);
	end
end

return MissionLogic;