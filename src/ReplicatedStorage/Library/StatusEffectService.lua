local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Variables;
local StatusEffectService = {};

local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modInfoBubbles = require(game.ReplicatedStorage.Library.InfoBubbles);

local remoteSyncStatusEffect = modRemotesManager:Get("SyncStatusEffect");

if RunService:IsServer() then
	modSkillTree = require(game.ServerScriptService.ServerLibrary.SkillTree);
	modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
	
	remoteSyncStatusEffect.OnServerEvent:Connect(function(player, cmd)
		if cmd == "ready" then
			local classPlayer = modPlayers.GetByName(player.Name);
			classPlayer.StatusSyncEnabled = true;
		end
	end)
end

--== Script;
local function replicateStatus(player, ...)
	local classPlayer = modPlayers.GetByName(player.Name);
	while player:IsDescendantOf(game.Players) and classPlayer.StatusSyncEnabled == nil do wait(0.5); end
	remoteSyncStatusEffect:FireClient(player, "do", ...);
end

if RunService:IsServer() then
	modPlayers.OnPlayerDied:Connect(function(classPlayer)
		
	end)
end

return StatusEffectService;