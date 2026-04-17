local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modReplicationManager = shared.require(game.ReplicatedStorage.Library.ReplicationManager);

local BossArena = {};

function BossArena.BindLoad(room)
end

function BossArena.BindBegin(room)
	if shared.WorldName ~= "TheMall" and shared.WorldName ~= "BioXResearch" then return end;
	local arenaWalls = game.ServerStorage.Prefabs.Objects:WaitForChild("TheMallArenaWalls"):Clone();
	room.Garbage:Tag(arenaWalls);

	Debugger.Expire(arenaWalls, 600);

	local players = room:GetInstancePlayers();
	modReplicationManager.ReplicateIn(players, arenaWalls, workspace.Environment);
end

function BossArena.BindEnded(room)
end

return BossArena;