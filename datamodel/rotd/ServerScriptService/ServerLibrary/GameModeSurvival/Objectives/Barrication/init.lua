local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);


local Objective = {
	Controller = nil;
};
Objective.__index = Objective;

Objective.Title = "Barrication";
Objective.Description = "Enemies' outside are immune, fortify up and hold your ground!";

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
			destructibleConfig:SetAttribute("_AttractRange", 32);
			destructibleConfig:SetAttribute("_ExpiringDamageTick", false);
			destructibleConfig.Parent = model;
			
			local destructible: DestructibleInstance = modDestructibles.getOrNew(destructibleConfig);
			destructible.BroadcastHealth = true;
			destructible.HealthComp:SetCanBeHurtBy("!Player&!Human"); -- not HumanoidType == Player & not Survivors
			destructible.HealthComp:SetMaxHealth(wave * 1000);
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
	Objective.ImmuneBreaks = {};

	local barricationPrefabs = self.Controller.StageElements:WaitForChild("Barrication");
	for _, obj in pairs(barricationPrefabs:WaitForChild("Materials"):GetChildren()) do
		table.insert(Objective.MaterialSpawns, obj);
	end

	for _, obj in pairs(barricationPrefabs:WaitForChild("Buildables"):GetChildren()) do
		table.insert(Objective.BuildableSpawns, obj);
	end

	for _, obj in pairs(barricationPrefabs:WaitForChild("ImmuneBreak"):GetChildren()) do
		table.insert(Objective.ImmuneBreaks, obj);
	end

end

function Objective:Begin()
	local controller = self.Controller;

	self.Barricades = {};

	self.LastSpawnTick = tick();
	self.PauseTick = tick();
	
	self.SpawnCount = 0;
    self.EliminateCount = math.ceil(math.clamp(controller.Wave *(controller.IsHard and 7 or 5), 20, 200));

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

	for _, regionPart in pairs(self.ImmuneBreaks) do
		regionPart.Parent = workspace.Debris;
	end

	for a=1, 4 do
		local newMat = table.remove(matPickList, math.random(1, #matPickList))
		newMat = newMat:Clone();
		newMat.Parent = workspace.Environment.Game;
		
		controller.StageGarbage:Tag(newMat);
	end

	local curObjectiveInfo = controller.CurObjective;
	local locationName = curObjectiveInfo.Locations[math.random(1, #curObjectiveInfo.Locations)];

	self.StartTime = tick()+5;
	controller:Hud{
		ObjectiveDesc = `Enemies' outside the {locationName} are immune, fortify up and hold your ground!`;
	};
end

function Objective:Tick()
	local controller = self.Controller;

	local endWaveBool = false;
	local canSpawn = true;
	
    local liveEnemies = self.Controller.EnemyNpcClasses;
	local timeLapse = math.max(0, tick()-self.StartTime);

	for a=#liveEnemies, 1, -1 do
		local npcClass: NpcClass = liveEnemies[a];
		
		local rpCf = npcClass:GetCFrame();
		local isInImmuneBreak = false;

		for _, regionPart in pairs(self.ImmuneBreaks) do
			if modVector.isPointInBounds(regionPart.Size, regionPart.CFrame, rpCf.Position) then
				isInImmuneBreak = true;
				break;
			end
		end

		if isInImmuneBreak then
			npcClass.Properties.Immunity = nil;

		else
			npcClass.Properties.Immunity = 1;

		end
		
	end


    if tick()-self.LastSpawnTick <= math.min(math.max(self.Controller.IsHard and 0.1 or 0.5, (#liveEnemies)/40), 1) then
        canSpawn = false;
    end
    if #self.Controller.EnemyNpcClasses > 100 then
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
		
		local enemyName = controller:PickEnemy();
		self.LastSpawnName = enemyName;
		
		local enemyLevel = controller:GetWaveLevel();
		controller:SpawnEnemy(enemyName, {
			Level = enemyLevel;
			Immunity = 1;
		});

		self.SpawnCount = self.SpawnCount+1;
		if timeLapse <= 15 then
			self.PauseTick = tick()+5;
		elseif timeLapse <= 30 then
			self.PauseTick = tick()+2.5;
		elseif timeLapse <= 40 then
			self.PauseTick = tick()+1;
		end
	end

	if self.SpawnCount >= self.EliminateCount then
		local enemiesLeft = #liveEnemies;
		if enemiesLeft <= 0 then
			endWaveBool = true;

		else
			if tick()-self.LastSpawnTick > 120 then
				if self.DespawnTick == nil or tick() > self.DespawnTick then
					self.DespawnTick = tick()+3;

					local pickEnemy = #liveEnemies > 1 and liveEnemies[math.random(1, #liveEnemies)] or liveEnemies[1];
					if pickEnemy then
						Debugger:Warn("Despawned potential stuck");
						pickEnemy:Destroy();
					end
				end
			end
		end
	end

	return endWaveBool;
end

function Objective:End()
	local controller = self.Controller;

	for _, regionPart in pairs(self.ImmuneBreaks) do
		regionPart.Parent = script;
	end

	table.clear(self.Barricades);
end

return Objective;
