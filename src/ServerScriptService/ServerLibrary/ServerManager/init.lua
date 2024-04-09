local ServerManager = {};
local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configurations;

--== Dependencies;
local RunService = game:GetService("RunService");
local TeleportService = game:GetService("TeleportService");
local MessagingService = game:GetService("MessagingService");
local HttpService = game:GetService("HttpService");
local DataStoreService = game:GetService("DataStoreService");
local LocalizationService = game:GetService("LocalizationService");

local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modEventSignal = require(game.ReplicatedStorage.Library.EventSignal);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modOnGameEvents = Debugger:Require(game.ServerScriptService.ServerLibrary.OnGameEvents);
local modDatabaseService = require(game.ServerScriptService.ServerLibrary.DatabaseService);
local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);

ServerManager.OnPlayerTravel = modEventSignal.new("OnPlayerTravel");
--== Variables;
local loadingGui = script:WaitForChild("TravelLoadingScreen");


local remoteTravelRequest = modRemotesManager:Get("TravelRequest");

ServerManager.AccessCode = nil;
ServerManager.Kicked = {};

ServerManager.RegionCode = "?";
ServerManager.LowestPing = math.huge;


ServerManager.IsUpdatingTag = Instance.new("BoolValue");
ServerManager.IsUpdatingTag.Name = "ServerIsUpdating";
ServerManager.IsUpdatingTag.Value = false;
ServerManager.IsUpdatingTag.Parent = game.ReplicatedStorage;


--Private Servers
ServerManager.PrivateServers = DataStoreService:GetDataStore("PrivateServers");
ServerManager.PrivateServerOwnerId = nil;
ServerManager.PrivateCache = nil;

--== Script;
function ServerManager:GetPrivateServerOwnerId()
	if game.PrivateServerOwnerId ~= "" and game.PrivateServerOwnerId ~= 0 then
		-- VIP Server;
		ServerManager.PrivateServerOwnerId = game.PrivateServerOwnerId;
	end
	return ServerManager.PrivateServerOwnerId
end

function ServerManager:UpdatePrivateServer(ownerId, updateAsync)
	local ownerId = tostring(ownerId);
	repeat
		local success, err = pcall(function()
			ServerManager.PrivateServers:UpdateAsync(ownerId, updateAsync);
		end)
		if not success then
			task.wait(6);
			Debugger:WarnClient(game.Players:GetPlayers(), "Update Private Server save failed. Error:"..err);
		else
			Debugger:Log("Private Server Updated:", ServerManager.PrivateCache);
		end
	until success == true;
end

function ServerManager.OnPlayerAdded(player)
	local joinData = player:GetJoinData();
	local teleportData = joinData.TeleportData;
	
	if teleportData then
		if teleportData.AccessCode then
			ServerManager.AccessCode = teleportData.AccessCode;
		end
		if teleportData.ShadowBanned then
			ServerManager.ShadowBanned = true;
		end
		if game.PrivateServerId ~= "" and teleportData.PrivateServerOwnerId and teleportData.GameMode == nil then
			ServerManager.PrivateServerOwnerId = teleportData.PrivateServerOwnerId;
		end
	end
	
	local worldLib = modBranchConfigs.WorldInfo;
	
	if worldLib.PrivateWorld then
		if ServerManager.PrivateWorldCreator == nil then
			ServerManager.PrivateWorldCreator = player;
		end
	end
	
	
	if ServerManager:GetPrivateServerOwnerId() ~= nil then
		ServerManager:UpdatePrivateServer(ServerManager.PrivateServerOwnerId, function(storedData)
			if storedData == nil then
				local newData = {
					PrivateServerOwnerId = ServerManager.PrivateServerOwnerId;
					WorldCodes = {};
				};
				ServerManager.PrivateCache = newData;
				
				Debugger:Log("Private server initialized:", ServerManager.PrivateCache);
				
				return HttpService:JSONEncode(newData);
			end
			
			ServerManager.PrivateCache = HttpService:JSONDecode(storedData);
			ServerManager.PrivateCache.PrivateServerOwnerId = ServerManager.PrivateServerOwnerId;
			
			return HttpService:JSONEncode(ServerManager.PrivateCache);
		end);
	end
	
	local profile = shared.modProfile:WaitForProfile(player);
	if profile then
		local shadowBanned = false;
		if profile.Loaded then
			shadowBanned = profile and profile.ShadowBan and profile.ShadowBan == -1 or profile.ShadowBan > os.time();
		end
		if shadowBanned and ServerManager.ShadowBanned ~= true and not modBranchConfigs.IsWorld("MainMenu") then
			player:Kick("You are not allowed on this server.");
		end
		
		if ServerManager.Kicked[player.Name] then
			player:Kick("You are not allowed on this server.");
		end
	end
	
	task.spawn(function()
		local chances = 4;
		while true do
			task.wait(10);
			
			if not game.Players:IsAncestorOf(player) then break; end
			
			local locale;
			pcall(function()
				locale = LocalizationService:GetCountryRegionForPlayerAsync(player);
			end)
			
			if locale then
				local pingMs = player:GetNetworkPing()*1000;
				
				if pingMs < ServerManager.LowestPing then
					ServerManager.LowestPing = pingMs;
					ServerManager.RegionCode = locale;
				end
				chances = chances-1;
			end
			if chances <= 0 then break; end;
		end
	end)
