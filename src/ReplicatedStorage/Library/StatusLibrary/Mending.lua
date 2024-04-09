local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local localPlayer = game.Players.LocalPlayer;

local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);

local StatusClass = require(script.Parent.StatusClass).new();
--==

if RunService:IsServer() then
	local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);

	modOnGameEvents:ConnectEvent("OnNpcDeath", function(players, npcModule)
		for _, player in pairs(players) do
			local classPlayer = shared.modPlayers.Get(player);
			
			if classPlayer.Properties.Mending == nil then continue end;
			local mendingStatus = classPlayer.Properties.Mending;

			if classPlayer.Properties.ArmorBreak == nil then continue end;
			
			local armorBreakStatus = classPlayer.Properties.ArmorBreak;
			local t = mendingStatus.Time;
			
			local timeRemaining = armorBreakStatus.Expires-modSyncTime.GetTime();
			timeRemaining = math.max(timeRemaining-t, 0);

			armorBreakStatus.Expires = modSyncTime.GetTime() + timeRemaining;
			armorBreakStatus.Delay = timeRemaining;

			classPlayer:SyncProperty("ArmorBreak");
		end
	end)
end

function StatusClass.OnTick(classPlayer, status, tickPack)
	if RunService:IsClient() then
		status.Visible = classPlayer.Properties.ArmorBreak ~= nil
	end
end

return StatusClass;
