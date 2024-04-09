local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local ZombieModule = script.Parent.Zombie;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);
local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);

-- Note; Function called for each zombie before zombie parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Prefab = npc;
		SpawnPoint = spawnPoint;
		
		Properties = {
			BasicEnemy=true;
			WalkSpeed={Min=14; Max=16};
			AttackSpeed=1;
			AttackDamage=30;
			AttackRange=8;
			TargetableDistance=70;
		};
		
		Configuration = {
			Level=1;
			MoneyReward={Min=4; Max=8};
			ExperiencePool=50;
		};
		
	};
	
	--== Initialize;
	function self.Initialize()
		local level = math.max(self.Configuration.Level-1, 0);

		self.Move.SetDefaultWalkSpeed = 15;
		self.Move:Init();

		self.Prefab:SetAttribute("EntityHudHealth", true);
		
		self.Humanoid.MaxHealth = 1000 + 2000*level;
		self.Humanoid.Health = self.Humanoid.MaxHealth;
		self.Properties.AttackDamage = 25 + 2*level;
		
		self.Properties.AttackCooldown = tick();

		self.Think:Fire();
		coroutine.yield();
	end
	
	--== Components;
	self:AddComponent("AntiSit");
	self:AddComponent("WeakPoint");
	self:AddComponent("DropReward");
	self:AddComponent(ZombieModule.OnDeath);
	self:AddComponent(ZombieModule.OnHealthChanged);
	self:AddComponent(ZombieModule.OnDamaged);
	self:AddComponent(ZombieModule.OnTarget);
	self:AddComponent(ZombieModule.BasicAttack1);
	
	
	--== Connections;
	self.Garbage:Tag(self.Think:Connect(function()
		self.BehaviorTree:RunTree("DrSinisterTree", true);
	end));

	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	self.Garbage:Tag(self.Humanoid.Died:Connect(self.OnDeath));
	
	
return self end
