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
	shared.modEventService:OnInvoked("Interactables_BindMakeshiftBuilt", function(event: EventPacket, ...)
		local interactable: InteractableInstance, info: InteractInfo = ...;
		
		local config = interactable.Config;
		if config:GetAttribute("BuildType") ~= "Barricade" then return end;


		task.spawn(function()
			local model = config.Parent;
			if model == nil or model:FindFirstChild("Destructible") then return end;

			local wave = config:GetAttribute("Wave") or 1;

			local destructibleConfig = modDestructibles.createDestructible("Scarecrow");
			destructibleConfig:SetAttribute("_AttractRange", 350);
			destructibleConfig:SetAttribute("_ExpiringDamageTick", false);
			destructibleConfig.Parent = model;
			
			local destructible: DestructibleInstance = modDestructibles.getOrNew(destructibleConfig);
			destructible.BroadcastHealth = true;
			destructible.HealthComp:SetCanBeHurtBy("!Player&!Human"); -- not HumanoidType == Player & not Survivors
			destructible.HealthComp:SetMaxHealth(wave * 700);
			destructible.HealthComp:Reset();

			destructible:SetupHealthbar{
				Size = UDim2.new(4, 0, 1, 0);
				Distance = 128;
				OffsetWorldSpace = Vector3.new(0, 3, 0);
				ShowLabel = true;
			};
		end)
	end)
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

	self.State = 1;

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

	local curObjectiveInfo = controller.CurObjective;
	local locationName = curObjectiveInfo.Locations[math.random(1, #curObjectiveInfo.Locations)];

	local barricationDuration = math.clamp(200 - (controller.Wave * 5), 100, 200);

	controller.WaveStartTime = workspace:GetServerTimeNow();
	controller.WaveDuration = math.floor(barricationDuration);
	controller:Hud{
		ObjectiveDesc = `You have {barricationDuration} seconds to barricade the {locationName}.`;
	};
end

function Objective:Tick()
	local controller = self.Controller;

	local endWaveBool = false;
	local canSpawn = false;
	local immunity = nil;

	if self.State == 1 then
		if workspace:GetServerTimeNow() > controller.WaveStartTime + controller.WaveDuration then
			self.State = 2;
				
			self.RoundDuration = math.clamp(self.Controller.Wave * 8, 150, 300);
			self.EndTime = tick() + self.RoundDuration;
			self.LastSpawn = tick();

			modAudio.Play("DeathClock", workspace);
			
			controller.WaveStartTime = workspace:GetServerTimeNow();
			controller.WaveDuration = self.RoundDuration;
			controller:Hud{
				ObjectiveDesc = `Survive the timer.`;
			}
		end

		canSpawn = tick()-self.LastSpawn > 5 and #controller.EnemyNpcClasses <= 10;

	elseif self.State == 2 then

		local timeRemain = math.max(self.EndTime-tick(), 0);
		local timeLapsed = self.RoundDuration-timeRemain;
		local maxSpawnRate = math.clamp(timeRemain*0.05, 1/(math.max(controller.Wave/5, 1)), 1);
		
		canSpawn = timeRemain > 1 and tick()-self.LastSpawn > maxSpawnRate and #controller.EnemyNpcClasses <= 50;
		if self.PauseTick and tick() < self.PauseTick then
			canSpawn = false;
		end
		
		immunity = math.clamp(timeLapsed/(self.RoundDuration-60), 0, 1.1);

		if timeRemain <= 0 then
			endWaveBool = true;
		end
	end

	if canSpawn then
		self.LastSpawn = tick();
		
		local enemyName = controller:PickEnemy();
		self.LastSpawnName = enemyName;
		
		local enemyLevel = controller:GetWaveLevel();
		controller:SpawnEnemy(enemyName, {
			Level = enemyLevel;
			Immunity = immunity;
		});

		self.PauseTick = tick()+1;
	end

	return endWaveBool;
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
