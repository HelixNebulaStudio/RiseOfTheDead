local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");

local modNpcProfileLibrary = shared.require(game.ReplicatedStorage.Library.NpcProfileLibrary);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

local MISSION_ID = 58;

if RunService:IsServer() then
	local modNpcs = shared.modNpcs;
	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
	function MissionLogic.Init(missionProfile, mission)
		local player: Player = missionProfile.Player;

		local function OnChanged(firstRun)
			if mission.Type == 3 then
				local patrick = modNpcProfileLibrary:Find("Patrick");
				patrick.Class="Survivor";
				patrick.World="Safehome";

				Debugger:Log("Update patrick class")

				if modBranchConfigs.IsWorld("TheMall") then

					local patrickPrefab = workspace.Entity:FindFirstChild("Patrick");
					if patrickPrefab then
						modReplicationManager.SetClientParent(player, patrickPrefab, game.ReplicatedStorage);
					end
					Debugger:Warn("Hide Patrick");
					
				end

			else
				if modBranchConfigs.IsWorld("TheMall") then
					local patrickPrefab = workspace.Entity:FindFirstChild("Patrick");
					if patrickPrefab then
						modReplicationManager.SetClientParent(player, patrickPrefab, workspace.Entity);
					end
				end

				if mission.Type == 1 then -- OnActive
					if modBranchConfigs.IsWorld("DoubleCross") then

					else
						if mission.ProgressionPoint >= 4 and mission.ProgressionPoint <= 6 then
							if firstRun then
								modMission:Progress(player, MISSION_ID, function(mission)
									mission.ProgressionPoint = 3;
								end)
							end

						elseif mission.ProgressionPoint >= 9 and mission.ProgressionPoint <= 16 then
							modMission:Progress(player, MISSION_ID, function(mission)
								mission.ProgressionPoint = 8;
							end)

						end

					end

				end
			end

			if mission.ProgressionPoint >= 17 then
				if modBranchConfigs.IsWorld("Safehome") then
					local patrick = modNpcProfileLibrary:Find("Patrick");
					patrick.Class="Survivor";
					patrick.World="Safehome";

					Debugger:Log("Update patrick class")
				elseif modBranchConfigs.IsWorld("TheMall") then

					local patrickPrefab = workspace.Entity:FindFirstChild("Patrick");
					if patrickPrefab then
						modReplicationManager.SetClientParent(player, patrickPrefab, game.ReplicatedStorage);
					end
					Debugger:Warn("Hide Patrick");

				end
			end
		end
		
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
	end
	
else
	
	function MissionLogic.Init(missionProfile, mission)
		if mission == nil then return end;
		if mission.Type == 3 or (mission.ProgressionPoint >= 17) then
			local patrick = modNpcProfileLibrary:Find("Patrick");
			patrick.Class="Survivor";
			patrick.World="Safehome";

			Debugger:Log("Client>> Update patrick class");
			
			if modBranchConfigs.IsWorld("TheMall") then
				local patrickPrefab;
				repeat
					patrickPrefab = workspace.Entity:FindFirstChild("Patrick");
					if patrickPrefab then
						patrickPrefab.Parent = game.ReplicatedStorage;
						Debugger:Warn("Hide Patrick");
					end
					task.wait(1);
				until false;
			end
		end
	end
	
end

return MissionLogic;