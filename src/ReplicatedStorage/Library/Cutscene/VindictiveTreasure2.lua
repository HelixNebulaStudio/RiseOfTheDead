local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Client Variables;
local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);

local random = Random.new();
--== Server Variables;
local modPlayers = require(game.ReplicatedStorage.Library.Players);

if RunService:IsServer() then
	modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
	modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
	modMission = require(game.ServerScriptService.ServerLibrary.Mission);
	modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
end

--== Script;
return function(CutsceneSequence)
	if modBranchConfigs.WorldInfo.Type ~= modBranchConfigs.WorldTypes.General then return end;
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player = players[1];
		local mission = modMission:GetMission(player, 41);
		if mission == nil then return end;
			
		spawn(function()
			local classPlayer = modPlayers.Get(player);
			local profile = modProfile:Get(player);
			
			local isOldMission = (os.time()-mission.StartTime) >= (3600*72);
			while player:IsDescendantOf(game.Players) do
				wait(mission.Type ~= 3 and 35 or math.random(600, 900));
				if not player:IsDescendantOf(game.Players) then continue end;
				if isOldMission and math.random(1, 4) >= 2 then continue end;

				if mission.ProgressionPoint <= 2
				or (mission.Type == 1 and mission.ProgressionPoint == 4
				or mission.ProgressionPoint == 5) then
					
					if profile and profile.LastDoorCFrame and classPlayer and classPlayer.IsAlive and classPlayer.Properties.InBossBattle == nil then
						if mission.Type == 3 then
							shared.Notify(player, "You spotted a Cultist doing something suspicious, the Cultist spots you.", "Important");
						end
						modNpc.Spawn("Cultist", profile.LastDoorCFrame, function(npc, npcModule)
							npcModule.Properties.TargetableDistance = 4096;
							npcModule.OnTarget(player);
						end);
					end
				end
			end
		end)
		
		if not modMission:IsComplete(player, 41) then
			
			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable
					
				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 1 then

					elseif mission.ProgressionPoint == 2 then

					end
				elseif mission.Type == 3 then -- OnComplete

					mission.Changed:Disconnect(OnChanged);
				end
			end
			mission.Changed:Connect(OnChanged);
			OnChanged(true, mission);
		else -- Loading Completed
			
		end
	end)
	
	return CutsceneSequence;
end;