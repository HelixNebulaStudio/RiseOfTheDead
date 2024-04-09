local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local PlayerService = {};
--==
local RunService = game:GetService("RunService");
local Player = require(script:WaitForChild("Player"))(PlayerService);

local modEventSignal = require(game.ReplicatedStorage.Library.EventSignal);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modStatusLibrary = require(game.ReplicatedStorage.Library.StatusLibrary);

local remotePlayerProperties = modRemotesManager:Get("PlayerProperties");

--==
PlayerService.Players = {};
PlayerService.OnPlayerDied = modEventSignal.new("OnPlayerDied");
PlayerService.OnPlayerSpawn = modEventSignal.new("OnPlayerSpawn");

function PlayerService.Get(player)
	if player == nil then return end;
	if PlayerService.Players[player.Name] ~= nil then return PlayerService.Players[player.Name] end;
	
	local timeOut = tick();
	while player and PlayerService.Players[player.Name] == nil do
		if tick()-timeOut > 10 then break; end;
		task.wait(0.5);
	end
	
	return PlayerService.Players[player.Name];
end

function PlayerService.GetByName(name)
	return PlayerService.Players[name];
end

function PlayerService.WaitForCharacter(player)
	local clasPlayer = PlayerService.Get(player);
	local character;
	local timeOut = tick();
	
	while player:IsDescendantOf(game.Players) and tick()-timeOut < 10 do
		character = clasPlayer.Character;
		
		if character then
			break;
		else
			task.wait();
		end
	end
	
	return character;
end

function PlayerService.RefreshPlayers()
	for name, player in pairs(PlayerService.Players) do
		if game.Players:FindFirstChild(name) == nil then
			if not player.IsTeleporting and player.Destroy then
				player:Destroy();
			end
		end
	end
end

function PlayerService.GetPlayerInstance(object)
	local player = game.Players:FindFirstChild(object);
	if player and player.Character == object then
		return player;
	end
end

function PlayerService.GetPlayerToPlayerDistanceCache(playerA, playerB)
	local classPlayerA = PlayerService.Get(playerA);
	local classPlayerB = PlayerService.Get(playerB);
	
	if classPlayerA and classPlayerB and classPlayerA.RootPart and classPlayerB.RootPart then
		local t = tick();
		local posA = classPlayerA.RootPart.Position;
		local posB = classPlayerB.RootPart.Position;
		
		if classPlayerA.PlayerDistanceCache == nil then classPlayerA.PlayerDistanceCache = {}; end;
		if classPlayerB.PlayerDistanceCache == nil then classPlayerB.PlayerDistanceCache = {}; end;
		
		if classPlayerA.PlayerDistanceCache[playerB] == nil or t- classPlayerA.PlayerDistanceCache[playerB].Tick >= 5 then
			local distCache = {
				Tick=t;
				Distance=(posA-posB).Magnitude;
			}
			
			classPlayerA.PlayerDistanceCache[playerB] = distCache;
			classPlayerB.PlayerDistanceCache[playerA] = distCache;
		end
		
		if classPlayerA.PlayerDistanceCache[playerB] then
			return classPlayerA.PlayerDistanceCache[playerB].Distance;
		end
		if classPlayerB.PlayerDistanceCache[playerA] then
			return classPlayerB.PlayerDistanceCache[playerA].Distance;
		end
	end
	
	return 0;
end

function PlayerService.WaitForPlayerRadius(player, tarPos, radius, func)
	local classPlayer = PlayerService.Get(player);
	
	while game.Players:IsAncestorOf(player) do
		local rootPos = classPlayer.RootPart.Position;
		local distance = (rootPos-tarPos).Magnitude;
		
		if func and func(distance) == true then
			break;
		end
		if distance < radius then
			break;
			
		else
			task.wait(0.1);
			
		end
	end
end

function PlayerService.OnPlayerAdded(playerInstance)
	local player = Player.new(playerInstance, tick());
	
	PlayerService.Players[player.Name] = player;
	PlayerService.RefreshPlayers();
end

function PlayerService.OnPlayerRemoving(playerInstance)
	local player = PlayerService:Get(playerInstance);
	if player then
		wait(1);
		task.delay(player.IsTeleporting and 10 or 2, function()
			player.IsTeleporting = false;
			player:Destroy(tick());
		end)
	end
	PlayerService.RefreshPlayers();
end

local modEngineCore = require(game.ReplicatedStorage.EngineCore);
modEngineCore:ConnectOnPlayerAdded(script, PlayerService.OnPlayerAdded, 3)
game.Players.PlayerRemoving:Connect(PlayerService.OnPlayerRemoving);

if RunService:IsServer() then
	remotePlayerProperties.OnServerEvent:Connect(function(player, action, ...)
		local classPlayer = PlayerService.Players[player.Name];
		if classPlayer == nil then return end;

		if action == "Relay" then
			local statusId = ...;
			for id, status in pairs(classPlayer.Properties) do
				if id ~= statusId then continue end;
				if type(status) ~= "table" then continue end;
				
				local lib = modStatusLibrary:Find(id);
				local statusClass = lib and lib.Module and require(lib.Module);
				
				if statusClass and statusClass.OnRelay then
					statusClass.OnRelay(classPlayer, status, select(2, ...));
				elseif status.OnRelay then
					status.OnRelay(classPlayer, status, select(2, ...));
				end
			end
		end
	end)
else
	remotePlayerProperties.OnClientEvent:Connect(function(name, action, ...)
		local classPlayer = PlayerService.Players[name];
		if classPlayer == nil then return end;
		
		if action == "Kill" then
			local value = ...;
			classPlayer:Kill(value);
			
		elseif action == "SetProperties" then
			local key, value = ...;
			
			classPlayer:SetProperties(key, value);
		end
	end)
end

shared.modPlayers = PlayerService;

return PlayerService;

