local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local BanditModule = script.Parent.Bandit;
local EnemyModule = script.Parent.Enemy;
local HumanModule = script.Parent.Human;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);

-- Note; Function called for each zombie before zombie parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Prefab = npc;
		Name = npc.Name;
		Head = npc:WaitForChild("Head");
		Humanoid = npc:WaitForChild("Bandit");
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
			MoneyReward={Min=45; Max=60};
			ExperiencePool=40;
			Audio={Hurt=false;};
		};
	};
	
	self.Speeches = {
		"Don't run so I can slice you!";
		"Let's not make this difficult!";
		"Which way is it, the easy way or the hard way?";
		"Do you need to catch a breath? Stand still!";
		"Come back here!";
		"Is this your blood on my blade?";
	}
	
	--== Initialize;
	function self.Initialize()
		self.Humanoid.Health = self.Humanoid.MaxHealth;
		self.Configuration.ExperiencePool = 35;

		if self.HardMode then
			self.Humanoid.MaxHealth = 95000 + ((#self.NetworkOwners-1) * 66000);
			self.Humanoid.Health = self.Humanoid.MaxHealth;
			self.KnockbackResistant = true;
			self.Properties.AttackDamage = 60;
		end
		
		self.Properties.AttackCooldown = tick();
		self.Wield.Equip("machete");
		pcall(function()
			self.Wield.ToolModule.Configurations.Damage = self.Properties.AttackDamage;
			self.Wield.ToolModule.Configurations.PrimaryAttackAnimationSpeed = 0.2;
		end);
		
		self.Wield.Targetable.Humanoid = 1;
		self.Wield.Targetable.Destructible = 500;
		
		if self.HardMode then
			self.Wield.ToolModule.OnEnemyHit = function(self, model, damage)
				local player = game.Players:GetPlayerFromCharacter(model);
				if player then
					modStatusEffects.Slowness(player, 5, 1);
				end
			end
		end
		
		--== Chatter;
		spawn(function()
			repeat
				if self.Speeches == nil then return end;
				local players = {};
				for a=1, #self.Enemies do
					local character = self.Enemies[a].Character;
					table.insert(players, game.Players:FindFirstChild(character.Name));
				end
				self.Chat(players, self.Speeches[random:NextInteger(1, #self.Speeches)]);
			until self.IsDead or self.Humanoid.RootPart == nil or not wait(random:NextNumber(32, 64));
		end)
	
		repeat until not self.Update();
		
		wait(5);
	end
	
	--== Components;
	self:AddComponent("Movement");
	self:AddComponent("Follow");
	self:AddComponent("Logic");
	self:AddComponent("IsInVision");
	self:AddComponent("CrateReward");
	self:AddComponent("Wield");
	self:AddComponent(HumanModule.Chat);
	self:AddComponent(EnemyModule.OnHealthChanged);
	self:AddComponent(EnemyModule.OnDamaged);
	self:AddComponent(EnemyModule.OnDeath);
	self:AddComponent(BanditModule.OnTarget);
	self:AddComponent(BanditModule.Idle);
	
	--== NPC Logic;
	self.Logic:AddAction("Idle", self.Idle.Begin, self.Idle.Cancel);
	
	function self.Update()
		if self.IsDead or self.Humanoid.RootPart == nil then return false end;
		
		if self.Enemy and self.Enemy.Humanoid and self.Enemy.Humanoid.Health > 0 then
			self.Logic:SetState("Aggro");
			
			self.Movement:SetWalkSpeed("default", 20);
			self.Follow(self.Enemy.Humanoid.RootPart, 0.5);
			
			self.Enemy.Distance = (self.Humanoid.RootPart.CFrame.p - self.Enemy.Humanoid.RootPart.CFrame.p).Magnitude;
			repeat
				if self.Enemy and self.Enemy.Humanoid and self.Enemy.Humanoid.RootPart and self.Enemy.Humanoid.Health > 0 then
					if self.Enemy.Distance <= self.Properties.AttackRange then
						self.Wield.SetEnemyHumanoid(self.Enemy.Humanoid);
						self.Movement:LookAt(self.Enemy.Humanoid.RootPart.Position);
						self.Movement:Face(self.Enemy.Humanoid.RootPart.Position);
						self.Wield.PrimaryFireRequest();
					end
				else
					self.Enemy = nil;
				end
				if self.Humanoid and self.Humanoid.RootPart and self.Enemy.Humanoid then
					self.Follow(self.Enemy.Humanoid.RootPart, 0.5);
					self.Movement:LookAt(self.Enemy.Humanoid.RootPart.Position);
					self.Enemy.Distance = (self.Humanoid.RootPart.CFrame.p - self.Enemy.Humanoid.RootPart.CFrame.p).Magnitude;
				end
				self.Logic:Timeout("Aggro", 0.1);
			until self.IsDead or self.Enemy == nil or self.Enemy.Distance >= 50;
			if self.Enemy == nil then
				self.NextTarget();
			end
			self.Logic:Timeout("Aggro", 1);
			
		else
			self.Logic:SetState("Idle");
			
			self.NextTarget();
			self.Movement:SetWalkSpeed("default", 8);
			self.Follow();
			self.Logic:Action("Idle");
			
		end

		self.Logic:Timeout("Idle", 10);
		return true;
	end
	
	--== Connections;
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	
return self end