end

task.spawn(function()
	Debugger.AwaitShared("modProfile");
	Debugger:Log("ServerManager connected OnPlayerPacketRecieved.")

	shared.modProfile.OnPlayerPacketRecieved:Connect(function(profile, ...)
		local packet = ...;
		
		local player = profile.Player;
		Debugger:Log(player," Received packet", packet);
		
		if packet and packet.Data then
			if packet.Data.Request == "GetServer" then
				local data = {
					Request = "PostServer";
					Value = {
						AccessCode=ServerManager.AccessCode;
						PlaceId=game.PlaceId;
						UserId=player.UserId;
					};
					Sender = player.Name;
				}
				
				local playerId;
				for a=1, 3 do
					local getUserIdS, getUserIdE = pcall(function()
						playerId = game.Players:GetUserIdFromNameAsync(packet.Data.Sender);
					end) 
					if not getUserIdS then 
						Debugger:Warn(":SendTravelRequest GetUserIdFailed", getUserIdE) 
						task.wait(1); 
					else 
						break; 
					end;
				end
				
				profile:SendMsg("Msg"..playerId, data);

			elseif packet.Data.Request == "TravelRequest" then
				if profile.Settings.DisabledTravelRequests == 1 then return end;
				if profile.TravelRequests == nil then profile.TravelRequests = {} end;
				local name = packet.Data.Value and packet.Data.Value.UserName;

				profile.TravelRequests[name] = packet.Data.Value;
				remoteTravelRequest:FireClient(player, packet.Data.Value);
				shared.Notify(player, name.." is requesting to travel to you. Check "..name.." in the social menu.", "Inform");

			elseif packet.Data.Request == "TravelResponse" then
				local name = packet.Data.Sender;
				local accepted = packet.Data.Value and packet.Data.Value.Accepted;
				shared.Notify(player, name.." accepted your travel request.", "Inform");
				task.wait(1);
				ServerManager:TravelToPlayer(player, name);
			end
		end
	end)
end)

function ServerManager.OnPlayerRemoving(player)
	
end

function ServerManager:IsUpdating(player)
	if ServerManager.IsUpdatingTag.Value then
		if modBranchConfigs.IsWorld("MainMenu") then
			shared.Notify(player, "Servers are currently updating, please wait..", "Negative");
		else
			ServerManager:Teleport(player, "MainMenu");
		end
		return true;
	end
end

