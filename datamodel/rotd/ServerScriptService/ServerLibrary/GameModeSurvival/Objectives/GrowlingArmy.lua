local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Objective = {
	Title = "Growling Army";
	Description = "Only Growlers spawns";
	Controller = nil;
};
Objective.__index = Objective;
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
    self.EliminateCount = math.clamp(self.Controller.Wave *3, 10, 70);

	self.SpawnCount = 0;
	self.SpawnPattern = math.random(1, 3);
end

function Objective:Tick()
    local activeEnemyCount = #self.Controller.EnemyNpcClasses;
    
	local canSpawn = true;
    if not self.Controller.IsHard and tick()-self.LastSpawnTick <= 0.5 then
        canSpawn = false;
    end
    if #self.Controller.EnemyNpcClasses > 60 then
        canSpawn = false;
    end
    if self.SpawnCount >= self.EliminateCount then
        canSpawn = false;
    end
	
	if canSpawn then
		self.LastSpawnTick = tick();
		
		local enemyName = "Growler";
        local enemyLevel = self.Controller:GetWaveLevel();

		self.LastSpawnName = enemyName;
		self.SpawnCount = self.SpawnCount+1;
		self.PauseTick = nil;

		self.Controller:SpawnEnemy(enemyName, {
			Level = enemyLevel;
		});
	end

	if self.SpawnCount >= self.EliminateCount and #self.Controller.EnemyNpcClasses <= 0 then
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
