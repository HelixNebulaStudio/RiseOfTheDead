local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);


local Objective = {
	Controller = nil;
};
Objective.__index = Objective;

Objective.Title = "Barrication";
Objective.Description = "With enemies' ever growing immunity, barricade up to survive the duration";

--==
function Objective.onRequire()
end

function Objective.new()
	local self = {};
	
	setmetatable(self, Objective);
	return self;
end

function Objective:Load()
	Objective.MaterialSpawns = {};
	Objective.BuildableSpawns = {};

	local barricationPrefabs = self.Controller.StageElements:WaitForChild("Barrication");
	for _, obj in pairs(barricationPrefabs:WaitForChild("Materials"):GetChildren()) do
		table.insert(Objective.MaterialSpawns, obj);
	end

	for _, obj in pairs(barricationPrefabs:WaitForChild("Buildables"):GetChildren()) do
		table.insert(Objective.BuildableSpawns, obj);
	end
end

function Objective:Begin()
	local controller = self.Controller;

	self.Barricades = {};

	self.RoundDuration = math.clamp(self.Controller.Wave * 4.5, 85, 300);
	self.EndTime = tick() + self.RoundDuration;
	self.LastSpawn = tick();

	controller.WaveStartTime = workspace:GetServerTimeNow();
	controller.WaveDuration = self.RoundDuration;

	for _, buildable in pairs(self.BuildableSpawns) do
		local newBuildable = buildable:Clone();
		newBuildable.Parent = workspace.Environment.Game;
		table.insert(self.Barricades, newBuildable);

		controller.StageGarbage:Tag(newBuildable);
	end

	local matPickList = {};
	for _, material in pairs(self.MaterialSpawns) do
		if material:GetAttribute("AlwaySpawn") ~= true then
			table.insert(matPickList, material);
			continue
		end;
		
		local newMaterial = material:Clone();
		newMaterial.Parent = workspace.Environment.Game;
		
		controller.StageGarbage:Tag(newMaterial);
	end

	for a=1, 12 do
		local newMat = table.remove(matPickList, math.random(1, #matPickList))
		newMat = newMat:Clone();
		newMat.Parent = workspace.Environment.Game;
		
		controller.StageGarbage:Tag(newMat);
	end
end

function Objective:Tick()
	local controller = self.Controller;

	local timeRemain = math.max(self.EndTime-tick(), 0);
	local timeLapsed = self.RoundDuration-timeRemain;
	local maxSpawnRate = math.min(math.max(timeRemain*0.05, 1/(math.max(controller.Wave/5, 1)), 0.1), 1);
	
	local canSpawn = timeRemain > 1 and tick()-self.LastSpawn > maxSpawnRate and #controller.EnemyNpcClasses <= 80;
	if self.PauseTick and tick() < self.PauseTick then
		canSpawn = false;
	end
	
	if canSpawn and timeLapsed >= 10 then
		self.LastSpawn = tick();
		
		local enemyName = controller:PickEnemy();
		self.LastSpawnName = enemyName;
		
        local enemyLevel = controller:GetWaveLevel();
		local immunity = math.clamp(timeLapsed/(self.RoundDuration-30), 0, 1.1);
		controller:SpawnEnemy(enemyName, {
			Level = enemyLevel;
			Immunity = immunity;
		});

		self.PauseTick = tick()+4;
		if self.SurviveTime then
			self.PauseTick = tick()+1;
		end
	end

	if self.SurviveTime then
		if tick() > self.EndTime and #controller.EnemyNpcClasses <= 0 then
			return true;
		end

	elseif tick() > self.EndTime - 30 then
		self.SurviveTime = tick() + 30;

		modAudio.Play("DoomAlarm", workspace);
		for a=1, #controller.EnemyNpcClasses do
			local npcClass: NpcClass = controller.EnemyNpcClasses[a];
			npcClass.Properties.Immunity = nil;
		end
		
		for a=1, #self.Barricades do
			local barricade = self.Barricades[a];
			for _, obj in pairs(barricade:GetChildren()) do
				if obj:IsA("Configuration") then
					obj:Destroy();

				elseif obj:IsA("BasePart") then
					obj.Anchored = false;
				end
			end

			modAudio.Play("WoodSlam", barricade.PrimaryPart);
			Debugger.Expire(barricade, 10);
		end

	end

	return false;
end

function Objective:End()
	local controller = self.Controller;

	for a=#controller.EnemyNpcClasses, 1, -1 do
		game.Debris:AddItem(controller.EnemyNpcClasses[a].Character, 0);
		table.remove(controller.EnemyNpcClasses, a);
	end

	table.clear(self.Barricades);
end

return Objective;
