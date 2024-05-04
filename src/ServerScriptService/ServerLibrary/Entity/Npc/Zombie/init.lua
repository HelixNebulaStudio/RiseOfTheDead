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
		
		AggressLevel = -1;
		
		Properties = {
			BasicEnemy=true;
			AttackSpeed=2;
			AttackRange=5;
			TargetableDistance=50;

			AttackDamage=nil;
		};

		Configuration = {
			Level=1;
			MoneyReward={Min=2; Max=4};
			ExperiencePool=20;
			ResourceDrop=modRewardsLibrary:Find("zombie");
		};
	};

	--== Initialize;
	function self.Initialize()
		local level = math.max(self.Configuration.Level-1, 0);
		
		self.Move.SetDefaultWalkSpeed = 18+math.floor(level/10);
		self.Move:Init();
		
		self.Humanoid.MaxHealth = level == 0 and 50 or math.max(100 + 50*level, 100);
		self.Humanoid.Health = self.Humanoid.MaxHealth;

		self.Properties.AttackDamage = 5 + (level/2);
		
		self.RandomClothing(self.Name);
		self.NekronMask();

		self.Think:Fire();
		coroutine.yield();
	end


	--== Components;
	self:AddComponent("AntiSit");
	self:AddComponent("WeakPoint");
	self:AddComponent("DropReward");
	self:AddComponent("RandomClothing");
	self:AddComponent(ZombieModule.OnDeath);
	self:AddComponent(ZombieModule.OnHealthChanged);
	self:AddComponent(ZombieModule.OnDamaged);
	self:AddComponent(ZombieModule.OnTarget);
	self:AddComponent(ZombieModule.BasicAttack2);
	self:AddComponent(ZombieModule.Idle);
	self:AddComponent(ZombieModule.NekronMask);


	--== Signals;
	self.Garbage:Tag(self.Think:Connect(function()
		self.BehaviorTree:RunTree("ZombieTree", true);
		self.Humanoid:SetAttribute("AggressLevel", self.AggressLevel);
	end));

	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	self.Garbage:Tag(self.Humanoid.Died:Connect(self.OnDeath));
	
	
	return self;
end
