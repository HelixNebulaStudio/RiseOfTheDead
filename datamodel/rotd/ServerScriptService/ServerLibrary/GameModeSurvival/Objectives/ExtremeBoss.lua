local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Objective = {};
Objective.__index = Objective;

Objective.Title = "Extreme Boss";
Objective.DifficultyModes = {Hard=false;};

Objective.Controller = nil;
--==

function Objective.new()
	local self = {};
	
	setmetatable(self, Objective);
	return self;
end

function Objective:Load()
	Objective.BossNpcClasses = {};
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
	
	local npcClass: NpcClass = self.Controller:SpawnEnemy(pickBossName, {
		SpawnCFrame = Objective.BossSpawns[math.random(1, #Objective.BossSpawns)].CFrame;
		HardChance = pickBossData.HardChance; 
	})

	local newHealth = 200000 * math.max(math.ceil(self.Controller.Wave/5), 1);
	
	npcClass.Properties.HealthRescaled = true;
	npcClass.Properties.IsBoss = true;
	npcClass.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject;

	local newMaxHealth = math.clamp(newHealth, 1000, math.huge);
	npcClass.HealthComp:SetMaxHealth(newMaxHealth);

	if npcClass.Properties.FullHealOnSpawn ~= false then
		npcClass.HealthComp:SetHealth(newMaxHealth);
		
	else
		npcClass.HealthComp:SetHealth(math.max(npcClass.Humanoid.MaxHealth * 0.0256, 30000));
		
	end
	npcClass.HealthComp:Reset();

	local bossChar = npcClass.Character;
	bossChar:SetAttribute("EntityHudHealth", true);
	table.insert(bossList, bossChar);

	npcClass.HealthComp.OnIsDeadChanged:Connect(function(isDead)
		if not isDead then return end;

		game.Debris:AddItem(bossChar, 10);

		for a=#Objective.BossNpcClasses, 1, -1 do
			if Objective.BossNpcClasses[a] == npcClass then
				table.remove(Objective.BossNpcClasses, a);
				break;
			end
		end
		for a=#bossList, 1, -1 do
			if bossList[a] == bossChar then
				table.remove(bossList, a);
			end
		end

		self.Controller:Hud{
			BossKilled=true;
		};
		
		local canRagdoll = bossChar:GetAttribute("HasRagdoll") == true;
		if not canRagdoll then
			for _, obj in pairs(bossChar:GetDescendants()) do
				if obj:IsA("Motor6D") then
					game.Debris:AddItem(obj, 0);
				end
			end
		end
	end)
	table.insert(Objective.BossNpcClasses, npcClass);

	self.Controller:Hud{
		BossList = bossList;
	};
end

function Objective:Tick()

	if tick()-self.LastZombieSpawn >= 2 and #self.Controller.EnemyNpcClasses <= 10 and #Objective.BossNpcClasses > 0 then
		self.LastZombieSpawn = tick();
		
		if math.random(1, 100)/100 <= self.ZombieSpawnChance then
			local enemyName = self.Controller:PickEnemy();
			local enemyLevel = self.Controller:GetWaveLevel();
	
			self.Controller:SpawnEnemy(enemyName, {
				Level = enemyLevel;
			});
		end
	end

	if tick() > self.StartTime and #self.Controller.EnemyNpcClasses <= 0 then
		return true;
	end

	return false;
end

function Objective:End()
	
end

return Objective;
