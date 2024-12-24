local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local Objective = {};
Objective.__index = Objective;

Objective.Title = "Supplies Request";
Objective.DifficultyModes = {Hard=false;};

Objective.Controller = nil;

local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
local modNpc = require(game.ServerScriptService.ServerLibrary.Entity.Npc);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
--==

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
	
	local interactableModule = newPrefab:WaitForChild("MilitaryRadio"):WaitForChild("Interactable");
	local interactData = require(interactableModule);

	self.ActiveInteractData = interactData;
	self.AlertLightPrefab = newPrefab:WaitForChild("alertLight");

	self.DisconnectOnTrigger = modOnGameEvents:ConnectEvent("OnTrigger", function(player, interactData, packet)
		if not self.ResupplyObjectiveActive then return end;
		local triggerId = interactData.TriggerTag;

		if triggerId == "ResupplyRadio" then
			if self.StartTick == nil then
				self.TenSecTick = tick();
				self.StartTick = tick();

				interactData.RadioActive = true;
				self.LastReactivate = tick();

				modAudio.Play("Sonar", workspace);
				modAudio.Play("HordeGrowl", workspace);
				
				shared.Notify(game.Players:GetPlayers(), "Resupply has been requested!", "Important");

			elseif interactData.CallInterupted == true then
				self.LastReactivate = tick();
				self.TimesReactivated = self.TimesReactivated +1;
				interactData.CallInterupted = false;
				
				modAudio.Play("Sonar", workspace);
				
				shared.Notify(game.Players:GetPlayers(), "Resupply beacon has been reactivated!", "Important");

			end

			self.FiveSecTick = tick();
			self.AlertLightPrefab:SetAttribute("Active", false);
			interactData:Sync();
		end
	end);
	
	local humanoid = newPrefab:WaitForChild("Structure");
	humanoid.MaxHealth = 10000 * (self.Controller.IsHard and 10 or 1);
	humanoid.Health = humanoid.MaxHealth;

	local destructible = require(newPrefab:WaitForChild("Destructible"));
	self.ActiveDestructibleObj = destructible;

	function destructible:OnDestroy()
		Debugger:Warn("radio destroyed");

		self.ActiveRadioPrefab = nil;
		game.Debris:AddItem(self.Prefab, 5);

		shared.Notify(game.Players:GetPlayers(), "The resupply radio has been destroyed, the request failed!", "Negative");

		modAudio.Play("VechicleExplosion", self.Prefab.PrimaryPart.Position);
		modAudio.Play("Explosion4", self.Prefab.PrimaryPart.Position);

		local ex = Instance.new("Explosion");
		ex.BlastRadius = 16;
		ex.DestroyJointRadiusPercent = 0;
		ex.BlastPressure = 0;
		ex.Position = self.Prefab.PrimaryPart.Position;

		for _, obj in pairs(self.Prefab:GetDescendants()) do
			if obj:IsA("BasePart") then
				obj.Anchored = false;
				obj.CanCollide = true;
				obj:ApplyImpulse(Vector3.new(math.random(-50, 50), 20, math.random(-50, 50))*10);

			end
		end
	end
	
	
	newPrefab:PivotTo(CFrame.new(spawnCf) * worldSpawn.CFrame.Rotation);
	newPrefab.Name = "Resupply Radio";

	newPrefab:SetAttribute("EntityHudHealth", true);
	newPrefab.Parent = workspace.Environment;
	
	task.spawn(function()
		while self.ResupplyObjectiveActive do
			task.wait(1);
			
			for a=#modNpc.NpcModules, 1, -1  do
				local npcModule = modNpc.NpcModules[a] and modNpc.NpcModules[a].Module;

				if npcModule and not npcModule.IsDead and npcModule.OnTarget and npcModule.Humanoid and npcModule.Humanoid.Name == "Zombie" then
					npcModule.OnTarget(newPrefab);
				end
			end
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
end

function Objective:Tick()
	if self.ActiveRadioPrefab == nil or self.ActiveDestructibleObj.Destroyed == true then
		return true;
	end
	
	local timelapseSinceStart = tick()-self.WaveStartTick;
	if tick()-self.OneSecTick > 1 then
		self.OneSecTick = tick();
		
		if self.StartTick then

			if self.ActiveInteractData.CallInterupted == true then
				self.ActiveDestructibleObj:TakeDamagePackage(modDamagable.NewDamageSource{
					Damage=200;
					Dealer=script.BasicDamager;
				})
				--self.ActiveDestructibleObj:TakeDamage(200, script.BasicDamager);
			end

			local isFiveSecTick = tick()-self.FiveSecTick > 5
			if isFiveSecTick then
				self.FiveSecTick = tick();

				if self.ActiveInteractData.CallInterupted ~= true then
					if tick()-self.LastReactivate > 10 and math.random(1, 6) == 1 and self.TimesReactivated < 2 then
						modAudio.Play("DoomAlarm", workspace).PlaybackSpeed = 0.2;
						shared.Notify(game.Players:GetPlayers(), "Transmission for resupply has been interrupted and needs to be reactivated!", "Important");
						
						self.AlertLightPrefab:SetAttribute("Active", true);
						self.ActiveInteractData.CallInterupted = true;
						self.ActiveInteractData:Sync();
						
					else
						modAudio.Play("Sonar", workspace);
							
					end
					
				end
			end

			if self.ActiveInteractData.CallInterupted ~= true and tick()-self.StartTick > 60 then
				if math.random(1, 10) == 1 then
					self.ActiveDestructibleObj:SetEnabled(false);

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
				self.ActiveDestructibleObj:TakeDamagePackage(modDamagable.NewDamageSource{
					Damage=200;
					Dealer=script.BasicDamager;
				})
				--	:TakeDamage(200, script.BasicDamager);
			end
			
		end
	end

	
	
	local maxSpawnRate = math.max(1-(timelapseSinceStart/60), 1);
	
	local canSpawn = tick()-self.LastSpawn > maxSpawnRate and #self.Controller.EnemyModules <= 50
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
	
	if self.DisconnectOnTrigger then
		self.DisconnectOnTrigger();
		self.DisconnectOnTrigger = nil;
	end
	
	game.Debris:AddItem(self.ActiveRadioPrefab, 0);
end

return Objective;
