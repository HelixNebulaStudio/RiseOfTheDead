local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

--== Variables;
local MISSION_ID = 56;

if RunService:IsServer() then
	modNpcs = shared.modNpcs;
	modStorage = shared.require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
	
else
	modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigurations.IsWorld("TheResidentials") then return end;
	-- MARK: TheResidentials

	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, MISSION_ID);
		if mission == nil then return end;
		
		local playerClass: PlayerClass = shared.modPlayers.get(player);
			
		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable
				
			elseif mission.Type == 1 then -- OnActive
				if mission.ProgressionPoint == 1 then

				elseif mission.ProgressionPoint == 2 then
					local coopEntrancePos = Vector3.new(1060.251, -20.875, -126.729);
					local distFromEntrance = math.huge;
					repeat
						wait(1);
						distFromEntrance = (playerClass.RootPart.Position-coopEntrancePos).Magnitude;
					until not player:IsDescendantOf(game.Players) or distFromEntrance <= 14;
					
					modMission:Progress(player, MISSION_ID, function(mission)
						if mission.ProgressionPoint == 2 then mission.ProgressionPoint = 3; end;
					end)
					
				end
			elseif mission.Type == 3 then -- OnComplete


			end
		end
		mission.OnChanged:Connect(OnChanged);
		OnChanged(true);
	end)

	return CutsceneSequence;
end;