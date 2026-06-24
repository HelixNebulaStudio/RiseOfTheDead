local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");

local modNpcProfileLibrary = shared.require(game.ReplicatedStorage.Library.NpcProfileLibrary);
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
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
				patrick.Class = "Survivor";
				patrick.World = "Safehome";

				Debugger:Log("Update patrick class")

				if shared.WorldName == "TheMall" then
					local patrickClass = modNpcs.matchNpc(function(npcClass: NpcClass)
						if npcClass.Player then return end;
						if npcClass.Name ~= "Patrick" then return end;
						return true;
					end);

					if patrickClass then
						modReplicationManager.SetClientParent(player, patrickClass.Character, game.ReplicatedStorage);
					end
					Debugger:Warn("Hide Patrick 1");
					
				end

			else
				if shared.WorldName == "TheMall" then
					local patrickClass = modNpcs.matchNpc(function(npcClass: NpcClass)
						if npcClass.Player then return end;
						if npcClass.Name ~= "Patrick" then return end;
						return true;
					end);

					if patrickClass then
						modReplicationManager.SetClientParent(player, patrickClass.Character, workspace.Entity);
					end

				end

				if mission.Type == 1 then -- OnActive
					if shared.WorldName == "DoubleCross" then

					else
						if mission.Redo then
							if shared.WorldName == "TheHarbor" then
								local caitlinClass = modNpcs.matchNpc(function(npcClass: NpcClass)
									if npcClass.Player then return end;
									if npcClass.Name ~= "Caitlin" then return end;
									return true;
								end);

								if mission.ProgressionPoint >= 1 and mission.ProgressionPoint <= 3 then
									modReplicationManager.SetClientParent(player, caitlinClass.Character, workspace.Entity);
								elseif mission.ProgressionPoint > 4 then
									modReplicationManager.SetClientParent(player, caitlinClass.Character, game.ReplicatedStorage);
								end
							end

						else


						end
						
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
				if shared.WorldName == "Safehome" then
					local patrick = modNpcProfileLibrary:Find("Patrick");
					patrick.Class = "Survivor";
					patrick.World = "Safehome";

					Debugger:Log("Update patrick class")

				elseif shared.WorldName == "TheMall" then
					local patrickClass = modNpcs.matchNpc(function(npcClass: NpcClass)
						if npcClass.Player then return end;
						if npcClass.Name ~= "Patrick" then return end;
						return true;
					end);
					if patrickClass then
						modReplicationManager.SetClientParent(player, patrickClass.Character, game.ReplicatedStorage);
					end
					Debugger:Warn("Hide Patrick 2");

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
		end
	end
	
end

return MissionLogic;