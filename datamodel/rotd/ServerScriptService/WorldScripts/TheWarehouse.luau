local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);
local modLeaderboardService = require(game.ReplicatedStorage.Library.LeaderboardService);

if RunService:IsServer() then
local modGameModeManager = require(game.ServerScriptService.ServerLibrary.GameModeManager);
local modNpcs = require(game.ServerScriptService.ServerLibrary.Entity.Npcs);
local modEvents = require(game.ServerScriptService.ServerLibrary.Events);
local modCrates = require(game.ServerScriptService.ServerLibrary.Crates);

end

local WorldCore = {};
--==

function WorldCore.onRequire()
    
    shared.modEngineCore:ConnectOnPlayerAdded(script, function(player: Player)
	    local profile = shared.modProfile:WaitForProfile(player);

    end, 999)



end

return WorldCore;