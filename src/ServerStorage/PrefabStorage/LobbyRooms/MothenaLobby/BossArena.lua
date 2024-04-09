local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local TweenService = game:GetService("TweenService");
local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);

local BossArenaMeta = {};
BossArenaMeta.__index = BossArenaMeta;
BossArenaMeta.Enemies = {};
local BossArena = setmetatable({}, BossArenaMeta);

local arenaWalls = script.Parent:WaitForChild("ServerAsset"):WaitForChild("ArenaWalls");
--== Variables;
local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.In);

--== Script;
function BossArena:SetRoom(room)
	BossArenaMeta.Room = room;
end

function BossArena:Start()
	local players = BossArena.Room:GetInstancePlayers();
	
	Debugger.Expire(arenaWalls, 600);

	modReplicationManager.ReplicateIn(players, arenaWalls, workspace.Environment);
	
	local npcModule = self.Room and self.Room.BossNpcModules and #self.Room.BossNpcModules > 0 and self.Room.BossNpcModules[1];

	if npcModule and npcModule.Humanoid then
		local humanoid = npcModule.Humanoid;
		humanoid.Died:Connect(function()
			if arenaWalls then arenaWalls:Destroy() end;
		end)
	end
end

function BossArena:End()
	if arenaWalls then arenaWalls:Destroy() end;
end

--== Initialize;
arenaWalls.Parent = game.ReplicatedStorage;

return BossArena;
