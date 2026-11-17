local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local HttpService = game:GetService("HttpService");

local modGlobalVars = shared.require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurationsRotd);

local modCrossServerSignals = shared.require(game.ServerScriptService.ServerLibrary.CrossServerSignals);
local modMatchMakingService = shared.require(game.ServerScriptService.ServerLibrary.MatchMakingService);
local modServerManager = shared.require(game.ServerScriptService.ServerLibrary.ServerManager);


local SERVER_TYPES = {
	Default = {};
	ReapersGames = {
		WorldId = "ReapersGames";
		MinLobbySize = 3;
		MaxLobbySize = 6;
		DeficitDurationMultiplier = 5;
	};
};
--==

function modMatchMakingService.onRequire()
	modMatchMakingService:SetQueueTypesConfig(SERVER_TYPES);

	local crossServerSignal = modCrossServerSignals.new("MatchMaking");

	local function joinServer(queueType, gameLobbyUserIds, worldId, reserveAccessCode)
		local teleportData = modServerManager:CreateTeleportData();
		teleportData.LobbyInfo = {
			QueueType = queueType;
			UserIds = gameLobbyUserIds;
			WorldId = worldId;
			AccessCode = reserveAccessCode;
		}

		local localPlayers = {};
		for _, player in ipairs(game.Players:GetPlayers()) do
			if table.find(gameLobbyUserIds, player.UserId) == nil then
				continue;
			end;
			table.insert(localPlayers, player);
		end

		if #localPlayers <= 0 then
			Debugger:Warn(`No players to join Server:`, gameLobbyUserIds);
			return;
		end

		Debugger:Warn(`Teleporting players ({Debugger:Stringify(localPlayers)}) to {reserveAccessCode}`);
		modServerManager:TeleportToPrivateServer(worldId, reserveAccessCode, localPlayers, teleportData);
	end

	crossServerSignal:Connect(function(action, ...)
		Debugger:Warn(`MatchMaking CS event:`, action, ...);

		if action == "joinserver" then
			local queueType, gameLobbyUserIds, worldId, serverCode = ...;
			joinServer(queueType, gameLobbyUserIds, worldId, serverCode);
		end
	end)

	modMatchMakingService:BindLobbyFormed(function(gameLobby)
		local queueType = gameLobby.QueueType;
		local serverConfig = SERVER_TYPES[queueType];

		Debugger:Warn(`Preparing server queueType={queueType} config=`, serverConfig);

		local worldId = serverConfig.WorldId;
		local reserveAccessCode, privateServerId = modServerManager:CreatePrivateServer(worldId);

		gameLobby.WorldId = worldId;
		gameLobby.AccessCode = reserveAccessCode;
		gameLobby.Values = gameLobby.Values or {};

		if serverConfig and serverConfig.CanJoinInProgress then
			gameLobby.Values.GraceUntil = os.time() + 30;
			gameLobby.Values.StartTime = os.time();
			gameLobby.Values.CanJoinInProgress = true;

		else
			gameLobby.Values.CanJoinInProgress = false;
		end
		gameLobby.Values.JoinedCount = 0;

		crossServerSignal:Fire("joinserver", queueType, gameLobby.UserIds, gameLobby.WorldId, reserveAccessCode);
	end)

	shared.modEngineCore:ConnectOnPlayerAdded(script, function(player: Player)
		local worldInfo = modBranchConfigurations.WorldInfo;
		local worldType = worldInfo.WorldType;
		if worldType ~= 1 then Debugger:Warn(`Not game world`); return; end;

	end);

    shared.modCommandsLibrary.bind{
		["mmrotd"]={
			Permission = shared.modCommandsLibrary.PermissionLevel.Admin;
			Description = [[Matchmaking Admin / test harness.
			/mmrotd <u>t</u>est<u>j</u>oin<u>s</u>erver  -- test join server
			/mmrotd <u>p</u>rint<u>i</u>nfo
			]];

			RequiredArgs = 0;
			UsageInfo = "/mmrotd action [args]";
			Function = function(speaker: Player, args)
				local player = speaker;
				local actionId = args[1];

				if actionId == "testjoinserver" or actionId == "tjs" then
					local serverConfig = SERVER_TYPES.ReapersGames;
					local reserveAccessCode = modServerManager:CreatePrivateServer(serverConfig.WorldId);
					crossServerSignal:Fire("joinserver", "ReapersGames", {player.UserId}, serverConfig.WorldId, reserveAccessCode);
					
				else
					Debugger:Log("MatchMaking: unknown action", tostring(actionId));
				end

				return true;
			end
		};
    };

	if modBranchConfigurations.WorldInfo.OverWorldIndex then
		-- Is overworld
		modMatchMakingService:StartScheduler();
	end
end

return modMatchMakingService;
