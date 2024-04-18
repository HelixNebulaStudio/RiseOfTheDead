local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local ZombieModule = script.Parent.Zombie;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);
local modAudio = require(game.ReplicatedStorage.Library.Audio);

-- Note; Function called for each zombie before zombie parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Name = npc.Name;
		Prefab = npc;
		SpawnPoint = spawnPoint;
		Humanoid = npc:FindFirstChildWhichIsA("Humanoid");
		RootPart = npc.PrimaryPart;
		
		Properties = {
			WalkSpeed = {Min=15; Max=18};
			AttackSpeed = 1;
			AttackDamage = 30;
			AttackRange = 4;
		};
		
		Configuration = {
			Level=1;
			MoneyReward={Min=25; Max=30};
			ExperiencePool=60;
		};
	};
	
	--== Initialize;
	function self.Initialize()
		local level = self.Configuration.Level-1;

		if self.HardMode then
			self.Humanoid.MaxHealth = math.max(300000 + 7000*level, 100);
			
		else
			self.Humanoid.MaxHealth = math.max(8000 + 2000*level, 100);

		end
		self.Humanoid.Health = self.Humanoid.MaxHealth;
		
		--self.Humanoid.MaxHealth = 4000 + 4000*(self.Configuration.Level-1);
		--self.Humanoid.Health = self.Humanoid.MaxHealth;
		
		self.Properties.PoisonGasCooldown = tick();
		self.Properties.AttackCooldown = tick();
		modAudio.Play("Flies", self.RootPart, true).RollOffMaxDistance = 128;
		
		self.LevelVisuals();
		repeat until not self.Update();
	end
	
	--== Components;
	self:AddComponent("Follow");
	self:AddComponent("Movement");
	self:AddComponent("Logic");
	self:AddComponent("CrateReward");
	self:AddComponent(ZombieModule.OnDeath);
	self:AddComponent(ZombieModule.OnHealthChanged);
	self:AddComponent(ZombieModule.OnDamaged);
	self:AddComponent(ZombieModule.OnTarget);
	self:AddComponent(ZombieModule.BasicAttack1);
	self:AddComponent(ZombieModule.PoisonGas);
	self:AddComponent(ZombieModule.LevelVisuals);
	
	--== NPC Logic;
	self.Logic:AddAction("Attack", function(enemiod, position)
		if self.Properties.AttackCooldown == nil then self.Properties.AttackCooldown = tick(); end;
		if tick()-self.Properties.AttackCooldown > self.Properties.AttackSpeed then
			self.Properties.AttackCooldown = tick();
			self.BasicAttack1(enemiod);
		end
	end);
	
	function self.Update()
		if self.IsDead or self.Humanoid.RootPart == nil then return false; end;
		
		local targetHumanoid = self.Enemy and self.Enemy.Humanoid or nil;
		local targetRootPart = self.Enemy and self.Enemy.RootPart;
		if self.Enemy ~= nil and targetRootPart ~= nil and targetHumanoid.Health > 0 then
			self.Logic:SetState("Aggro");
			
			self.Follow(targetRootPart, 1);
			local targetPlayer = game.Players:GetPlayerFromCharacter(self.Enemy.Character);
			if targetPlayer then
				self.Enemy.Distance = targetPlayer:DistanceFromCharacter(self.RootPart.Position);
				if self.Enemy.Distance < self.Properties.AttackRange then
					self.Logic:Action("Attack", targetHumanoid, targetRootPart.CFrame.p);
				end
				if self.Properties.PoisonGasCooldown == nil or tick()-self.Properties.PoisonGasCooldown > 15 then
					self.Properties.PoisonGasCooldown = tick();
					self.Follow();
					task.wait(1);
					
					self.PlayAnimation("PoisonGas",1);
					self.PoisonGas(20, 32, 12, 0.5);
					if self.IsDead or self.Humanoid.RootPart == nil then return false; end;
					self.StopAnimation("PoisonGas");
				end
			end
			self.Logic:Timeout("Aggro", 1);
			
		else
			self.Logic:SetState("Idle");
			self.Follow();
			
		end
		self.NextTarget();
		
		self.Logic:Timeout("Idle", 10);
		return true;
	end
	
	--== Connections;
	self.Humanoid.HealthChanged:Connect(self.OnHealthChanged);
	
return self end
