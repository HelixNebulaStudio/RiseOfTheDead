local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local RunService = game:GetService("RunService");

local modGlobalVars = shared.require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modPlayers = shared.require(game.ReplicatedStorage.Library.Players);
local modServerManager = shared.require(game.ServerScriptService.ServerLibrary.ServerManager);
local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);
local modGameModeLibrary = shared.require(game.ReplicatedStorage.Library.GameModeLibrary);
local modAnalytics = shared.require(game.ServerScriptService.ServerLibrary.GameAnalytics);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modLeaderboardService = shared.require(game.ReplicatedStorage.Library.LeaderboardService);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);

local modMatchMaking = shared.require(game.ServerScriptService.ServerLibrary.MatchMaking);
local modOnGameEvents = shared.require(game.ServerScriptService.ServerLibrary.OnGameEvents);

local GameModeManager = {};
GameModeManager.Load = nil;
GameModeManager.Games = {};
GameModeManager.MenuRooms = {};
GameModeManager.Lobbies = {};
GameModeManager.IsGameWorld = nil;
GameModeManager.GameWorldInfo = nil;
GameModeManager.Active = nil;
GameModeManager.StudioData = nil;
GameModeManager.TeleportDataLoaded = nil;


local remoteGameModeLobbies;
local remoteGameModeUpdate;
local remoteGameModeRequest;
local remoteGameModeExit;
local remoteGameModeHud;
local remoteGameModeAssign;

local enumRequests = modGameModeLibrary.RequestEnums;
local enumRoomStates = modGameModeLibrary.RoomStatesEnums;

local lobbyPrefabs;

local endingDuration = 15;

