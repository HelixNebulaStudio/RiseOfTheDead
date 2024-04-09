local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);

local BossArenaMeta = {};
BossArenaMeta.__index = BossArenaMeta;
BossArenaMeta.Enemies = {};
local BossArena = setmetatable({}, BossArenaMeta);
--== Variables;

--== Script;
local function spawnMinions(name)
	local newSpawnPoint = modNpc.GetCFrameFromPlatform(BossArena.Room.LobbyPrefab:WaitForChild("BossSpawn"));
	modNpc.Spawn(name, newSpawnPoint, function(npc, npcModule)
		npcModule.OnTarget(BossArena.Room:GetInstancePlayers());
		table.insert(BossArenaMeta.Enemies, npcModule);
	end)
end

function BossArena:SetRoom(room)
	BossArenaMeta.Room = room;
end

function BossArena:Start()
	local stage = 0;
	
	local zpideNpcModule = self.Room and self.Room.BossNpcModules and #self.Room.BossNpcModules > 0 and self.Room.BossNpcModules[1];
	
	if zpideNpcModule and zpideNpcModule.Humanoid then
		local humanoid = zpideNpcModule.Humanoid;
		humanoid.HealthChanged:Connect(function()
			if stage == 0 and humanoid.Health < humanoid.MaxHealth * 0.75 then
				stage = 1;
				for a=1, 2 do
					if humanoid.Health <= 0 then return end;
					spawnMinions("Mini Zpider");
				end
			elseif stage == 1 and humanoid.Health < humanoid.MaxHealth * 0.5 then
				stage = 2;
				for a=1, 4 do
					if humanoid.Health <= 0 then return end;
					spawnMinions("Mini Zpider");
				end
			elseif stage == 2 and humanoid.Health < humanoid.MaxHealth * 0.25 then
				stage = 3;
				for a=1, 8 do
					if humanoid.Health <= 0 then return end;
					spawnMinions("Mini Zpider");
				end
			end
		end)
		humanoid.Died:Connect(function()
			stage = 3;
			for a=1, 3 do
				for a=#self.Enemies, 1, -1 do
					if self.Enemies[a].Humanoid == nil then continue end;
					self.Enemies[a].Humanoid.Health = 0;
				end
				wait(1);
			end
		end)
	end
end

function BossArena:End()
	for a=#self.Enemies, 1, -1 do
		self.Enemies[a].Prefab:Destroy();
		self.Enemies[a] = nil;
	end
end

function Initialize()
	
end

Initialize();
return BossArena;
