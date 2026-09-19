local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local RunService = game:GetService("RunService");

local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

local MissionLogic = {};

local MISSION_ID = 38;
if RunService:IsServer() then

	function MissionLogic.Init(missionProfile, mission)
		local player: Player = missionProfile.Player;

		local function OnChanged(firstRun)
			if shared.WorldName ~= "TheMall" then return end;

			local patrickPrefab = workspace.Entity:FindFirstChild("Patrick");
			if patrickPrefab == nil then return end;

			if mission.Type == 2 then -- OnAvailable
				modReplicationManager.SetClientParent(player, patrickPrefab, workspace.Entity);
				
			elseif mission.Type == 1 then -- OnActive
				modReplicationManager.SetClientParent(player, patrickPrefab, workspace.Entity);
				
			elseif mission.Type == 3 then -- OnComplete
				local mission58 = missionProfile:Get(58);
				if mission.Redo and mission58 and mission58.Type == 3 then
					modReplicationManager.SetClientParent(player, patrickPrefab, game.ReplicatedStorage);
				end

			elseif mission.Type == 4 then -- Failed
				
			end
		end
		
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
	end
end

return MissionLogic;