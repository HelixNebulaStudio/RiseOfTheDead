local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);

local MISSION_ID = 88;

local MissionLogic = {};
--==

function MissionLogic.onRequire()
	if RunService:IsServer() then
		modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
    	local modGameModeManager = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager);

        if modGameModeManager.IsGameWorld ~= true then return end;

		shared.modEventService:OnInvoked("GameModeManager_BindGameModeComplete", function(event: EventPacket, packet)
			local room = packet.Room;
			if room.Type ~= "Raid" then return end;

			for _, player in pairs(game.Players:GetPlayers()) do
				local mission = modMission:GetMission(player, MISSION_ID);
				if mission == nil then continue end;
				if room.Stage ~= "North Star Embassy" then continue end;
				if mission.Type ~= 1 or (mission.ProgressionPoint ~= 10 and mission.ProgressionPoint ~= 11) then continue end;
					
				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint == 11 then
						mission.ProgressionPoint = 12;
					end;
				end)
			end
		end)

	elseif RunService:IsClient() then


	end
end

if RunService:IsServer() then
	-- modBranchConfigurations.IsWorld("TheMall")
	
	function MissionLogic.Init(missionProfile: MissionsProfile, mission: Mission)
		local player: Player = missionProfile.Player;

		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable

			elseif mission.Type == 1 then -- OnActive
				if mission.ProgressionPoint == 10 then
					modMission:Progress(player, MISSION_ID, function(mission)
						if mission.ProgressionPoint < 11 then mission.ProgressionPoint = 11; end;
					end)
				end

			elseif mission.Type == 3 then -- OnComplete

			end
		end
		
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
	end
end

return MissionLogic;