function ServerManager:SendTravelRequest(player, targetName)
	local profile = shared.modProfile:Get(player);
	if profile.LastPlayerTravelRequest and tick()-profile.LastPlayerTravelRequest < 20 then 
		shared.Notify(player, "Please wait before sending another travel request.", "Negative");
		return
	end
	profile.LastPlayerTravelRequest = tick();

	local playerId;
	for a=1, 3 do
		local getUserIdS, getUserIdE = pcall(function()
			playerId = game.Players:GetUserIdFromNameAsync(targetName);
		end) 
		if not getUserIdS then 
			Debugger:Warn(":SendTravelRequest GetUserIdFailed", getUserIdE) 
			task.wait(1); 
		else 
			break; 
		end;
	end
	
	local data = {
		Request = "TravelRequest";
		Sender = player.Name;
		Value = {
			VisitorId=player.UserId;
			UserName=player.Name;
			PlaceId=game.PlaceId;
		}
	};
	
	profile:SendMsg("Msg"..playerId, data);
end

function ServerManager:AcceptTravelRequest(player, targetName)
	local profile = shared.modProfile:Get(player);
	if profile.TravelRequests and profile.TravelRequests[targetName] then
		local data = {
			Request = "TravelResponse";
			Sender = player.Name;
			Value = {
				Accepted = true;
			}
		}
		
		local playerId;
		for a=1, 3 do
			local getUserIdS, getUserIdE = pcall(function()
				playerId = game.Players:GetUserIdFromNameAsync(targetName);
			end) 
			if not getUserIdS then 
				Debugger:Warn(":AcceptTravelRequest GetUserIdFailed", getUserIdE) 
				task.wait(1); 
			else 
				break; 
			end;
		end
		
		shared.Notify(player, "Accepting "..targetName.."'s travel request.", "Inform");
		profile:SendMsg("Msg"..playerId, data);
		profile.TravelRequests[targetName] = nil;
	end
end

function ServerManager:RequestPlayerServer(player, targetName)
	local playerId;
	for a=1, 3 do
		local getUserIdS, getUserIdE = pcall(function()
			playerId = game.Players:GetUserIdFromNameAsync(targetName);
		end) 
		if not getUserIdS then 
			Debugger:Warn(":RequestPlayerServer GetUserIdFailed", getUserIdE) 
			task.wait(1); 
		else 
			break; 
		end;
	end

	
	local isCurrentServer, errMsg, placeId, instanceId; 
	if playerId then
		for a=1, 3 do
			local getPlaceInstanceS, getPlaceInstanceE = pcall(function()
				isCurrentServer, errMsg, placeId, instanceId = TeleportService:GetPlayerPlaceInstanceAsync(playerId);
			end) if not getPlaceInstanceS then Debugger:Warn(":RequestPlayerServer getPlaceInstanceE", getPlaceInstanceE); task.wait(1); else break; end;
		end
	end
	
	local liveProfile = shared.modProfile:GetLiveProfile(playerId);
	if placeId and liveProfile then
		local accessCode = liveProfile and liveProfile.AccessCode or nil;
		return placeId, accessCode, {UserId=playerId};
	end
	
	local invokeTick = tick();
	local Packet = nil;
	
	local function waitForReply(packet)
		if packet and packet.Data and packet.Data.Request == "PostServer" then
			Packet = packet;
		end
	end
	
	local data = {
		Request = "GetServer";
		Sender = player.Name;
	}
	
	local profile = shared.modProfile:Get(player);
	profile.OnMessageRecieved:Connect(waitForReply);
	profile:SendMsg("Msg"..playerId, data);
	repeat until (tick()-invokeTick) >= 3 or Packet ~= nil or not task.wait();
	profile.OnMessageRecieved:Disconnect(waitForReply);
	
	if Packet and Packet.Data then
		if Packet.Data.Request == "PostServer" then
			local values = Packet.Data.Value;
			return values.PlaceId, values.AccessCode, values;
		end
	end
end

