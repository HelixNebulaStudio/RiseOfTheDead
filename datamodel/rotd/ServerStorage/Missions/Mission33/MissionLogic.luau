local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

local missionId = 33;
if RunService:IsServer() then
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
	-- modBranchConfigs.IsWorld("TheMall")
	
	function MissionLogic.Init(missionProfile, mission)
		local player: Player = missionProfile.Player;

		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable
				if modBranchConfigs.IsWorld("TheMall") then
					local patrickPrefab = workspace.Entity:FindFirstChild("Patrick");
					if patrickPrefab then
						modReplicationManager.SetClientParent(player, patrickPrefab, workspace.Entity);
					end
				end
				
			elseif mission.Type == 1 then -- OnActive
				if modBranchConfigs.IsWorld("TheMall") then
					local patrickPrefab = workspace.Entity:FindFirstChild("Patrick");
					if patrickPrefab then
						modReplicationManager.SetClientParent(player, patrickPrefab, workspace.Entity);
					end
				end

				if modBranchConfigs.IsWorld("BanditOutpost") then
					if firstRun then
						Debugger:Log("Awoken the bear script.");
					end
				elseif not modBranchConfigs.IsWorld("AwokenTheBear") then
					if mission.ProgressionPoint > 3 and mission.ProgressionPoint < 13 then
						modMission:Progress(player, missionId, function(mission)
							mission.ProgressionPoint = 3;
						end)

					elseif mission.ProgressionPoint >= 13 then
						wait(1);
						modMission:CompleteMission(player, 33);

					end

				else
					if mission.ProgressionPoint <= 3 then
						modMission:Progress(player, missionId, function(mission)
							if mission.ProgressionPoint <= 3 then
								mission.ProgressionPoint = 4;
							end;
						end)
					end

				end
				
			elseif mission.Type == 3 then -- OnComplete

			end
		end
		
		mission.Changed:Connect(OnChanged);
	end
end

return MissionLogic;