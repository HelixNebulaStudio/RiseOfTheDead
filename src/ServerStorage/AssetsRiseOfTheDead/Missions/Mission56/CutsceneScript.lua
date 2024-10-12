local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);

--== Variables;
local missionId = 56;

if RunService:IsServer() then
	modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
	modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	
else
	modData = require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);
	
end

--== Script;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("TheResidentials") then return end;
	-- MARK: TheResidentials

	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player: Player = players[1];
		local mission = modMission:GetMission(player, missionId);
		if mission == nil then return end;
		
		local classPlayer = shared.modPlayers.Get(player);
			
		local function OnChanged(firstRun)
			if mission.Type == 2 then -- OnAvailable
				
			elseif mission.Type == 1 then -- OnActive
				if mission.ProgressionPoint == 1 then

				elseif mission.ProgressionPoint == 2 then
					
					local coopEntrancePos = Vector3.new(1060.251, -20.875, -126.729);
					local distFromEntrance = math.huge;
					repeat
						wait(1);
						distFromEntrance = (classPlayer.RootPart.Position-coopEntrancePos).Magnitude;
					until not player:IsDescendantOf(game.Players) or distFromEntrance <= 14;
					
					modMission:Progress(player, missionId, function(mission)
						if mission.ProgressionPoint == 2 then mission.ProgressionPoint = 3; end;
					end)
				end
			elseif mission.Type == 3 then -- OnComplete


			end
		end
		mission.Changed:Connect(OnChanged);
		OnChanged(true);
	end)

	return CutsceneSequence;
end;