local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);
local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modGameModeLibrary = require(game.ReplicatedStorage.Library.GameModeLibrary);
local modLeaderboardService = require(game.ReplicatedStorage.Library.LeaderboardService);

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
	
	local arenaTimer = tick();
	
	local gamemodeModule = game.ServerScriptService:FindFirstChild("ModeWorldScript") or script:FindFirstChild(gameStage)
	if gamemodeModule then
		local gameController = require(gamemodeModule);
		shared.GameController = gameController;
		
		GameMode.Active = gameController;
		if GameMode.Active.Initiated == nil then
			spawn(function()
				GameMode.Active:Initialize(modeData.Room);
				GameMode.Active.Initiated = true;
			end)
		end
		GameMode.Active.OnComplete = function(players)
			spawn(function()
				for _, player in pairs(players) do
					modAnalytics.RecordProgression(player.UserId, "Complete", gameType..":"..(modeData.Room.IsHard and "Hard-" or "")..gameStage);
					
					local profile = modProfile:Get(player);
					local timePlayed = math.ceil(tick()-arenaTimer);
					profile.Analytics:LogTime("Arena:"..(modeData.Room.IsHard and "Hard-" or "")..gameStage, timePlayed);
				end
			end)
		end;
		
	end
end

function GameMode.new(gameTable)
	local self = {};
	
	setmetatable(self, GameMode);
	return self;
end

return GameMode;