local loaded = false;
--== Script;
function GameModeManager.onRequire()
	lobbyPrefabs = game.ServerStorage.Prefabs:WaitForChild("LobbyRooms");

	remoteGameModeLobbies = modRemotesManager:Get("GameModeLobbies");
	remoteGameModeUpdate = modRemotesManager:Get("GameModeUpdate");
	remoteGameModeRequest = modRemotesManager:Get("GameModeRequest");
	remoteGameModeExit = modRemotesManager:Get("GameModeExit");
	remoteGameModeHud = modRemotesManager:Get("GameModeHud");
	remoteGameModeAssign = modRemotesManager:Get("GameModeAssign");

	function remoteGameModeLobbies.OnServerInvoke(player, action, ...)
		local rPacket = {};
		if remoteGameModeLobbies:Debounce(player) then return rPacket; end;

		local playerClass: PlayerClass = shared.modPlayers.get(player);

		local profile: Profile = shared.modProfile:Get(player);
		local gameSave = profile:GetActiveSave();
		local inventory = profile.ActiveInventory;

		local gameMode, gameStage;
		
		if action == "map" then
			if modConfigurations.DisableMapItems then return rPacket; end;
			local mapSiid = ...;

			local storageItem = inventory and inventory:Find(mapSiid);
			if storageItem == nil then 
				Debugger:Warn("StorageItem(",mapSiid,") does not exist."); 
				rPacket.FailMsg = `StorageItem does not exist.`;
				return rPacket;
			end;

			local itemLib = storageItem.Library;
			if itemLib == nil or itemLib.GameMode == nil then
				Debugger:Warn(`StorageItem({storageItem.ItemId}) does not have a GameMode.`);
				rPacket.FailMsg = `Invalid StorageItem.`;
				return rPacket;
			end
			
			gameMode = itemLib.GameMode.Mode;
			gameStage = itemLib.GameMode.Stage;

		elseif action == "door" then
			local interactConfig = ...;

			local interactable: InteractableInstance = modInteractables.getOrNew(interactConfig);
			local interactPart = interactable.Part;
			if interactPart == nil then
				rPacket.FailMsg = `Missing interactable part.`;
				return rPacket;
			end;
			if player:DistanceFromCharacter(interactPart.Position) > 32 then
				rPacket.FailMsg = `Too far from interactable.`;
				return rPacket;
			end;

			gameMode = interactable.Values.Mode;
			gameStage = interactable.Values.Stage;

		end

		if gameMode == nil or gameStage == nil then 
			rPacket.FailMsg = `Invalid game mode or stage.`;
			return rPacket;
		end;

		-- if gameStage == "Random" then
		-- 	local ownerPlayer = modServerManager.PrivateWorldCreator;
		-- 	local isOwner = player == ownerPlayer;
			
		-- 	if RunService:IsStudio() then
		-- 		isOwner = true;
		-- 	end
			
		-- 	if isOwner then
		-- 		local stageSelect = paramPacket.StageSelect;
				
		-- 		local list = {};
		-- 		for k, v in pairs(modGameModeLibrary.GameModes.Boss.Stages) do
		-- 			if v.IsExtreme ~= true then
		-- 				table.insert(list, k);
		-- 			end
		-- 		end
				
		-- 		if table.find(list, stageSelect) then
		-- 			gameStage = stageSelect;
		-- 			interactData.RandomStage = gameStage;
		-- 		end
		-- 	else
		-- 		gameStage = interactData.RandomStage or "The Prisoner";
		-- 	end
		-- end
		
		local gameLib = modGameModeLibrary.GetGameMode(gameMode);
		local stageLib = gameLib and modGameModeLibrary.GetStage(gameMode, gameStage);
		
		if stageLib == nil then
			Debugger:Warn("Game door missing stageLib.");
			rPacket.FailMsg = `Missing stage library.`;
			return rPacket;
		end;
		
		if playerClass.GameModeAccess == nil then
			playerClass.GameModeAccess = {};
		end
		playerClass.GameModeAccess[gameMode..":"..gameStage] = true;
			

		local gameTable = GameModeManager:GetActive(gameMode, gameStage);
		if gameTable == nil then
			gameTable = GameModeManager:Initialize(gameMode, gameStage);
		end;
		
		gameTable = GameModeManager:GetActive(gameMode, gameStage);
		gameTable.IsGameWorld = GameModeManager.IsGameWorld;
		
		if GameModeManager.IsGameWorld and GameModeManager.Active then
			gameTable.GameWorldInfo = {
				Status=GameModeManager.Active.Status;
			};
		end
		
		rPacket.Success = true;
		rPacket.LobbyData = gameTable;

		return rPacket;
	end


	function remoteGameModeRequest.OnServerInvoke(player, requestEnum, ...)
		if remoteGameModeRequest:Debounce(player) then return end;
		
		if requestEnum == enumRequests.OpenInterface then
			local gameType, gameStage = ...;
			
			return GameModeManager:ConnectPlayer(player, gameType, gameStage);
			
		elseif requestEnum == enumRequests.CloseInterface then

			local gameTable = GameModeManager:GetPlayerMenuRoom(player);
			if gameTable then
				local room = gameTable:GetPlayerRoom(player);
				if room then
					room:RemovePlayer(player);
				end
				
			end

			GameModeManager:DisconnectPlayer(player);
			
		elseif requestEnum == enumRequests.JoinRoom then
			local roomId = ...;
			Debugger:Log("JoinRoom", ...);
			
			local gameTable = GameModeManager:GetPlayerMenuRoom(player);
			if gameTable == nil then
				Debugger:WarnClient(player, "Player not in any menu lobbies.");
				Debugger:Log("JoinRoom", ..., "Player not in any menu lobbies.");
				return;
			end
			
			local gameType, gameStage = gameTable.Type, gameTable.Stage;
			
			local playerRoom = gameTable:GetPlayerRoom(player);
			if playerRoom  then
				Debugger:WarnClient(player, "Player already in room id: "..playerRoom.Id..".");
				Debugger:Log("JoinRoom", ..., "Player already in room id: "..playerRoom.Id..".");
				return
			end
			
			local room = gameTable:GetIdRoom(roomId or "nil");
			if room == nil then
				Debugger:WarnClient(player, "Attempt to join non-existent room: "..(roomId or "nil")..".");
				Debugger:Log("JoinRoom", ..., "Attempt to join non-existent room: "..(roomId or "nil")..".");
				return
			end

			local classPlayer = modPlayers.get(player);
			if classPlayer.GameModeAccess == nil or classPlayer.GameModeAccess[gameType..":"..gameStage] ~= true then
				Debugger:WarnClient(player, `Invalid game room. {gameType}:{gameStage}`);
				return;
			end
			
			return GameModeManager:JoinRoom(player, gameTable, room);
			
		elseif requestEnum == enumRequests.LeaveRoom then
			local gameTable = GameModeManager:GetPlayerMenuRoom(player);
			if gameTable == nil then
				Debugger:WarnClient(player, "Player not in any menu lobbies.");
				return;
			end
			
			local room = gameTable:GetPlayerRoom(player);
			if room == nil then
				Debugger:WarnClient(player, "Player not in any room.");
				return
			end
			
			room:RemovePlayer(player);
			GameModeManager:TpLobbyBox(gameTable, player);
			
			return gameTable;
			
		elseif requestEnum == enumRequests.Ready then
			Debugger:Log("Ready", ...);
			
			local gameTable = GameModeManager:GetPlayerMenuRoom(player);
			if gameTable == nil then
				Debugger:WarnClient(player, "Player not in any menu lobbies.");
				Debugger:Log("Ready", ..., "Player not in any menu lobbies.");
				return;
			end
			
			local room = gameTable:GetPlayerRoom(player);
			if room == nil then
				Debugger:WarnClient(player, "Player not in any room.");
				Debugger:Log("Ready", ..., "Player not in any room.");
				return
			end
			
			if not room:SetReady(player, true) then
				Debugger:WarnClient(player, "Player not in room.");
				Debugger:Log("Ready", ..., "Player not in room.");
				return
			end
			
			return gameTable;
			
		elseif requestEnum == enumRequests.Unready then
			local gameTable = GameModeManager:GetPlayerMenuRoom(player);
			if gameTable == nil then
				Debugger:WarnClient(player, "Player not in any menu lobbies.");
				return;
			end
			
			local room = gameTable:GetPlayerRoom(player);
			if room == nil then
				Debugger:WarnClient(player, "Player not in any room.");
				return
			end
			
			if not room:SetReady(player, false) then
				Debugger:WarnClient(player, "Player not in room.");
				return
			end
			
			return gameTable;
			
		elseif requestEnum == enumRequests.CreateRoom then
			local roomConfig = ...;
			roomConfig = roomConfig or {};

			local isPublic, isHard = roomConfig.IsPublic, roomConfig.IsHard;
			local skipJoiningRoom = false;
			if roomConfig.SkipJoinRoom then
				skipJoiningRoom = true;
			end

			local gameTable = GameModeManager:GetPlayerMenuRoom(player);
			if gameTable == nil then
				Debugger:WarnClient(player, "Player not in any menu lobbies.");
				return;
			end
		
			local room = gameTable:GetPlayerRoom(player);
			if room then
				Debugger:WarnClient(player, "Player already in a room.");
				return;
			end
			
			if #gameTable.Lobbies > (gameTable.GameLib.MaxRooms or 8) or gameTable.StageLib.SingleArena == true then
				Debugger:WarnClient(player, "Maxed out number of rooms.");
				return;
			end
			
			room = gameTable:NewRoom(isPublic, isHard);
			task.wait(0.5);
			if skipJoiningRoom == false then
				GameModeManager:JoinRoom(player, gameTable, room);
			end
			
			return gameTable, room.Id;
		end

		return;
	end

	function remoteGameModeExit.OnServerInvoke(player, action, interactModule)
		if remoteGameModeExit:Debounce(player) then return end;
		local playerClass: PlayerClass = modPlayers.get(player);
		
		if playerClass.HealthComp.IsDead then
			return GameModeManager:ExitGamemodeWorld(player);
		end
		
		if action == "lobbyexitgame" then
			return GameModeManager:ExitGamemodeWorld(player);
		end
		
		local interactObject = action;
		
		if interactObject == nil or interactModule == nil then Debugger:StudioWarn("Missing valid interactable."); return end;
		if player:DistanceFromCharacter(interactObject.Position) > 20 then Debugger:StudioWarn("Player too far from interactable."); return end;
		
		local interactData = shared.saferequire(player, interactModule);
		if interactData == nil then Debugger:StudioWarn("Missing interactable data."); return end;
		
		if GameModeManager.GameWorldInfo == nil then
			Debugger:Warn("Exiting non-game world.")
			modOnGameEvents:Fire("OnGameModeExit", player, interactData);
				
			return modServerManager:Travel(player, "MainMenu");
		end;
		
		
		if interactData.Enabled then
			modOnGameEvents:Fire("OnGameModeExit", player, interactData);
			
			return GameModeManager:ExitGamemodeWorld(player);
		end
		return false;
	end

	modPlayers.OnPlayerDied:Connect(function(classPlayer)
		--Debugger:Log(classPlayer.Name," died, removing from room.")
		GameModeManager:Purge(classPlayer:GetInstance());
	end)

	game.Players.PlayerRemoving:Connect(function(player)
		task.wait(1);
		GameModeManager:Purge(player);
		GameModeManager:Clean();
	end)

	shared.modEngineCore:ConnectOnPlayerAdded(script, function(player)
		GameModeManager:Purge(player);
	end);

	modSyncTime.GetClock():GetPropertyChangedSignal("Value"):Connect(function()
		for gameType, _ in pairs(GameModeManager.Games) do
			for gameStage, gameTable in pairs(GameModeManager.Games[gameType]) do
				gameTable:Sync();
			end
		end
	end);

	task.spawn(function()
		Debugger.AwaitShared("modCommandsLibrary");

		shared.modCommandsLibrary:HookChatCommand("gamemode", {
			Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;

			RequiredArgs = 0;
			UsageInfo = "/gamemode action";
			Description = [[Game mode commands:
				/gamemode join modeId stageId

					e.g. /gamemode join Raid Tombs
			]];
			Function = function(player, args)
				--local profile = shared.modProfile:Get(player);

				local action = args[1];

				if action == "join" then
					local gameId = args[2];
					local stageId = args[3];

					GameModeManager:Assign(player, gameId, stageId);

					local gameTable = GameModeManager:GetActive(gameId, stageId);
					if gameTable == nil then
						shared.Notify(player, `Could not load {gameId}:{stageId}`, "Negative");
						return;
					end
					shared.Notify(player, `Attempting to join {gameId}:{stageId}`, "Inform");
				end
				
				return true;
			end;
		});
	end)

