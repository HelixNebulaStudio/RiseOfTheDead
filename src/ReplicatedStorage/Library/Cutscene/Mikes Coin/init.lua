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
	modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
end

local luckyCoin = script:WaitForChild("Mike's Lucky Coin");
--== Script;
return function(CutsceneSequence)
	if not modBranchConfigs.IsWorld("Prison") then Debugger:Warn("Invalid place for cutscene ("..script.Name..")"); return; end;

	modOnGameEvents:ConnectEvent("OnGameModeStart", function(player, gameType, gameStage, room)
		if gameType == "Survival" and gameStage == "Prison" then
			modMission:Progress(player, 45, function(mission)
				if mission.ProgressionPoint == 1 then
					mission.ProgressionPoint = 2;
				end;
			end)

		end
	end);
	

	modOnGameEvents:ConnectEvent("OnGameModeComplete", function(player, gameType, gameStage, room)
		if gameType == "Survival" and gameStage == "Prison" then
			modMission:Progress(player, 45, function(mission)
				mission.ProgressionPoint = 3;
			end)
			
		end
	end)
	
	CutsceneSequence:Initialize(function()
		local players = CutsceneSequence:GetPlayers();
		local player = players[1];
		local mission = modMission:GetMission(player, 45);
		if mission == nil then return end;
			
		if not modMission:IsComplete(player, 45) then
			
			local function OnChanged(firstRun)
				if mission.Type == 2 then -- OnAvailable
					
				elseif mission.Type == 1 then -- OnActive
					if mission.ProgressionPoint == 3 then
						local new = luckyCoin:Clone();
						new.Parent = workspace.Interactables;
						modReplicationManager.ReplicateOut(player, new);
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