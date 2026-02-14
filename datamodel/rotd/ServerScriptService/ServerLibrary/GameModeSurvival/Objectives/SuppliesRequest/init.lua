local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Objective = {};
Objective.__index = Objective;

Objective.Title = "Supplies Request";
Objective.Description = "Call in resupply";

Objective.DifficultyModes = {Hard=false;};

Objective.Controller = nil;

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);
--==
function Objective.onRequire()
	shared.modEventService:OnInvoked("Generic_BindTrigger", function(eventPacket: EventPacket, ...)
		local player: Player? = eventPacket.Player;
		if player == nil then return end;

		local triggerId: string, interactable: InteractableInstance = ...;
		if triggerId ~= "ResupplyRadio" then return end;
		
		local objective = interactable.Values.s_Objective;
		if objective == nil then
			Debugger:StudioWarn(`{triggerId} Missing objective`, interactable);
			return;
		end

		if objective.StartTick == nil then
			objective.TenSecTick = tick();
			objective.StartTick = tick();

			interactable.Values.RadioActive = true;
			objective.LastReactivate = tick();

			modAudio.Play("Sonar", workspace);
			modAudio.Play("HordeGrowl", workspace);
			
			shared.Notify(game.Players:GetPlayers(), "Resupply has been requested!", "Important");

		elseif interactable.Values.CallInterupted == true then
			objective.LastReactivate = tick();
			objective.TimesReactivated = objective.TimesReactivated +1;
			interactable.Values.CallInterupted = false;
			
			modAudio.Play("Sonar", workspace);
			
			shared.Notify(game.Players:GetPlayers(), "Resupply beacon has been reactivated!", "Important");

		end

		objective.FiveSecTick = tick();
		objective.AlertLightPrefab:SetAttribute("Active", false);
		interactable:Sync();
		
	end);
end

function Objective.new()
	local self = {};
	
	setmetatable(self, Objective);
	return self;
end

function Objective:Load()
	self.ResupplyRadio = script:WaitForChild("RadioSystem");
end

function Objective:Begin()
	self.ResupplyObjectiveActive = true;
	
	local newPrefab = self.ResupplyRadio:Clone();
	
	local worldSpawn = workspace:FindFirstChildWhichIsA("SpawnLocation");
	local spawnCf = worldSpawn.Position + Vector3.new(0, worldSpawn.Size.Y/2, 0);
	
	newPrefab:PivotTo(CFrame.new(spawnCf) * worldSpawn.CFrame.Rotation);
	newPrefab.Name = "Resupply Radio";

	newPrefab:SetAttribute("EntityHudHealth", true);
	newPrefab.Parent = workspace.Environment.Game;
	
	local interactConfig = newPrefab:WaitForChild("MilitaryRadio"):WaitForChild("Interactable");
	local interactable: InteractableInstance = modInteractables.getOrNew(interactConfig);

	interactable.Values.s_Objective = self;
	interactable.Values.CallInterupted = false;
	interactable.Values.RadioActive = false;

	self.ActiveInteractData = interactable;
	self.AlertLightPrefab = newPrefab:WaitForChild("alertLight");
	
	local destructibleConfig = modDestructibles.createDestructible("Scarecrow");
	destructibleConfig:SetAttribute("_AttractRange", 999);
	destructibleConfig:SetAttribute("_ExpiringDamageTick", false);
	destructibleConfig.Parent = newPrefab;
	
	local destructible: DestructibleInstance = modDestructibles.getOrNew(destructibleConfig);
	destructible.BroadcastHealth = true;
	destructible.HealthComp:SetCanBeHurtBy("!Player&!Human"); -- not HumanoidType == Player & not Survivors
	destructible.HealthComp:SetMaxHealth(10000 * (self.Controller.IsHard and 10 or 1));
	destructible.HealthComp:Reset();

	destructible:SetupHealthbar{
		Size = UDim2.new(6, 0, 1, 0);
		Distance = 128;
		OffsetWorldSpace = Vector3.new(0, 8, 0);
		ShowLabel = true;
	};
	
	self.ActiveDestructibleInstance = destructible;

	destructible.OnDestroy:Connect(function()
		local destroyPos = destructible.Model:GetPivot().Position;

		self.ActiveRadioPrefab = nil;
		game.Debris:AddItem(self.Prefab, 5);

		shared.Notify(game.Players:GetPlayers(), "The resupply radio has been destroyed, the request failed!", "Negative");

		modAudio.Play("VechicleExplosion", destroyPos);
		modAudio.Play("Explosion4", destroyPos);

		local ex = Instance.new("Explosion");
		ex.BlastRadius = 16;
		ex.DestroyJointRadiusPercent = 0;
		ex.BlastPressure = 0;
		ex.Position = destroyPos;
		ex.Parent = workspace;
	end)
	
	
	task.spawn(function()
		while self.ResupplyObjectiveActive do
			task.wait(1);
		end
	end)

	self.Controller:Hud{
		HookEntity = {newPrefab};
	};
	
	self.ActiveRadioPrefab = newPrefab;
	self.WaveStartTick = tick();
	self.StartTick = nil;
	self.LastSpawn = tick();
	
	self.OneSecTick = tick();
	self.FiveSecTick = tick();
	self.LastReactivate = tick();
	self.TimesReactivated = 0;
	
	shared.Notify(game.Players:GetPlayers(), "The resupply radio requires activation to call in resupply!", "Important");

	self.SpawnCount = 0;
	self.SpawnPattern = 1;
	self.PauseTick = tick()+10;
	
	interactable:Sync();