end

function GameModeManager:OnPlayerJoin(player)
	local joinData = player:GetJoinData();
	local teleportData = joinData.TeleportData;
	
	if modBranchConfigs.CurrentBranch.Name == "Dev" 
	and GameModeManager.StudioData 
	and GameModeManager.StudioData.ForceDevBranchTpData == true then
		Debugger:Warn(`Overriding teleport data ({ Debugger:Stringify(teleportData) })`);
		teleportData = GameModeManager.StudioData;


	elseif teleportData == nil 
	and (modBranchConfigs.CurrentBranch.Name == "Dev" or RunService:IsStudio()) 
	and GameModeManager.StudioData then
		Debugger:Warn("No teleport data, using studio teleport data.");
		teleportData = GameModeManager.StudioData;


	end;


	if teleportData and teleportData.GameMode and GameModeManager.TeleportDataLoaded ~= true then
		GameModeManager.TeleportData = teleportData;
		GameModeManager.TeleportDataLoaded = true;
		
		local gameType = teleportData.GameMode.Type;
		local gameStage = teleportData.GameMode.Stage;
			
		local gameLib = modGameModeLibrary.GetGameMode(gameType);
		local stageLib = gameLib and modGameModeLibrary.GetStage(gameType, gameStage);
		
		teleportData.GameMode.GameLib = gameLib;
		teleportData.GameMode.StageLib = stageLib;
		
		if gameLib then
			if gameLib.Module and script:FindFirstChild(gameLib.Module) then
				local system = shared.require(script[gameLib.Module]);
				
				GameModeManager.IsGameWorld = true;
				GameModeManager.GameWorldInfo = teleportData.GameMode;
				
				if system.WorldLoad then
					system:WorldLoad(teleportData.GameMode);
					GameModeManager.Active = system.Active;
				end
				
				if stageLib and stageLib.LeaderboardKeyTable then
					modLeaderboardService.Init(stageLib.LeaderboardKeyTable);
				end
				
				if GameModeManager.Load and not loaded then
					loaded = true;
					task.spawn(function()
						GameModeManager:Load();
					end)
				end
			end
		end
	end

	if GameModeManager.IsGameWorld ~= true then
		GameModeManager.IsGameWorld = false;
	end
