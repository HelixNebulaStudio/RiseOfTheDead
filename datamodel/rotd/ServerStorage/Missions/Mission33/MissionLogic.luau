local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

local MissionLogic = {};

local MISSION_ID = 33;
if RunService:IsServer() then
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
	function MissionLogic.Init(missionProfile, mission)
		local player: Player = missionProfile.Player;

		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable
				if shared.WorldName == "TheMall" then
					local patrickPrefab = workspace.Entity:FindFirstChild("Patrick");
					if patrickPrefab then
						modReplicationManager.SetClientParent(player, patrickPrefab, workspace.Entity);
					end
				end
				
			elseif mission.Type == 1 then -- OnActive
				if shared.WorldName ==  "TheMall" then
					local patrickPrefab = workspace.Entity:FindFirstChild("Patrick");
					if patrickPrefab then
						modReplicationManager.SetClientParent(player, patrickPrefab, workspace.Entity);
					end
				end

				if shared.WorldName == "BanditOutpost" then
					if firstRun then
						Debugger:Log("Awoken the bear script.");
					end

				elseif shared.WorldName ~= "AwokenTheBear" then
					if mission.ProgressionPoint > 3 and mission.ProgressionPoint < 13 then
						Debugger:Warn(`Rewind mission 33 to point 3`);
						modMission:FailMission(player, MISSION_ID, "You left Stan in the Bandit Camp.");

					elseif mission.ProgressionPoint >= 13 then
						Debugger:Warn(`Rewind mission 33 to point 3`);
						modMission:FailMission(player, MISSION_ID, "You left Stan in the Bandit Camp.");

					end

				else
					if mission.ProgressionPoint <= 3 then
						modMission:Progress(player, MISSION_ID, function(mission)
							if mission.ProgressionPoint <= 3 then
								mission.ProgressionPoint = 4;
							end;
						end)
					end

				end
				
			elseif mission.Type == 3 then -- OnComplete
				if shared.WorldName == "TheMall" then
					local patrickClass = shared.modNpcs.matchNpc(function(npcClass: NpcClass)
						if npcClass.Player then return end;
						if npcClass.Name ~= "Patrick" then return end;
						return true;
					end);

					if patrickClass then
						local mission58 = missionProfile:Get(58);
						if mission.Redo and mission58 and mission58.Type == 3 then
							modReplicationManager.SetClientParent(player, patrickClass.Character, game.ReplicatedStorage);
						end
					end
				end

			elseif mission.Type == 4 then -- Failed
				
			end
		end
		
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
	end
end

return MissionLogic;