end

function Objective:Tick()
	local destructible: DestructibleInstance = self.ActiveDestructibleInstance;
	if self.ActiveRadioPrefab == nil or destructible == nil or destructible.HealthComp.IsDead == true then
		return true;
	end
	
	local interactable: InteractableInstance = self.ActiveInteractData;

	local timelapseSinceStart = tick()-self.WaveStartTick;
	if tick()-self.OneSecTick > 1 then
		self.OneSecTick = tick();
		
		if self.StartTick then

			if interactable.Values.CallInterupted == true then
				destructible.HealthComp:TakeDamage(DamageData.new{
					Damage = 200;
				});
			end

			local isFiveSecTick = tick()-self.FiveSecTick > 5
			if isFiveSecTick then
				self.FiveSecTick = tick();

				if interactable.Values.CallInterupted ~= true then
					if tick()-self.LastReactivate > 10 and math.random(1, 6) == 1 and self.TimesReactivated < 2 then
						modAudio.Play("DoomAlarm", workspace).PlaybackSpeed = 0.2;
						shared.Notify(game.Players:GetPlayers(), "Transmission for resupply has been interrupted and needs to be reactivated!", "Important");
						
						self.AlertLightPrefab:SetAttribute("Active", true);
						interactable.Values.CallInterupted = true;
						interactable:Sync();
						
					else
						modAudio.Play("Sonar", workspace);
							
					end
					
				end
			end

			if interactable.Values.CallInterupted ~= true and tick()-self.StartTick > 60 then
				if math.random(1, 10) == 1 then
					destructible:SetEnabled(false);

					shared.Notify(game.Players:GetPlayers(), "Resupply transmission has been received, supply crate incoming!", "Important");
					self.Controller.ResupplyEnabled = true;

					return true;
					
				else
					if isFiveSecTick then
						shared.Notify(game.Players:GetPlayers(), "Resupply transmission receiving soon..", "Important");
					end
					modAudio.Play("Sonar", workspace);
					
				end
			end
			
		else
			if timelapseSinceStart > 10 then
				local destructibleInstance: DestructibleInstance = self.ActiveDestructibleInstance;
				destructibleInstance.HealthComp:TakeDamage(DamageData.new{
					Damage = 200;
				});
			end
			
		end
	end

	
	
	local maxSpawnRate = math.max(1-(timelapseSinceStart/60), 1);
	
	local canSpawn = tick()-self.LastSpawn > maxSpawnRate and #self.Controller.EnemyNpcClasses <= 50
	if self.PauseTick and tick() < self.PauseTick then
		canSpawn = false;
	end
	
	if canSpawn then
		self.LastSpawn = tick();

		local enemyName = self.Controller:PickEnemy();
        local enemyLevel = self.Controller:GetWaveLevel();

		self.Controller:SpawnEnemy(enemyName, {
			Level = enemyLevel;
		});
		
		self.SpawnCount = self.SpawnCount+1;
		self.PauseTick = nil;
	end

	if self.SpawnPattern == 1 then
		if math.fmod(self.SpawnCount, 30) == 0 and self.PauseTick == nil then
			self.PauseTick = tick()+10;
		end
	end
	
	return false;
end

function Objective:End()
	self.ResupplyObjectiveActive = false;
	
	self.ActiveInteractData = nil;
	
	game.Debris:AddItem(self.ActiveRadioPrefab, 0);
end

return Objective;