end

function GameModeManager:GetActive(gameType, gameStage)
	return GameModeManager.Games[gameType] and GameModeManager.Games[gameType][gameStage];
end

function GameModeManager:GetPlayerMenuRoom(player)
	for a=1, #GameModeManager.MenuRooms do
		local menuRoomData = GameModeManager.MenuRooms[a];
		menuRoomData.MenuRoom:Refresh();
		if menuRoomData.MenuRoom:GetPlayer(player) then
			return menuRoomData.GameTable;
		end;
	end
	return;
end

function GameModeManager:RemovePlayerFromMenuRoom(player)
	for a=1, #GameModeManager.MenuRooms do
		local menuRoomData = GameModeManager.MenuRooms[a];
		menuRoomData.MenuRoom:RemovePlayer(player);
		menuRoomData.GameTable:Refresh();
	end
end

function GameModeManager:GetPlayerLobby(player)
	for a=#GameModeManager.Lobbies, 1, -1  do
		for b=#GameModeManager.Lobbies[a].Players, 1, -1  do
			if GameModeManager.Lobbies[a].Players[b].Name == player.Name then
				return GameModeManager.Lobbies[a], a;
			end
		end
	end
	return;
end

function GameModeManager:Initialize(gameType, gameStage)
	local gameLib = modGameModeLibrary.GetGameMode(gameType);
	local stageLib = gameLib and modGameModeLibrary.GetStage(gameType, gameStage);
	
	if stageLib == nil then Debugger:Warn("Unknown game mode",gameType,", ",gameStage); return end;
	if GameModeManager.Games[gameType] == nil then GameModeManager.Games[gameType] = {} end;
	if GameModeManager.Games[gameType][gameStage] == nil then
		GameModeManager.Games[gameType][gameStage] = setmetatable({}, {});
	end;
	local gameTable = GameModeManager.Games[gameType][gameStage];
	
	if gameTable.Initialized then return end;
	local meta = getmetatable(gameTable);
	meta.__index = meta;
	
	meta.Initialized = true;
	meta.GameLib = gameLib;
	meta.StageLib = stageLib;
	meta.MenuRoom = modMatchMaking.Room.new();
	meta.IdCounter = 1;
	meta.RoomSpots = {};
	
	gameTable.SingleArena = stageLib.SingleArena;
	
	if gameLib.Module == nil or script:FindFirstChild(gameLib.Module) == nil then
		error("GameModeManager>>  Game: "..gameType.." is missing module.");
	end
	
	meta.System = shared.require(script[gameLib.Module]).new();
	meta.System:Init(gameTable);
	
	function meta:Sync()
		for a=1, #self.MenuRoom.Players do
			local playerName = self.MenuRoom.Players[a].Name;
			if game.Players:FindFirstChild(playerName) then
				remoteGameModeUpdate:FireClient(game.Players[playerName], "synclobby", self);
			end
		end
	end
	
	function meta:NewRoom(isPublic, isHard)
		if #self.Lobbies > 0 and stageLib.SingleArena then return end;
		
		local room = modMatchMaking.Room.new();
		local roomMeta = getmetatable(room);
		roomMeta.OnStateChanged = shared.EventSignal.new("OnRoomStateChanged");
		roomMeta.LastPlayerChanged = 0;
		roomMeta.Prefabs = {};
		
		roomMeta.Type = gameType;
		roomMeta.Stage = gameStage;
		
		function roomMeta:SetHard(value)
			self.IsHard = value;
			gameTable:Sync();
			self.OnStateChanged:Fire();
		end
		
		room.IsPublic = isPublic ~= false;
		room.IsHard = isHard;
		room.Id = meta.IdCounter;
		room.State = enumRoomStates.Idle;
		room.MaxPlayers = stageLib.MaxPlayers;
		meta.IdCounter = meta.IdCounter +1;
		
		local newLobbyPrefab: Model = lobbyPrefabs:FindFirstChild(self.Stage.."Lobby") and lobbyPrefabs[self.Stage.."Lobby"]:Clone() or nil;
		if newLobbyPrefab == nil then
			newLobbyPrefab = lobbyPrefabs:WaitForChild("TemplateLobby"):Clone();
		end
		if newLobbyPrefab then
			newLobbyPrefab:AddTag("LobbyPrefab");
			newLobbyPrefab.Parent = workspace.Environment;
			
			local spotIndex = 0;
			for a=0, 9 do
				if gameTable.RoomSpots[a] == nil then
					gameTable.RoomSpots[a] = room;
					spotIndex = a;
					break;
				end
			end
			
			if stageLib.SingleArena ~= true then
				local cf = newLobbyPrefab:GetPivot() * CFrame.new(0, (newLobbyPrefab:GetExtentsSize().Y + 50)*spotIndex, 0);
				newLobbyPrefab:PivotTo(cf);
			end
			
			room.LobbyPrefab = newLobbyPrefab;
			table.insert(roomMeta.Prefabs, newLobbyPrefab);
		end
		
		function roomMeta:SetState(stateEnum)
			if self.State == stateEnum then return end;
			self.State = stateEnum;
			gameTable:Sync();
			self.OnStateChanged:Fire();
		end
		
		local function StartRoom(canStart)
			if room.State >= enumRoomStates.InProgress then return end;

			if canStart ~= true then
				room.StartTime = nil;
				room:SetState(enumRoomStates.Idle);
				gameTable:Sync();
				return;
			end
			
			if room.State == enumRoomStates.Intermission then
				for a=1, #room.Players do
					task.spawn(function()
						local player = room.Players[a] and room.Players[a].Instance;
						if player then
							local playerClass: PlayerClass = modPlayers.get(player);
							if playerClass and playerClass.RootPart then
								playerClass.RootPart.Anchored = false;
							end

							if room.IsHard then
								local hardItemId = gameTable.StageLib.HardModeItem;
								
								if player and player.Character then
									local toolModel = hardItemId and player.Character:FindFirstChild(hardItemId);
									local storageItemID = toolModel and toolModel:GetAttribute("StorageItemId");
									if storageItemID then
										local profile = shared.modProfile:Get(player);
										local inventory = profile.ActiveInventory;
										local storageItem = inventory and inventory.Find and inventory:Find(storageItemID);
										if storageItem then
											local itemLib = modItemsLibrary:Find(hardItemId);
											inventory:Remove(storageItemID, 1);
											shared.Notify(player, ("$Item removed from your Inventory."):gsub("$Item", itemLib.Name), "Negative");
										end
									end
								end
							end
							
							modAnalytics.RecordProgression(room.Players[a].Instance.UserId, "Start", gameType..":"..(room.IsHard and "Hard" or "")..gameStage);
						end
					end);
				end
				--==
				
				room:SetState(enumRoomStates.InProgress);
				if gameTable.System.Start then
					local players = room:GetInstancePlayers();
					shared.modEventService:ServerInvoke("GameModeManager_BindGameModeStart", {ReplicateTo=players}, {
						Room = room;
					});

					gameTable.System:Start(room);
				end;
			end
			gameTable:Sync();
		end
		
		room.OnPlayersChanged:Connect(function()
			if #room.Players > 0 then
				if room.State == enumRoomStates.Idle then
					if stageLib.SingleArena then
						room:SetState(enumRoomStates.Intermission);

						room.StartTime = modSyncTime.GetTime() + (gameTable.StageLib.ReadyLength or modGameModeLibrary.DefaultReadyLength);
						if RunService:IsStudio() then
							room.StartTime = modSyncTime.GetTime() + 5;
						end
						gameTable:Sync();
						
						if #room.Players > 0 then
							if tick()-roomMeta.LastPlayerChanged > 10 then
								if gameTable.System.AnnounceReady then gameTable.System:AnnounceReady(room) end;
							end
						end
						
						local canStart = true;
						repeat
							local hardEnabled = false;
							for a=1, #room.Players do
								local player = room.Players[a].Instance;
								if player and player.Character then
									local hardItemId = gameTable.StageLib.HardModeItem;
									if hardItemId and player.Character:FindFirstChild(hardItemId) then
										hardEnabled = true;
										break;
									end
								end
							end
							if room.IsHard ~= hardEnabled then
								room:SetHard(hardEnabled);
							end
							
							if #room.Players <= 0 then
								canStart = false;
							end
							task.wait(0.1);
						until not canStart or room.State ~= enumRoomStates.Intermission or room.StartTime-modSyncTime.GetTime() <= 0;
						StartRoom(canStart);
					else
						if room:IsReady() then
							room:SetState(enumRoomStates.Intermission);
							local canStart = true;
							room.StartTime = modSyncTime.GetTime() + (gameTable.StageLib.ReadyLength or modGameModeLibrary.DefaultReadyLength);
							
							gameTable:Sync();
							repeat
								task.wait(0.1);
								if not room:IsReady() then canStart = false; break; end;
							until room.State ~= enumRoomStates.Intermission or room.StartTime-modSyncTime.GetTime() <= 0;
							
							StartRoom(canStart);
						end
					end
				end
			else
				if stageLib.SingleArena then
					if room.State >= enumRoomStates.InProgress then
						room.EndDuration = 3;
						room:SetState(enumRoomStates.Ending);
					end
				else
					if gameTable:HasEmptyRoom(room.Id) or not room.IsPublic or room.State ~= enumRoomStates.Idle then
						room.EndDuration = 3;
						room:SetState(enumRoomStates.Ending);
					end
				end
			end
			
			if #room.Players > 0 then
				local hostPlayer = room.Players[1].Instance;

				local profile = shared.modProfile:Get(hostPlayer);
				local equippedTools = profile and profile.EquippedTools or nil;
				local storageItem = equippedTools and equippedTools.StorageItem or nil;
				
				if storageItem and storageItem.ItemId == stageLib.MapItemId then
					room.MapStorageItem = storageItem;
				end

				local highestFocusLevel = 0;
				for a=1, #room.Players do
					local player = room.Players[a].Instance;
					local playerProfile = shared.modProfile:Get(player);
					if playerProfile then
						local playerSave = playerProfile:GetActiveSave();
						local playerLevel = playerSave and playerSave:GetStat("Level") or 1;
						local focusLevel = modGlobalVars.GetLevelToFocus(playerLevel);
						if focusLevel > highestFocusLevel then
							highestFocusLevel = focusLevel;
						end
					end
				end
				local lobbyLevel = math.clamp(highestFocusLevel, 1, math.huge);
				room.Values.Level = lobbyLevel;

			else
				room.MapStorageItem = nil;
				room.Values.Level = nil;
				
			end


			gameTable:Sync();
			roomMeta.LastPlayerChanged = tick();
			gameTable:Refresh();
		end)
		
		room.OnStateChanged:Connect(function()
			if room.State == enumRoomStates.Ending then
				room.EndTime = modSyncTime.GetTime() + (room.EndDuration or endingDuration);
				task.delay((room.EndDuration or endingDuration), function()
					room:SetState(enumRoomStates.Close);
				end)
				if gameTable.System.End then gameTable.System:End(room) end;
				
			elseif room.State == enumRoomStates.Close then
				local players = room:GetInstancePlayers();
				for a=1, #players do
					local player = players[a];
					if player then
						GameModeManager:DisconnectPlayer(player, stageLib.ExitTeleport);
						GameModeManager:Purge(player);
					end
				end
				room:Destroy();
				
			end
			gameTable:Refresh();
			gameTable:Sync();
		end)
		
		if gameTable.System.Load then gameTable.System:Load(room); end;
		table.insert(self.Lobbies, room);
		table.insert(GameModeManager.Lobbies, room);
		return room;
	end
	
	function meta:GetPlayerRoom(player)
		for a=1, #self.Lobbies do
			if self.Lobbies[a]:GetPlayer(player) then
				return self.Lobbies[a];
			end
		end
		return;
	end
	
	function meta:GetIdRoom(id)
		for a=#self.Lobbies, 1, -1  do
			if self.Lobbies[a].Id == id then
				return self.Lobbies[a];
			end
		end
		return;
	end

	function meta:HasEmptyRoom(excludeId)
		for a=1, #self.Lobbies do
			local room = self.Lobbies[a];
			if not room:IsFull() and room.State == 1 and room.IsPublic then
				if excludeId == nil or excludeId ~= room.Id then
					return true;
				end
			end
		end
		return false;
	end
	
	function meta:Refresh()
		local menuPlayers = self.MenuRoom:GetInstancePlayers();

		for a=#self.Lobbies, 1, -1 do
			local lobbyData = self.Lobbies[a];
			for b=#lobbyData.Players, 1, -1 do
				local playerData = lobbyData.Players[b];
				if playerData.Instance == nil or not playerData.Instance:IsDescendantOf(game.Players) then
					table.remove(lobbyData.Players, b);
				end
			end
			
			if lobbyData.State == enumRoomStates.Close then
				table.remove(self.Lobbies, a);
				
			elseif stageLib.SingleArena then
				if #lobbyData.Players <= 0 and lobbyData.State >= enumRoomStates.InProgress then
					lobbyData:SetState(enumRoomStates.Ending);
				end
				
			elseif not stageLib.SingleArena then
				if #lobbyData.Players <= 0 and lobbyData.State ~= enumRoomStates.Idle then
					lobbyData:SetState(enumRoomStates.Ending);
				end
				
			end
		end
		for a, _ in ipairs(self.RoomSpots) do
			if self.RoomSpots[a].State == enumRoomStates.Close then
				self.RoomSpots[a] = nil;
			end
		end
		
		if not self:HasEmptyRoom() then
			self:NewRoom();
		end
		
		for a=#self.Lobbies, 1, -1 do
			local lobbyPrefab: Model = self.Lobbies[a].LobbyPrefab;
			if lobbyPrefab == nil then continue end;
			if not workspace:IsAncestorOf(lobbyPrefab) then continue end;
			if lobbyPrefab.ModelStreamingMode ~= Enum.ModelStreamingMode.PersistentPerPlayer then continue end;

			local persistentPlayers = lobbyPrefab:GetPersistentPlayers();
			for b=#persistentPlayers, 1, -1 do
				if table.find(menuPlayers, persistentPlayers[b]) == nil then
					lobbyPrefab:RemovePersistentPlayer(persistentPlayers[b]);
				end
			end
			for b=1, #menuPlayers do
				lobbyPrefab:AddPersistentPlayer(menuPlayers[b]);
			end
		end
	end
	
	table.insert(GameModeManager.MenuRooms, {MenuRoom=meta.MenuRoom; GameTable=gameTable;});
	
	gameTable.Type = gameType;
	gameTable.Stage = gameStage;
	gameTable.Lobbies = {};
	
	gameTable:Refresh();
	
	setmetatable(meta, {__index=GameModeManager});
	return gameTable;
