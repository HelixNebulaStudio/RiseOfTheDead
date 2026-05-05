local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Objective = {};
Objective.__index = Objective;

Objective.Title = "Time Survival";
Objective.Description = "Survive the duration";

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
	self.RoundDuration = math.clamp(self.Controller.Wave * 2.5, 15, 60);
	self.EndTime = tick()+self.RoundDuration;
	self.LastSpawn = tick();
	self.StartLevel = self.Controller.Wave;
	
	self.SpawnCount = 0;
	self.SpawnPattern = math.random(1, 3);
	self.PauseTick = nil;
	
end

function Objective:Tick()
	local timeRemain = math.max(self.EndTime-tick(), 0);
	local maxSpawnRate = math.min(math.max(timeRemain*0.05, 1/(math.max(self.Controller.Wave/5, 1)), 0.1), 1);
	
	local canSpawn = timeRemain > 1 and tick()-self.LastSpawn > maxSpawnRate and #self.Controller.EnemyNpcClasses <= 80;
	if self.PauseTick and tick() < self.PauseTick then
		canSpawn = false;
	end
	
	if canSpawn then
		self.LastSpawn = tick();
		
		local enemyName = self.Controller:PickEnemy();
		self.LastSpawnName = enemyName;
		
		self.Controller:SpawnEnemy(enemyName, {
			Level = math.min(math.ceil((self.RoundDuration - timeRemain)/6) + self.Controller.Wave-1, self.Controller.PeekPlayerLevel);
		});
		self.SpawnCount = self.SpawnCount+1;
		self.PauseTick = nil;
	end
	
	if self.SpawnPattern == 1 then
		
	end

	if tick() > self.EndTime and #self.Controller.EnemyNpcClasses <= 0 then
		return true;
	end
	
	return false;
end

function Objective:End()
	for a=#self.Controller.EnemyNpcClasses, 1, -1 do
		game.Debris:AddItem(self.Controller.EnemyNpcClasses[a].Character, 0);
		table.remove(self.Controller.EnemyNpcClasses, a);
	end
end

return Objective;
