local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modGameModeLibrary = require(game.ReplicatedStorage.Library.GameModeLibrary);

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
	Objective.BossNpcModules = {};
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
			local bossPrefab, npcModule = self.Controller:SpawnEnemy(prefabName, {
				SpawnCFrame = Objective.BossSpawns[math.random(1, #Objective.BossSpawns)].CFrame;
			})

			local newHealth = 5000 * math.max(math.ceil(self.Controller.Wave/5), 1);

			npcModule.IsBoss = true;
			npcModule.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Subject;
			npcModule.Humanoid.MaxHealth = math.clamp(newHealth, 1000, math.huge);
			npcModule.Humanoid.Health = npcModule.Humanoid.MaxHealth;

			bossPrefab:SetAttribute("EntityHudHealth", true);
			table.insert(bossList, bossPrefab);

			npcModule:Died(function()
				game.Debris:AddItem(bossPrefab, 30);
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
					--LootPrefab=lootPrefab;
				};

				local canRagdoll = bossPrefab:GetAttribute("HasRagdoll") == true;
				if not canRagdoll then
					for _, obj in pairs(bossPrefab:GetDescendants()) do
						if obj:IsA("Motor6D") or obj:IsA("BodyMover") then
							game.Debris:AddItem(obj, 0);
						end
					end
				end
			end)
			table.insert(Objective.BossNpcModules, npcModule);
		end
		
	end
	
	self.Controller:Hud{
		BossList = bossList;
	};
end

function Objective:Tick()
	--Debugger:Display{
	--	Objective="Boss";
	--	Wave=self.Controller.Wave;
	--	NumOfEnemy=#self.Controller.EnemyModules;
	--};
	
	if tick()-self.LastZombieSpawn >= 3 and #self.Controller.EnemyModules <= 25 and #Objective.BossNpcModules > 0 then
		self.LastZombieSpawn = tick();
		self.Controller:SpawnEnemy(self.Controller:PickEnemy(), {
			Level = math.min(self.Controller.Wave, self.Controller.PeekPlayerLevel);
		});
	end

	if tick() > self.StartTime and #self.Controller.EnemyModules <= 0 then
		return true;
	end

	return false;
end

function Objective:End()
	table.clear(Objective.BossNpcModules);
end

return Objective;
