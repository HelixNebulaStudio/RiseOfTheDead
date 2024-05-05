local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local ZombieModule = script.Parent.Zombie;

local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);

local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);
--==

return function(npc, spawnPoint)
	--== Configurations;
	local self = modNpcComponent{
		Prefab = npc;
		SpawnPoint = spawnPoint;
		
		AggressLevel = 0;
		
		Properties = {
			BasicEnemy=true;
			AttackSpeed=2.3;
			AttackRange=4;
			TargetableDistance=50;

			AttackDamage=nil;
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
		local level = math.max(self.Configuration.Level, 0);

		self.Humanoid.MaxHealth = math.max(100 + 100*level, 100);
		self.Humanoid.Health = self.Humanoid.MaxHealth;

		self.Properties.AttackDamage = 30 + 3*level;

		self.Immunity = 0.8;

		self.Move.SetDefaultWalkSpeed = 10+math.floor(level/15);
		self.Move:Init();
		--
		
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

	--== Signals;
	self.Garbage:Tag(self.Think:Connect(function()
		self.BehaviorTree:RunTree("HeavyTree", true);
		self.Humanoid:SetAttribute("AggressLevel", self.AggressLevel);
	end));

	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	self.Garbage:Tag(self.Humanoid.Died:Connect(self.OnDeath));
	
	
	return self;
end
