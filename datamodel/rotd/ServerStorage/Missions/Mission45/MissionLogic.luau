local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local MissionLogic = {};
local RunService = game:GetService("RunService");
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

local MISSION_ID = 45;
if RunService:IsServer() then
	if shared.WorldName ~= "Prison" then return {}; end;

	local modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);

	shared.modEventService:OnInvoked("Survival_BindWaveReached", function(eventPacket: EventPacket, ...)
		local players = eventPacket.Players;
		if players == nil then return end;

		local gameController = ...;

		task.spawn(function()
			if gameController.ModeType ~= "Survival" or gameController.ModeStage ~= "Prison" then return end;
			if gameController.Wave < 5 then return end;
			
			for _, player: Player in pairs(players) do
				if not modMission:Progress(player, MISSION_ID) then continue end;

				modMission:Progress(player, MISSION_ID, function(mission)
					if mission.ProgressionPoint <= 2 then
						mission.ProgressionPoint = 3;
					end
				end)
			end
		end)
	end)
	
	shared.modEventService:OnInvoked("Interactables_BindCollectibleInteract", function(eventPacket: EventPacket, ...)
		local player: Player? = eventPacket.Player;
		if player == nil then return end;

		local interactable: InteractableInstance = ...;

		task.spawn(function()
			if interactable.Id ~= "mlc" then return end;
		
			modMission:Progress(player, MISSION_ID, function(mission)
				if mission.ProgressionPoint <= 4 then
					mission.ProgressionPoint = 4;
				end;
			end)
		end)
	end)

	local luckyCoin = script.Parent:WaitForChild("Mike's Lucky Coin");

	function MissionLogic.Init(missionProfile, mission)
		local player: Player = missionProfile.Player;
		if mission.Type == 3 then return end;
		
		local profile = shared.modProfile:Get(player);
		
		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable

			elseif mission.Type == 1 then -- OnActive
				if mission.ProgressionPoint < 2 then
					modMission:Progress(player, MISSION_ID, function(mission)
						if mission.ProgressionPoint == 1 then
							mission.ProgressionPoint = 2;
						end;
					end)

				elseif mission.ProgressionPoint == 3 then
					local new = luckyCoin:Clone();
					new.Parent = workspace.Interactables;
					modReplicationManager.ReplicateOut(player, new);

					if profile.Collectibles["mlc"] then
						modMission:Progress(player, MISSION_ID, function(mission)
							if mission.ProgressionPoint <= 4 then
								mission.ProgressionPoint = 4;
							end;
						end)
					end

				end
			elseif mission.Type == 3 then -- OnComplete

			end
		end
		
		mission.Changed:Connect(OnChanged);
		OnChanged(true);
	end
end

return MissionLogic;