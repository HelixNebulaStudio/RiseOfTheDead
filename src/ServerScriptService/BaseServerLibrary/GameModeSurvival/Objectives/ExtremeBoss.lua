local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Objective = {};
Objective.__index = Objective;

Objective.Title = "Extreme Boss";

Objective.Controller = nil;
--==

function Objective.new()
	local self = {};
	
	setmetatable(self, Objective);
	return self;
end

function Objective:Load()
	Objective.BossNpcModules = {};
	Objective.BossSpawns = {};

	for _, obj in pairs(self.Controller.StageElements:WaitForChild("ExtremeBossSpawns"):GetChildren()) do
		table.insert(Objective.BossSpawns, obj);
		obj.Transparency = 1;
	end

	local config = self.Controller.ExtremeBossConfig;
	
	local pickTable = {};
	local totalChance = 0;
	for a=1, #config.List do
		local enemyOption = config.List[a];
		totalChance = totalChance + enemyOption.Chance;
		table.insert(pickTable, {Total=totalChance; Data=enemyOption});
	end

	function Objective.PickBoss()
		local roll = math.random(0, totalChance);
		for a=1, #pickTable do
			if roll <= pickTable[a].Total then
				return pickTable[a].Data.Name, pickTable[a].Data;
			end
		end
	end
end

function Objective:Begin()
	self.LastZombieSpawn = tick();
	self.StartTime = tick()+5;

	local bossList = {};
	
	local pickBossName, pickBossData = self.PickBoss();
	
	self.ZombieSpawnChance = 0;
	if pickBossData.ZombieSpawnChance then
		self.ZombieSpawnChance = pickBossData.ZombieSpawnChance;
	end
	
	local bossPrefab, npcModule = self.Controller:SpawnEnemy(pickBossName, {
		SpawnCFrame = Objective.BossSpawns[math.random(1, #Objective.BossSpawns)].CFrame;
		HardChance = pickBossData.HardChance; 
	})

	local newHealth = 200000 * math.max(math.ceil(self.Controller.Wave/5), 1);
	
	npcModule.HealthRescaled = true;
	npcModule.IsBoss = true;
	npcModule.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject;
	npcModule.Humanoid.MaxHealth = math.clamp(newHealth, 1000, math.huge);
	if npcModule.FullHealOnSpawn ~= false then
		npcModule.Humanoid.Health = npcModule.Humanoid.MaxHealth;
		
	else
		npcModule.Humanoid.Health = math.max(npcModule.Humanoid.MaxHealth * 0.0256, 30000);
		
	end

	bossPrefab:SetAttribute("EntityHudHealth", true);
	table.insert(bossList, bossPrefab);

	npcModule:Died(function()
		game.Debris:AddItem(bossPrefab, 10);
		for a=#Objective.BossNpcModules, 1, -1 do
			if Objective.BossNpcModules[a] == npcModule then
				table.remove(Objective.BossNpcModules, a);
				break;
			end
		end
		for a=#bossList, 1, -1 do
			if bossList[a] == bossPrefab then
				table.remove(bossList, a);
			end
		end

		self.Controller:Hud{
			BossKilled=true;
		};
	end);
	table.insert(Objective.BossNpcModules, npcModule);

	self.Controller:Hud{
		BossList = bossList;
	};
end

function Objective:Tick()

	if tick()-self.LastZombieSpawn >= 2 and #self.Controller.EnemyModules <= 10 and #Objective.BossNpcModules > 0 then
		self.LastZombieSpawn = tick();
		
		if math.random(1, 100)/100 <= self.ZombieSpawnChance then
			self.Controller:SpawnEnemy(self.Controller:PickEnemy(), {
				Level = math.min(self.Controller.Wave, self.Controller.PeekPlayerLevel);
			});
		end
	end

	if tick() > self.StartTime and #self.Controller.EnemyModules <= 0 then
		return true;
	end

	return false;
end

function Objective:End()
	
end

return Objective;
