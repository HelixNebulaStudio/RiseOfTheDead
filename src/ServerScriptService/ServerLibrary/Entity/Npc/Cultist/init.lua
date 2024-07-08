local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);

local CultistModule = script;
local BanditModule = script.Parent.Bandit;
local EnemyModule = script.Parent.Enemy;
local HumanModule = script.Parent.Human;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);

-- Note; Function called for each zombie before zombie parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Prefab = npc;
		Name = npc.Name;
		Head = npc:WaitForChild("Head");
		Humanoid = npc:WaitForChild("Cultist");
		RootPart = npc.PrimaryPart;
		SpawnPoint = spawnPoint; -- CFrame;
		Smart = true;
		
		Properties = {
			WalkSpeed={Min=8; Max=20};
			AttackSpeed=1;
			AttackDamage=20;
			AttackRange=6;
			TargetableDistance=256;
		};
		
		Configuration = {
			Level=1;
			MoneyReward={Min=2; Max=4};
			ExperiencePool=40;
			Audio={Hurt=false;};
			ResourceDrop=modRewardsLibrary:Find("bandit");
		};

		DespawnPrefab = 10;
	};
	
	self.Speeches = {};
	
	--== Initialize;
	function self.Initialize()
		self.Humanoid.MaxHealth = 400 + 200*(self.Configuration.Level-1);
		self.Humanoid.Health = self.Humanoid.MaxHealth;
		
		self.RandomSkin();
		self.Properties.AttackCooldown = tick();
		self.Wield.Equip("survivalknife");
		
		repeat until not self.Update();
	end
	
	function self.CantFollow(destination)
		Debugger:Log("CantFollow");
		if self.CutsceneMode then return end;
		self:Destroy();
	end
	
	--== Components;
	self:AddComponent("AntiSit");
	self:AddComponent("Logic");
	self:AddComponent("IsInVision");
	self:AddComponent("DropReward");
	self:AddComponent("Wield");
	
	self:AddComponent(HumanModule.Chat);
	self:AddComponent(HumanModule.Chatter);
	
	self:AddComponent(EnemyModule.OnHealthChanged);
	self:AddComponent(EnemyModule.OnDeath);
	self:AddComponent(EnemyModule.OnDamaged);
	
	self:AddComponent(BanditModule.OnTarget);
	self:AddComponent(BanditModule.Idle);
	
	self:AddComponent(CultistModule.RandomSkin);
	
	--== NPC Logic;
	function self.Update()
		if self == nil then return false end;
		if self.IsDead or self.Humanoid.RootPart == nil then return false end;
		
		self.Wield.Targetable.Zombie = 1;

		if self.HoodSpawn == nil or tick()+55 > self.HoodSpawn then
			self.Wield.Targetable.Humanoid = 1;
		end
		
		if self.CutsceneMode then
			wait(0.1);
		else
	
			if self.Enemy and self.Enemy.Humanoid and self.Enemy.Humanoid.Health > 0 and self.Enemy.Humanoid.RootPart then
				local enemyRootPart = self.Enemy.Humanoid.RootPart;
				self.Logic:SetState("Aggro");

				self.Move:Follow(enemyRootPart, 2);

				local enemyHumanoidType = self.Enemy.Humanoid.Name;
				pcall(function()
					self.Wield.ToolModule.Configurations.PrimaryAttackAnimationSpeed = 0.2;

					if enemyHumanoidType == "Humanoid" then
						self.Wield.ToolModule.Configurations.Damage = 15;
					elseif enemyHumanoidType == "Zombie" then
						self.Wield.ToolModule.Configurations.Damage = math.clamp(self.Enemy.Humanoid.MaxHealth * 0.1, 40, 30000);
					end
				end);

				self.Enemy.Distance = (self.RootPart.CFrame.p - enemyRootPart.CFrame.p).Magnitude;
				repeat
					if self == nil then break end;
					
					if self.Enemy and self.Enemy.Humanoid and enemyRootPart and self.Enemy.Humanoid.Health > 0 then
						if self.Enemy.Distance <= self.Properties.AttackRange then
							self.Wield.SetEnemyHumanoid(self.Enemy.Humanoid);
							self.Move:LookAt(enemyRootPart.Position);
							self.Wield.PrimaryFireRequest();
						end
					else
						self.Enemy = nil;
					end
					if self.Humanoid and self.Humanoid.RootPart and self.Enemy and self.Enemy.Humanoid then
						self.Move:Follow(enemyRootPart);
						self.Move:LookAt(enemyRootPart.Position);
						self.Enemy.Distance = (self.Humanoid.RootPart.CFrame.p - enemyRootPart.CFrame.p).Magnitude;
					else
						if self.Prefab then self.Prefab:Destroy() end;
					end
						
					self.Logic:Timeout("Aggro", 0.1);

				until self.IsDead or self.Enemy == nil or self.Enemy.Distance >= 50;

				if self.Enemy == nil then
					if self.HoodSpawn then
						self:Destroy();
						return;
					end
					self.NextTarget();
				end
				self.Logic:Timeout("Aggro", 1);

			else
				self.Logic:SetState("Idle");

				self.NextTarget();
				self.Move:Stop();

			end
		end

		if self.HoodSpawn and tick() > self.HoodSpawn then
			self:Destroy();
		end

		self.Logic:Timeout("Idle", 10);
		return true;
	end
	
	--== Connections;
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	self.Humanoid.Died:Connect(self.OnDeath);
	
return self end
