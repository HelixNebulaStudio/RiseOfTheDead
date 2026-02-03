local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modServerManager = shared.require(game.ServerScriptService.ServerLibrary.ServerManager);
local modProfile = shared.require(game.ServerScriptService.ServerLibrary.Profile);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);

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
		Debugger:StudioLog("Create and send player to ", {
			WorldId = self.GameTable.StageLib.WorldId;
			Players = room:GetInstancePlayers();
			TeleportData = teleportData;
		});
		
		return;
	end
	
	local accessCode = modServerManager:CreatePrivateServer(self.GameTable.StageLib.WorldId);
	modServerManager:TeleportToPrivateServer(
		self.GameTable.StageLib.WorldId, 
		accessCode, 
		room:GetInstancePlayers(), 
		teleportData
	);
end

function GameMode:End(room)
	
end

function GameMode:WorldLoad(modeData)
	local gameType = modeData.Type;
	local gameStage = modeData.Stage;
	
	local gameController;

	if shared.WorldCore and shared.WorldCore.InitGameController then
		gameController = shared.WorldCore.InitGameController();
		shared.WorldCore.GameController = gameController;
	end
	
	if gameController then
		local arenaTimer = tick();

		GameMode.Active = gameController;
		modConfigurations.Set("InfTargeting", true);
		
		gameController.OnComplete = function(players)
			task.spawn(function()
				for _, player in pairs(players) do
					local profile = modProfile:Get(player);
					local timePlayed = math.ceil(tick()-arenaTimer);
					profile.Analytics:LogTime("Arena:"..(modeData.Room.IsHard and "Hard-" or "")..gameStage, timePlayed);
				end
			end)

			shared.modEventService:ServerInvoke("GameModeManager_BindGameModeComplete", {ReplicateTo=players}, {
				Room = gameController.RoomData;
			});
		end;
		
		gameController.OnStart = function(players)
		end

		if gameController.Initiated == nil then
			task.spawn(function()
				modeData.Room.Type = gameType;
				modeData.Room.Stage = gameStage;
				
				gameController:Initialize(modeData.Room);
				gameController.Initiated = true;
			end)
		end
	end
end

function GameMode.new(gameTable)
	local self = {};
	
	setmetatable(self, GameMode);
	return self;
end

return GameMode;