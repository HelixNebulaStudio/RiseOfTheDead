local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modGameModeLibrary = shared.require(game.ReplicatedStorage.Library.GameModeLibrary);

local Objective = {};
Objective.__index = Objective;

Objective.Title = "Boss";

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
	
	for _, obj in pairs(self.Controller.StageElements:WaitForChild("BossSpawns"):GetChildren()) do
		table.insert(Objective.BossSpawns, obj);
		obj.Transparency = 1;
	end
	
	local config = self.Controller.BossConfig;
	
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
				return pickTable[a].Data.Name;
			end
		end

		return;
	end
end

function Objective:Begin()
	self.LastZombieSpawn = tick();
	self.StartTime = tick()+5;
	
	local bossCount = math.clamp(math.ceil(self.Controller.Wave/15), 1, 4);
	local bossList = {};
	
	for a=1, bossCount do
		local bossId = self.PickBoss();
		
		local bossLib = modGameModeLibrary.GameModes.Boss.Stages[bossId];
		
		for prefabName, _ in pairs(bossLib.Prefabs) do
			local npcClass: NpcClass = self.Controller:SpawnEnemy(prefabName, {
				SpawnCFrame = Objective.BossSpawns[math.random(1, #Objective.BossSpawns)].CFrame;
			})

			local newHealth = 5000 * math.max(math.ceil(self.Controller.Wave/5), 1);

			npcClass.Properties.IsBoss = true;
			npcClass.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject;

			local newMaxHealth = math.clamp(newHealth, 1000, math.huge);
			npcClass.HealthComp:SetMaxHealth(newMaxHealth);
			npcClass.HealthComp:SetHealth(newMaxHealth);
			npcClass.HealthComp:Reset();

			local bossChar = npcClass.Character;
			bossChar:SetAttribute("EntityHudHealth", true);
			table.insert(bossList, bossChar);

			npcClass.HealthComp.OnIsDeadChanged:Connect(function()
				if not npcClass.HealthComp.IsDead then return end;

				game.Debris:AddItem(bossChar, 30);
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
					--LootPrefab=lootPrefab;
				};

				local canRagdoll = bossChar:GetAttribute("HasRagdoll") == true;
				if not canRagdoll then
					for _, obj in pairs(bossChar:GetDescendants()) do
						if obj:IsA("Motor6D") or obj:IsA("BodyMover") then
							game.Debris:AddItem(obj, 0);
						end
					end
				end
			end)
			table.insert(Objective.BossNpcClasses, npcClass);
		end
		
	end
	
	self.Controller:Hud{
		BossList = bossList;
	};
end

function Objective:Tick()	
	if tick()-self.LastZombieSpawn >= 3 and #self.Controller.EnemyNpcClasses <= 25 and #Objective.BossNpcClasses > 0 then
		self.LastZombieSpawn = tick();
		
		local enemyName = self.Controller:PickEnemy();
        local enemyLevel = self.Controller:GetWaveLevel();

		self.Controller:SpawnEnemy(enemyName, {
			Level = enemyLevel;
		});
	end

	if tick() > self.StartTime and #self.Controller.EnemyNpcClasses <= 0 then
		return true;
	end

	return false;
end

function Objective:End()
	table.clear(Objective.BossNpcClasses);
end

return Objective;
