local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Objective = {};
Objective.__index = Objective;

local CollectionService = game:GetService("CollectionService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);

local templatePrefab = script:WaitForChild("DestructibleGenerator");

Objective.Title = "Protect Generator";
Objective.Description = "Protect the generators";

Objective.Controller = nil;
--==

function Objective.new()
	local self = {};
	
	setmetatable(self, Objective);
	return self;
end

function Objective:Load()
	Objective.PrefabsSpawns = {};

	for _, obj in pairs(self.Controller.StageElements:WaitForChild("GeneratorSpawns"):GetChildren()) do
		table.insert(Objective.PrefabsSpawns, obj:GetPivot());
	end

end

function Objective:Begin()
	self.PrefabsSpawned = 0;
	Objective.Prefabs = {};

	self.LastZombieSpawn = tick();
	
	self.Active = true;
	self.RoundDuration = 60;
	self.EndTime = tick()+self.RoundDuration;
	
	local spawnsList = {};
	
	for a=1, #Objective.PrefabsSpawns do
		local spawnCf = Objective.PrefabsSpawns[a];
		if self.Controller.HazardType ~= "HighSeas" or spawnCf.Position.Y >= 39 then
			table.insert(spawnsList, spawnCf);
		end
	end
	
	local nameTags = {"A"; "B"; "C"};
	for a=1, math.min(3, #self.Controller.Characters) do
		if #spawnsList <= 0 then continue end;
		local spawnCf = table.remove(spawnsList, math.random(1, #spawnsList));
		
		local newPrefab = templatePrefab:Clone();
		newPrefab:PivotTo(spawnCf);
		
		newPrefab.Name = `Generator {nameTags[a]}`;
		
		newPrefab:SetAttribute("EntityHudHealth", true);
		newPrefab.Parent = workspace.Entity;
		
		self.PrefabsSpawned = self.PrefabsSpawned +1;
		table.insert(Objective.Prefabs, newPrefab);
			
		local destructibleConfig = modDestructibles.createDestructible("Scarecrow");
		destructibleConfig:SetAttribute("_AttractRange", 999);
		destructibleConfig:SetAttribute("_ExpiringDamageTick", false);
		destructibleConfig.Parent = newPrefab;

		local destructible: DestructibleInstance = modDestructibles.getOrNew(destructibleConfig);
		destructible.BroadcastHealth = true;
		destructible.HealthComp:SetCanBeHurtBy("!Player&!Human");
		destructible.HealthComp:SetMaxHealth(1000 * (self.Controller.IsHard and 10 or 1));
		destructible.HealthComp:SetMaxArmor(100);
		destructible.HealthComp:Reset();

		destructible:SetupHealthbar{
			Size = UDim2.new(4, 0, 1, 0);
			Distance = 128;
			OffsetWorldSpace = Vector3.new(0, 3, 0);
			ShowLabel = true;
		};

		destructible.OnDestroy:Connect(function() 
			local destroyPos = destructible.Model:GetPivot().Position;
			for a=#Objective.Prefabs, 1, -1 do
				if Objective.Prefabs[a] == newPrefab then
					table.remove(Objective.Prefabs, a);
					break;
				end
			end

			Debugger:Warn("generator destroyed", #Objective.Prefabs, "remaining");

			shared.Notify(game.Players:GetPlayers(), "A generator has been destroyed!", "Negative");
			
			modAudio.Play("VechicleExplosion", self.Prefab.PrimaryPart.Position);
			modAudio.Play("Explosion4", self.Prefab.PrimaryPart.Position);

			local ex = Instance.new("Explosion");
			ex.BlastRadius = 16;
			ex.DestroyJointRadiusPercent = 0;
			ex.BlastPressure = 0;
			ex.Position = destroyPos;
			ex.Parent = workspace;
		end)
		
		task.spawn(function()
			while self.Active do
				task.wait(1);

				shared.modNpcs.listNpcClasses(function(npcClass)
					if not destructible.HealthComp:CanTakeDamageFrom(npcClass) then return end;
					if npcClass.HealthComp.IsDead then return end;

					local targetHandlerComp = npcClass:GetComponent("TargetHandler");
					if targetHandlerComp then
						targetHandlerComp:AddTarget(destructible.Model, destructible.HealthComp);
					end

					npcClass.OnThink:Fire();

					return false; -- no need to return list;
				end)
			end
		end)
	end

	self.Controller:Hud{
		HookEntity = Objective.Prefabs;
	};
end

function Objective:Tick()
	if tick() > self.EndTime and #self.Controller.EnemyNpcClasses <= 0 then
		return true;
	end
	
	if tick()-self.LastZombieSpawn >= 1 and #self.Controller.EnemyNpcClasses <= 50 and tick() < self.EndTime then
		self.LastZombieSpawn = tick();
		
		local enemyName = self.Controller:PickEnemy();
        local enemyLevel = self.Controller:GetWaveLevel();

		self.Controller:SpawnEnemy(enemyName, {
			Level = enemyLevel;
		});
	end
	
	if #Objective.Prefabs <= 0 then
		return true;
		
	end
	
	return false;
end

function Objective:End()
	self.Active = false;
	
	local prefabDestroyed = self.PrefabsSpawned - #Objective.Prefabs;
	if prefabDestroyed > 0 then
		shared.Notify(game.Players:GetPlayers(),
			`{#Objective.Prefabs <= 0 and "All" or prefabDestroyed} generators were destroyed.\nBlackout will be in effect for {prefabDestroyed} waves, disrupting senses.`, 
			"Negative"
		);

		modAudio.Play("LightsOff", workspace);

		for _, lightPart in pairs(CollectionService:GetTagged("LightSourcePart")) do
			if lightPart:IsA("BasePart") and lightPart.Material == Enum.Material.Neon then

				lightPart.Material = Enum.Material.Plastic;
				for _, obj in pairs(lightPart:GetDescendants()) do
					if obj:IsA("Light") and obj:GetAttribute("DefaultEnabled") == true then
						obj.Enabled = false;
					end
				end

			end
		end

		self.Controller:Schedule({
			Id = "Blackout";
			EndWave = self.Controller.Wave + prefabDestroyed;

			Modifier = {Id="Blackout"; Value=prefabDestroyed;};
			Task = function(job)
				Debugger:Log("Blackout Task");
				for _, lightPart in pairs(CollectionService:GetTagged("LightSourcePart")) do
					if lightPart:IsA("BasePart") and lightPart.Material == Enum.Material.Plastic then

						lightPart.Material = Enum.Material.Neon;
						for _, obj in pairs(lightPart:GetDescendants()) do
							if obj:IsA("Light") and obj:GetAttribute("DefaultEnabled") == true then
								obj.Enabled = true;
							end
						end

					end
				end
				shared.Notify(game.Players:GetPlayers(), "[Blackout] is no longer in effect.", "Inform");
			end;
			Tick = function(job)
				local wavesLeft = job.EndWave - self.Controller.Wave;
				if wavesLeft <= 0 then return end;

				Debugger:Log("Blackout Tick", wavesLeft);
				shared.Notify(game.Players:GetPlayers(), "[Blackout] still in effect for ".. wavesLeft .." waves.", "Important");
			end;
		})
		
	end
	
	for a=1, #Objective.Prefabs do
		game.Debris:AddItem(self.Prefabs[a], 0);
	end
	table.clear(Objective.Prefabs);
	
end

return Objective;
