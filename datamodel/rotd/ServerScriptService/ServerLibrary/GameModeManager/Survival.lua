local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modGameModeLibrary = shared.require(game.ReplicatedStorage.Library.GameModeLibrary);
local modLeaderboardService = shared.require(game.ReplicatedStorage.Library.LeaderboardService);

local modProfile = shared.require(game.ServerScriptService.ServerLibrary.Profile);
local modServerManager = shared.require(game.ServerScriptService.ServerLibrary.ServerManager);
local modAnalyticsService = shared.require(game.ServerScriptService.ServerLibrary.AnalyticsService);

--==
local GameMode = {};
GameMode.__index = GameMode;
GameMode.Active = nil;

function GameMode:Init(gameTable)
	self.GameTable = gameTable;
end

function GameMode:Start(room)
	local teleportData = modServerManager:CreateTeleportData();
	teleportData.GameMode = {
		Type = self.GameTable.Type;
		Stage = self.GameTable.Stage;
		Room = room;
	};
	
	if RunService:IsStudio() then
		Debugger:Log("Studio-mode: Create and send player to ", {
			WorldId = self.GameTable.StageLib.WorldId;
			Players = room:GetInstancePlayers();
			TeleportData = teleportData;
		});
		return;
	end
	local accessCode = modServerManager:CreatePrivateServer(self.GameTable.StageLib.WorldId);
	modServerManager:TeleportToPrivateServer(self.GameTable.StageLib.WorldId, accessCode, room:GetInstancePlayers(), teleportData);
end

function GameMode:End(room)
	
end

function GameMode:WorldLoad(modeData)
	local gameType = modeData.Type;
	local gameStage = modeData.Stage;
	
	local gameLib = modGameModeLibrary.GetGameMode(gameType);
	local stageLib = gameLib and modGameModeLibrary.GetStage(gameType, gameStage);
	
	local gamemodeModule = game.ServerScriptService:FindFirstChild("ModeWorldScript") or script:FindFirstChild(gameStage)
	
	local gameController;
	if gamemodeModule then
		gameController = shared.require(gamemodeModule);
	end

	if shared.WorldCore and shared.WorldCore.InitGameController then
		gameController = shared.WorldCore.InitGameController();
		shared.WorldCore.GameController = gameController;
	end
	
	if gameController then
		modConfigurations.Set("InfTargeting", true);
		modConfigurations.Set("NpcThinkCycle", 1);

		gameController:Load();
		
		shared.GameController = gameController;
		
		GameMode.Active = gameController;
		if gameController.Initiated == nil then
			task.spawn(function()
				gameController:Initialize(modeData.Room);
				gameController.Initiated = true;
			end)
		end
		gameController.OnComplete = function(players)
		end;
		
		local arenaTimer = tick();
		local completedWave5 = false;
		gameController.OnWaveEnd = function(players, wave)
			task.spawn(function()
				if wave >= 5 and not completedWave5 then
					completedWave5 = true;
					
				end
			end)
			spawn(function()
				for _, player in pairs(players) do
					local profile = modProfile:Get(player);
					profile.Analytics:LogTime("Arena:"..(modeData.Room.IsHard and "Hard-" or "")..gameStage, math.ceil(tick()-arenaTimer));
					
					local playerSave = profile:GetActiveSave();
					if playerSave and playerSave.AddStat then
						if math.fmod(wave, 3) == 0 then
							local perksReward = math.min(math.ceil(wave/3), 3);
							if playerSave:AddStat("Perks", perksReward) > 0 then
								modAnalyticsService:Source{
									Player = player;
									Currency = modAnalyticsService.Currency.Perks;
									Amount = perksReward;
									EndBalance = playerSave:GetStat("Perks");
									ItemSKU = `{gameType}:{gameStage}`;
								};
						
							end

							shared.Notify(player, "You recieved "..perksReward.." Perks for reaching wave "..wave.."!", "Reward");
						end
					end
					
					if modeData.Room.IsHard then
						if stageLib.LeaderboardDataKey then
							spawn(function()
								local modeKey = gameStage..stageLib.LeaderboardDataKey;
								profile.MonthlyStats["LM_H"..modeKey] = math.max((profile.MonthlyStats["LM_H"..modeKey] or 0), wave);
								profile.SeasonlyStats["LS_H"..modeKey] = math.max((profile.SeasonlyStats["LS_H"..modeKey] or 0), wave);
								profile.YearlyStats["LY_H"..modeKey] = math.max((profile.YearlyStats["LY_H"..modeKey] or 0), wave);
								profile.AllTimeStats["LAT_H"..modeKey] = math.max((profile.AllTimeStats["LAT_H"..modeKey] or 0), wave);
								
								modLeaderboardService:SubmitPlayerToBoard(player);
							end)
						end

					else
						if stageLib.LeaderboardDataKey then
							spawn(function()
								local modeKey = gameStage..stageLib.LeaderboardDataKey;
								profile.MonthlyStats["LM_"..modeKey] = math.max((profile.MonthlyStats["LM_"..modeKey] or 0), wave);
								profile.SeasonlyStats["LS_"..modeKey] = math.max((profile.SeasonlyStats["LS_"..modeKey] or 0), wave);
								profile.YearlyStats["LY_"..modeKey] = math.max((profile.YearlyStats["LY_"..modeKey] or 0), wave);
								profile.AllTimeStats["LAT_"..modeKey] = math.max((profile.AllTimeStats["LAT_"..modeKey] or 0), wave);
								
								modLeaderboardService:SubmitPlayerToBoard(player);
							end)
						end

					end

				end
				arenaTimer = tick();
			end)
		end
		
		gameController.OnStart = function(players)
		end
		
	end
end

function GameMode.new(gameTable)
	local self = {};
	
	setmetatable(self, GameMode);
	return self;
end

return GameMode;