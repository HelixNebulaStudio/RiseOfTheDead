local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

local missionId = 30;
if RunService:IsServer() then
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
	function MissionLogic.Init(missionProfile, mission)
		local player: Player = missionProfile.Player;

		local function OnChanged(firstRun)
			if mission.Type == 3 then -- OnComplete
				if shared.WorldName == "TheMall" then
					local patrickPrefab = workspace.Entity:FindFirstChild("Patrick");
					if patrickPrefab then
						local mission58 = missionProfile:Get(58);
						if mission.Redo and mission58 and mission58.Type == 3 then
							modReplicationManager.SetClientParent(player, patrickPrefab, game.ReplicatedStorage);
						end
					end
				end

			else
				if shared.WorldName == "TheMall" then
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