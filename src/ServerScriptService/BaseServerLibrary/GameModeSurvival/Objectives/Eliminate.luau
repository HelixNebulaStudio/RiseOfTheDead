local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Objective = {};
Objective.__index = Objective;

Objective.Title = "Eliminate";

Objective.Controller = nil;
--==

function Objective.new()
	local self = {};
	
	setmetatable(self, Objective);
	return self;
end

function Objective:Load()
end

function Objective:Begin()
	self.StartTime = tick()+5;
	self.LastSpawnTick = tick();
    self.EliminateCount = math.clamp(self.Controller.Wave *5, 20, 100);

	self.SpawnCount = 0;
	self.SpawnPattern = math.random(1, 3);
	self.PauseTick = nil;
	
end

function Objective:Tick()
    local activeEnemyCount = #self.Controller.EnemyModules;
    
	local canSpawn = true;
    if tick()-self.LastSpawnTick <= math.max(self.Controller.IsHard and 0.1 or 1, activeEnemyCount/20) then
        canSpawn = false;
    end
    if #self.Controller.EnemyModules > 100 then
        canSpawn = false;
    end
	if self.PauseTick and tick() < self.PauseTick then
		canSpawn = false;
	end
    if self.SpawnCount >= self.EliminateCount then
        canSpawn = false;
    end
	
	if canSpawn then
		self.LastSpawnTick = tick();
		
		local enemyName = self.Controller:PickEnemy();
        local enemyLevel = self.Controller:GetWaveLevel();

		self.LastSpawnName = enemyName;
		self.SpawnCount = self.SpawnCount+1;
		self.PauseTick = nil;

		self.Controller:SpawnEnemy(enemyName, {
			Level = enemyLevel;
		});
	end
	
	if self.SpawnPattern == 1 then
		
	elseif self.SpawnPattern == 2 then
		if math.fmod(self.SpawnCount, 10) == 0 and self.PauseTick == nil then
			self.PauseTick = tick()+2;
		end

	elseif self.SpawnPattern == 3 then
		if math.fmod(self.SpawnCount, 20) == 0 and self.PauseTick == nil then
			self.PauseTick = tick()+4;
		end
		
	end

	if self.SpawnCount >= self.EliminateCount and #self.Controller.EnemyModules <= 0 then
		return true;
	end
	
	return false;
end

function Objective:End()
	for a=#self.Controller.EnemyModules, 1, -1 do
		game.Debris:AddItem(self.Controller.EnemyModules[a].Prefab, 0);
		table.remove(self.Controller.EnemyModules, a);
	end
end

return Objective;