function ServerManager:FindPlayerServer(playerName, useRetries)
	local playerId;
	
	local retries = 3;
	if useRetries == false then
		retries = 1;
		
	elseif tonumber(useRetries) then
		retries = tonumber(useRetries);
		
	end
	
	for a=1, retries do
		local getUserIdS, getUserIdE = pcall(function()
			playerId = game.Players:GetUserIdFromNameAsync(playerName);
		end) 
		if not getUserIdS then 
			Debugger:Warn(":FindPlayerServer GetUserIdFailed", getUserIdE) 
			task.wait(1); 
		else 
			break; 
		end;
	end
	
	local isCurrentServer, errMsg, placeId, instanceId;
	if playerId then
		for a=1, retries do
			local getServerS, getServerE = pcall(function()
				isCurrentServer, errMsg, placeId, instanceId = TeleportService:GetPlayerPlaceInstanceAsync(playerId);
			end) 
			if not getServerS then
				if string.match(getServerE, "Bad Request") and errMsg == nil then
					errMsg = "NotInGame?";
				end
				Debugger:Warn(":FindPlayerServer (",playerId,") GetServerFailed:", getServerE, "errMsg", errMsg); 
				task.wait(1);
			else
				break;
			end
		end
	end
	
	if instanceId then
		return placeId, instanceId;
	end
end

function ServerManager:AddForceField(player)
	if player and player.Character and player.Character:FindFirstChild("TravelForcefield") == nil then
		local ff = Instance.new("ForceField");
		game.Debris:AddItem(ff, 20);
		ff.Name = "TravelForcefield";
		ff.Visible = false;
		ff.Parent = player.Character;
	end
end

function ServerManager:PrepareTeleport(players, worldName, teleportData)
	players = type(players) == "table" and players or {players};
	
	local playerIds = {};
	for _, player in pairs(players) do
		table.insert(playerIds, player.UserId);
		ServerManager:AddForceField(player);
		local profile = shared.modProfile:Get(player);
		profile.DestinationWorldName = worldName;
		profile.PreviousWorldName = modBranchConfigs.WorldName;
		
		profile:Save();
		if teleportData then
			teleportData.Players[player.Name] = profile.TeleportData;
		end
	end
	
	local analyticsTpDataS, analyticsTpDataE = pcall(function()
		modAnalytics:addGameAnalyticsTeleportData(playerIds, teleportData);
	end)
end

function ServerManager:CreateTeleportData()
	local teleportData = {};
	teleportData.ClassName = "TeleportData";
	teleportData.Players = {};
	
	if ServerManager.PrivateServerOwnerId then
		teleportData.PrivateServerOwnerId = ServerManager.PrivateServerOwnerId;
	end
	
	return teleportData;
end

function ServerManager:Teleport(player, worldName, teleportData)
	local placeId = modBranchConfigs.GetWorldId(worldName);
	if placeId == nil then shared.Notify(player, "Invalid WorldId ("..worldName.."), travel failed.", "Negative"); return end;
	
	local worldLib = modBranchConfigs.WorldLibrary[worldName];
	
	local profile = shared.modProfile:Get(player);
	local shadowBanned = false;
	if profile ~= nil and profile.Loaded then
		shadowBanned = profile and profile.ShadowBan and profile.ShadowBan == -1 or profile.ShadowBan > os.time();
	end
	
	teleportData = teleportData or ServerManager:CreateTeleportData();
	
	if shadowBanned then
		local accessCode = ServerManager:CreatePrivateServer(worldName);
		teleportData.ShadowBanned = true;
		ServerManager:TeleportToPrivateServer(worldName, accessCode, {player}, teleportData);
		return;
		
	elseif worldLib.PrivateWorld or worldLib.MaxPlayers == 1 then
		local accessCode = ServerManager:CreatePrivateServer(worldName);
		ServerManager:TeleportToPrivateServer(worldName, accessCode, {player}, teleportData);
		return;
		
	elseif ServerManager:GetPrivateServerOwnerId() ~= nil and worldLib.NoPrivateServers ~= true then -- Join/create new private server;
		local accessCode = ServerManager.PrivateCache and ServerManager.PrivateCache.WorldCodes and ServerManager.PrivateCache.WorldCodes[worldName];
		if accessCode == nil then
			local newAccessCode = ServerManager:CreatePrivateServer(worldName);
			
			ServerManager:UpdatePrivateServer(ServerManager.PrivateServerOwnerId, function(storedData)
				if storedData == nil then return end;
				ServerManager.PrivateCache = HttpService:JSONDecode(storedData);
				accessCode = ServerManager.PrivateCache.WorldCodes and ServerManager.PrivateCache.WorldCodes[worldName];
				
				if accessCode == nil then
					ServerManager.PrivateCache.WorldCodes[worldName] = newAccessCode;
					accessCode = newAccessCode;
				end
				
				return HttpService:JSONEncode(ServerManager.PrivateCache);
			end)
		end
		
		if accessCode then
			ServerManager:TeleportToPrivateServer(worldName, accessCode, {player}, teleportData);
			return;
		end
	end
	
	ServerManager:PrepareTeleport(player, worldName, teleportData);
	ServerManager:AddForceField(player);
	TeleportService:Teleport(placeId, player, teleportData);
