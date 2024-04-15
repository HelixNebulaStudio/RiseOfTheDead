local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modServerManager = require(game.ServerScriptService.ServerLibrary.ServerManager);
local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);
local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

--==
local GameMode = {};
GameMode.__index = GameMode;

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
	
	local gamemodeModule = game.ServerScriptService:FindFirstChild("ModeWorldScript") or script:FindFirstChild(gameStage)
	if gamemodeModule then
		local arenaTimer = tick();
		local gameController = require(gamemodeModule);
		shared.GameController = gameController;
		
		GameMode.Active = gameController;

		modConfigurations.Set("InfTargeting", true);
		
		gameController.OnComplete = function(players)
			task.spawn(function()
				for _, player in pairs(players) do
					modOnGameEvents:Fire("OnGameModeComplete", player, gameType, gameStage, modeData.Room);
					modAnalytics.RecordProgression(player.UserId, "Complete", gameType..":"..(modeData.Room.IsHard and "Hard-" or "")..gameStage);
					
					local profile = modProfile:Get(player);
					local timePlayed = math.ceil(tick()-arenaTimer);
					profile.Analytics:LogTime("Arena:"..(modeData.Room.IsHard and "Hard-" or "")..gameStage, timePlayed);
				end
			end)
		end;
		
		gameController.OnStart = function(players)
			task.spawn(function()
				for _, player in pairs(players) do
					modOnGameEvents:Fire("OnGameModeStart", player, gameType, gameStage, modeData.Room);
				end
			end);
		end

		if gameController.Initiated == nil then
			task.spawn(function()
				gameController:Initialize(modeData.Room);
				gameController.Initiated = true;
			end)
		end
		--GameMode.Active:Initialize(modeData.Room);
	end
end

function GameMode.new(gameTable)
	local self = {};
	
	setmetatable(self, GameMode);
	return self;
end

return GameMode;