end

function GameModeManager:TpLobbyBox(gameManager, player)
	local playerClass: PlayerClass = modPlayers.get(player);
	local rootPart = playerClass.RootPart;

	if gameManager.SingleArena then
		local lobbyBox = workspace.Environment:FindFirstChild("BossLobby");
		if lobbyBox then
			rootPart.Anchored = true;
			
			playerClass:SetCFrame(lobbyBox.PrimaryPart.CFrame);
		end

	else
		for a=1, #gameManager.Lobbies do
			local room = gameManager.Lobbies[a];
			if room == nil 
				or room.LobbyPrefab == nil 
				or not workspace:IsAncestorOf(room.LobbyPrefab) then continue end;

			local roomCFrame = room.LobbyPrefab:GetPivot() * CFrame.new(0, -6, 0);
			
			rootPart.Anchored = true;
			
			playerClass:SetCFrame(roomCFrame);

			break;
		end

	end
end

function GameModeManager:JoinRoom(player, gameTable, room)
	local playerClass: PlayerClass = modPlayers.get(player);
	
	if gameTable.StageLib.SingleArena ~= true and room.State ~= enumRoomStates.Idle then
		Debugger:WarnClient(player, "Can not join room: Not idle room.");
		return;
		
	elseif gameTable.StageLib.SingleArena == true and room.State >= 3 then
		Debugger:WarnClient(player, "Can not join room: Not idle room.");
		return;
		
	end
	
	local joinRoom = room:CanAddPlayer(player);
	if joinRoom ~= true then
		Debugger:WarnClient(player, "Can not join room: "..joinRoom..".");
		return;
	end
	
	local playerData = room:AddPlayer(player);
	if room.LobbyPrefab and room.LobbyPrefab.PrimaryPart then
		local playerPos = {};
		for _, obj in pairs(room.LobbyPrefab.PrimaryPart:GetChildren()) do
			if obj.Name == "PlayerPosition" then
				table.insert(playerPos, obj);
			end
		end
		for a=1, #room.Players do
			for b=#playerPos, 1, -1 do
				if room.Players[a].LobbyPosition == playerPos[b] then
					table.remove(playerPos, b);
				end
			end
		end
		
		local newPos = playerPos[math.random(1, #playerPos)];
		playerData.LobbyPosition = newPos;
		
		local rootPart = playerClass.RootPart;
		if rootPart then
			local lobbyPoint = CFrame.new(playerData.LobbyPosition.WorldPosition + Vector3.new(0, 2.35, 0)) * playerData.LobbyPosition.WorldCFrame.Rotation;
			
			playerClass:SetCFrame(lobbyPoint);

			local hardItemId = gameTable.StageLib.HardModeItem;
			if hardItemId and rootPart.Parent:FindFirstChild(hardItemId) and rootPart.Parent[hardItemId]:FindFirstChild("Handle") then
				room:SetHard(true);
			end
		end
		gameTable:Sync();
		
		return gameTable;
	end
	return;
end

function GameModeManager:Assign(player, gameType, gameStage)
	local gameTable = GameModeManager:GetActive(gameType, gameStage);
	if gameTable == nil then gameTable = GameModeManager:Initialize(gameType, gameStage); end;
	if gameTable == nil then return end;
	
	local playerClass: PlayerClass = modPlayers.get(player);
	if playerClass then
		if playerClass.GameModeAccess == nil then
			playerClass.GameModeAccess = {};
		end
		playerClass.GameModeAccess[gameType..":"..gameStage] = true; 
	end
	
	local lobbyData = GameModeManager:GetActive(gameType, gameStage);
	remoteGameModeAssign:FireClient(player, lobbyData);
end

function GameModeManager:ConnectPlayer(player, gameType, gameStage)
	local playerClass: PlayerClass = modPlayers.get(player);

	local gameManager = GameModeManager:GetActive(gameType, gameStage);
	if gameManager == nil then return end;

	local rootPart = playerClass.RootPart;
	if rootPart == nil then return end;

	local joinSuccess = gameManager.MenuRoom:CanAddPlayer(player);

	gameManager.MenuRoom:AddPlayer(player);
	gameManager:Refresh();

	local profile = shared.modProfile:Get(player);
	profile.BossDoorCFrame = rootPart.CFrame;

	GameModeManager:TpLobbyBox(gameManager, player);

	return joinSuccess;
end

function GameModeManager:DisconnectPlayer(player, exitTeleport)
	if player == nil then return end;
	
	local playerClass: PlayerClass = modPlayers.get(player);
	if playerClass == nil then return end;
	
	local oldMenuRoom = GameModeManager:GetPlayerMenuRoom(player);
	GameModeManager:RemovePlayerFromMenuRoom(player);
	
	local rootPart = playerClass.RootPart;
	if rootPart then
		local profile = shared.modProfile:Get(player);

		local teleportCFrame = profile.BossDoorCFrame;
		
		shared.modEventService:ServerInvoke("GameModeManager_BindDisconnectPlayer", {ReplicateTo={player}}, {
			MenuRoom=oldMenuRoom;
			SetTeleportCfFunc=function(newCf)
				teleportCFrame = newCf;
			end
		});

		if teleportCFrame then
			if exitTeleport ~= false then
				if not playerClass.HealthComp.IsDead then
					playerClass:SetCFrame(teleportCFrame);
				end
				rootPart.Anchored = false;
				
			end
		end

	end
	local character = player.Character;
	if character then
		local ff = Instance.new("ForceField");
		ff.Name = "ExitBossFF";
		ff.Parent = character;
		ff.Visible = false;
		game.Debris:AddItem(ff, 5);
	end
end

function GameModeManager:ExitGamemodeWorld(player)
	if GameModeManager.GameWorldInfo == nil then return end;
	
	local profile = shared.modProfile:Get(player);
	local playerSave = profile:GetActiveSave();
	
	local spawnId = (GameModeManager.GameWorldInfo and GameModeManager.GameWorldInfo.StageLib.ExitSpawn) or playerSave.Spawn;
	local worldId = modBranchConfigs.GetWorldOfSpawn(spawnId);
	playerSave.Spawn = spawnId;
	
	if worldId == nil then
		shared.Notify(player, "Invalid SpawnId ("..spawnId.."), spawning in the warehouse.", "Negative");
		worldId = "TheWarehouse";
	end
	return modServerManager:Travel(player, worldId);
end

function GameModeManager:Purge(player)
	for a=#GameModeManager.Lobbies, 1, -1  do
		if GameModeManager.Lobbies[a] then
			GameModeManager.Lobbies[a]:RemovePlayer(player);
		end
	end
	
	GameModeManager:RemovePlayerFromMenuRoom(player);
	pcall(function()
		remoteGameModeHud:FireClient(player, {
			Action="Close";
		});
	end)
end

function GameModeManager:Clean()
	local function clean(room)
		if room == nil then return end;
		for a=#room.Players, 1, -1 do
			if room.Players[a] and game.Players:FindFirstChild(room.Players[a].Name) == nil then
				room:RemoveName(room.Players[a].Name);
			end
		end
	end
	
	for a=#GameModeManager.Lobbies, 1, -1  do
		if GameModeManager.Lobbies[a] then
			clean(GameModeManager.Lobbies[a]);
		end
	end
	
	for a=1, #GameModeManager.MenuRooms do
		local modes = GameModeManager.MenuRooms[a];
		clean(modes.MenuRoom);
		modes.GameTable:Refresh();
	end
end

return GameModeManager;