end

function ServerManager:CreatePrivateServer(worldName)
	local placeId = modBranchConfigs.GetWorldId(worldName);
	if placeId == nil then
		Debugger:Warn("Invalid WorldId (",worldName,") to create private server.");
		placeId = game.PlaceId;
	end;
	Debugger:Log("Creating private server for (",placeId,")");
	
	local accessCode;
	for a=1, 3 do
		local reserveServerS, reserveServerE = pcall(function()
			accessCode = TeleportService:ReserveServer(placeId);
		end) if not reserveServerS then Debugger:Warn(":CreatePrivateServer failed ",reserveServerE) task.wait(1); end;
		if accessCode then break; end;
	end
	return accessCode;
end

function ServerManager:TeleportToPrivateServer(worldName, accessCode, playersList, teleportData)
	local placeId = modBranchConfigs.GetWorldId(worldName);
	if modGlobalVars.EngineMode ~= "RiseOfTheDead" and placeId == nil then placeId = game.PlaceId; end;
	if placeId == nil then shared.Notify(playersList, "Invalid WorldId ("..(worldName or "").."), travel failed.", "Negative"); return end;
	
	teleportData = teleportData or ServerManager:CreateTeleportData();
	ServerManager:PrepareTeleport(playersList, worldName, teleportData);
	ServerManager:AddForceField(playersList);
	
	teleportData.AccessCode = accessCode;
	
	if accessCode == nil then shared.Notify(playersList, "Travel failed (Nil AccessCode), please try again.", "Negative"); return end;
	
	local worldDisplayName = placeId and modBranchConfigs.GetWorldDisplayName(worldName) or worldName or modBranchConfigs.WorldName;
	shared.Notify(playersList, "Traveling to world ("..worldDisplayName..")", "Positive");
	for _, player in pairs(playersList) do
		ServerManager.OnPlayerTravel:Fire(player);
		
	end
	
	
	TeleportService:TeleportToPrivateServer(placeId, accessCode, playersList, nil, teleportData);
end

function ServerManager:TeleportToPlaceInstance(worldName, jobId, player, teleportData)
	local placeId = modBranchConfigs.GetWorldId(worldName);
	if placeId == nil then shared.Notify(player, "Invalid WorldId ("..worldName.."), travel failed.", "Negative"); return end;
	
	teleportData = teleportData or ServerManager:CreateTeleportData();
	ServerManager:PrepareTeleport(player, worldName, teleportData);
	ServerManager:AddForceField(player);
	
	TeleportService:TeleportToPlaceInstance(placeId, jobId, player, nil, teleportData);
end

--	local newLoadingScreen = loadingGui:Clone();
--	newLoadingScreen.Enabled = true;
--	newLoadingScreen.Parent = player.PlayerGui;
function ServerManager:Travel(player, worldName, teleportData)
	if ServerManager:IsUpdating(player) then return end;
	local placeId = modBranchConfigs.GetWorldId(worldName);
	local worldDisplayName = placeId and modBranchConfigs.GetWorldDisplayName(worldName) or worldName;
	
	if placeId == nil then
		shared.Notify(player, "Invalid WorldId ("..(worldName or "nil").."), travel failed.", "Negative");
		
	elseif worldName == modBranchConfigs.WorldName then
		shared.Notify(player, "You are already in world ("..worldDisplayName..").", "Negative");
		
	else
		modOnGameEvents:Fire("OnWorldTravel", player, {
			WorldId=worldName;
		});
		
		shared.Notify(player, "Traveling to world ("..worldDisplayName..")", "Positive");
		ServerManager.OnPlayerTravel:Fire(player);
		ServerManager:Teleport(player, worldName, teleportData);
		return true;
	end
	return false;
