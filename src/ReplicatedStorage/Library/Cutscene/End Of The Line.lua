local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);

local random = Random.new();
--== Server Variables;
if RunService:IsServer() then
	modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
	modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = require(game.ServerScriptService.ServerLibrary.Mission);
end

--== Script;
return function(CutsceneSequence)
	if modBranchConfigs.IsWorld("TheResidentials") then
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player = players[1];
			local mission = modMission:GetMission(player, 56);
			if mission == nil then return end;
			
			local classPlayer = shared.modPlayers.Get(player);
			
			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable
					
				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 1 then

					elseif mission.ProgressionPoint == 2 then
						
						local coopEntrancePos = Vector3.new(1060.251, -20.875, -126.729);
						repeat
							wait(1)
						until not player:IsDescendantOf(game.Players) or (classPlayer.RootPart.Position-coopEntrancePos).Magnitude <= 14;
						
						modMission:Progress(player, 56, function(mission)
							if mission.ProgressionPoint == 2 then mission.ProgressionPoint = 3; end;
						end)
					end
				elseif mission.Type == 3 then -- OnComplete


				end
			end
			mission.Changed:Connect(OnChanged);
			OnChanged(true, mission);
		end)
	
	elseif modBranchConfigs.IsWorld("Genesis") then
		CutsceneSequence:Initialize(function()
			local players = CutsceneSequence:GetPlayers();
			local player = players[1];
			local mission = modMission:GetMission(player, 56);
			if mission == nil then return end;
			
			local classPlayer = shared.modPlayers.Get(player);
			
			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable
					
				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 1 then

					elseif mission.ProgressionPoint == 2 then
						
					end
				elseif mission.Type == 3 then -- OnComplete


				end
			end
			mission.Changed:Connect(OnChanged);
			OnChanged(true, mission);
		end)
		
	end
	return CutsceneSequence;
end;