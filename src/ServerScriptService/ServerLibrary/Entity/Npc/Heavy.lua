local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local ZombieModule = script.Parent.Zombie;

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);

local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);

-- Note; Function called for each zombie before zombie parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Prefab = npc;
		SpawnPoint = spawnPoint; -- CFrame;
		
		AggressLevel = 0;
		
		Properties = {
			BasicEnemy=true;
			WalkSpeed={Min=8; Max=12};
			AttackSpeed=2.3;
			AttackDamage=10;
			AttackRange=4;
			TargetableDistance=50;
		};

		Configuration = {
			Level=1;
			MoneyReward={Min=2; Max=4};
			ExperiencePool=35;
			ResourceDrop=modRewardsLibrary:Find("heavyzombie");
		};
	};

	--== Initialize;	
	function self.Initialize()
		local level = math.max(self.Configuration.Level-1, 0);

		self.Move.SetDefaultWalkSpeed = 10+math.floor(level/15);
		self.Move:Init();
		self.Immunity = 0.8;
		
		self.Humanoid.MaxHealth = math.max(200 + 100*level, 100);
		self.Humanoid.Health = self.Humanoid.MaxHealth;

		self.Properties.AttackDamage = 30 + 3*level;
		
		self.RandomClothing(self.Name, false);
		self.NekronMask();

		self.Think:Fire();
		coroutine.yield();
	end

	--== Components;
	
	self:AddComponent("AntiSit");
	self:AddComponent("WeakPoint");
	self:AddComponent("DropReward");
	self:AddComponent("BehaviorTree");
	self:AddComponent("RandomClothing");
	self:AddComponent(ZombieModule.OnDeath);
	self:AddComponent(ZombieModule.OnHealthChanged);
	self:AddComponent(ZombieModule.OnDamaged);
	self:AddComponent(ZombieModule.OnTarget);
	self:AddComponent(ZombieModule.HeavyAttack1);
	self:AddComponent(ZombieModule.Idle);
	self:AddComponent(ZombieModule.NekronMask);

	--== NPC Logic;
	self.Garbage:Tag(self.Think:Connect(function()
		self.BehaviorTree:RunTree("HeavyTree", true);
		self.Humanoid:SetAttribute("AggressLevel", self.AggressLevel);
	end));

	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	self.Garbage:Tag(self.Humanoid.Died:Connect(self.OnDeath));
	
	
	return self;
end