end

function ServerManager:TravelToPlayer(player, targetName)
	if ServerManager:IsUpdating(player) then return end;
	local placeId, jobId = ServerManager:FindPlayerServer(targetName);
	
	if placeId then
		local worldName = modBranchConfigs.GetWorldName(placeId);
		local worldLib = modBranchConfigs.WorldLibrary[worldName];
		
		if worldLib then
			if not worldLib.CanTravelTo then
				shared.Notify(player, targetName.." is in a mission world. Cannot travel at the moment.", "Negative");
				return false;
			end
			
			if worldLib.PrivateWorld then
				shared.Notify(player, "Getting "..targetName.."'s server..", "Inform");
				local placeId, accessCode = ServerManager:RequestPlayerServer(player, targetName);
				
				if placeId and accessCode then
					shared.Notify(player, "Traveling to "..targetName.."..", "Positive");
					ServerManager.OnPlayerTravel:Fire(player);
					
					local worldName = modBranchConfigs.GetWorldName(placeId);
					shared.Notify(player, "Server recieved, joining "..targetName..".", "Inform");
					ServerManager:TeleportToPrivateServer(worldName, accessCode, {player});
					
				else
					shared.Notify(player, "Could not find "..targetName.."'s server.", "Negative");
					
					return false;
				end
				
			else
				shared.Notify(player, "Traveling to "..targetName.."..", "Positive");
				ServerManager.OnPlayerTravel:Fire(player);
				ServerManager:TeleportToPlaceInstance(worldName, jobId, player)
				
			end
			return true;
		else
			Debugger:Warn("Invalid world to travel to.");
		end
	end
	shared.Notify(player, targetName.." is no longer in the game.", "Negative");
	
	return false;
end

TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage)
	Debugger:WarnClient(player, "Report this to developers: ".. tostring(teleportResult or "Unknown Result") ..", ".. tostring(errorMessage or "No server error message") .."." );
	if teleportResult ~= Enum.TeleportResult.Success and teleportResult ~= Enum.TeleportResult.IsTeleporting then
		shared.Notify(player, "Travel failed (".. tostring(teleportResult):gsub("Enum.TeleportResult.", "") ..").", "Positive");
	end
end)


local waitTime = 5;
game:BindToClose(function()
	if #game.Players:GetPlayers() <= 0 then return end;
	if RunService:IsStudio() then return end;
	if modBranchConfigs.IsWorld("MainMenu") then return end;
	local placeId = modBranchConfigs.GetWorldId("MainMenu");
	
	shared.Notify(game.Players:GetPlayers(), "This server is shutting down, please re-join..", "Negative");
	local menuCode = TeleportService:ReserveServer(placeId);
	
	for _,player in pairs(game.Players:GetPlayers()) do
		ServerManager:TeleportToPrivateServer("MainMenu", menuCode, {player});
		task.wait(waitTime);
		waitTime = math.clamp(waitTime/2, 0.1, 5);
	end
	
	game.Players.PlayerAdded:connect(function(player)
		task.wait(waitTime);
		waitTime = math.clamp(waitTime/2, 0.1, 5);
		ServerManager:TeleportToPrivateServer("MainMenu", menuCode, {player});
	end)
	
	while (#game.Players:GetPlayers() > 0) do task.wait(1); end
end)

task.spawn(function()
	local modCommandHandler = require(game.ReplicatedStorage.Library.CommandHandler);

	Debugger.AwaitShared("modCommandsLibrary");
	shared.modCommandsLibrary:HookChatCommand("server", {
		Permission = shared.modCommandsLibrary.PermissionLevel.Admin;
		Description = [[Server commands.
		/server getregion
		]];

		RequiredArgs = 0;
		UsageInfo = "/server action";
		Function = function(player, args)
			
			local action = args[1];

			if action == "getregion" then
				shared.Notify(player, "Server region code: "..ServerManager.RegionCode, "Inform");
				
			elseif action == "" then
				
				
			end
			
			return true;
		end;
	});
end)


return ServerManager;
