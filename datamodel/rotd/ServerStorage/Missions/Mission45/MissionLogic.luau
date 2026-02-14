local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

local MISSION_ID = 45;
if RunService:IsServer() then
	if not modBranchConfigurations.IsWorld("Prison") then return {}; end;

	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

	shared.modEventService:OnInvoked("GameModeManager_BindGameModeStart", function(eventPacket: EventPacket, packet)
		local room = packet.Room;
		if room.Type ~= "Survival" or room.Stage ~= "Prison" then return end;
		if eventPacket.Players == nil then return end;
		
		for _, player: Player in pairs(eventPacket.Players) do
			if not modMission:Progress(player, MISSION_ID) then continue end;

			modMission:Progress(player, MISSION_ID, function(mission)
				if mission.ProgressionPoint == 1 then
					mission.ProgressionPoint = 2;
				end;
			end)
		end
	end)

	shared.modEventService:OnInvoked("GameModeManager_BindGameModeComplete", function(eventPacket: EventPacket, packet)
		local room = packet.Room;

		if room.Type ~= "Survival" or room.Stage ~= "Prison" then return end;
		if eventPacket.Players == nil then return end;
		
		for _, player: Player in pairs(eventPacket.Players) do
			if not modMission:Progress(player, MISSION_ID) then continue end;

			modMission:Progress(player, MISSION_ID, function(mission)
				mission.ProgressionPoint = 3;
			end)
		end
	end)
	

	local luckyCoin = script.Parent:WaitForChild("Mike's Lucky Coin");

	function MissionLogic.Init(missionProfile, mission)
		local player: Player = missionProfile.Player;

		if mission.Type == 3 then return end;
		
		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable

			elseif mission.Type == 1 then -- OnActive
				if mission.ProgressionPoint == 3 then
					local new = luckyCoin:Clone();
					new.Parent = workspace.Interactables;
					modReplicationManager.ReplicateOut(player, new);
				end
			elseif mission.Type == 3 then -- OnComplete

			end
		end
		
		mission.Changed:Connect(OnChanged);
		OnChanged(true);
	end
end

return MissionLogic;