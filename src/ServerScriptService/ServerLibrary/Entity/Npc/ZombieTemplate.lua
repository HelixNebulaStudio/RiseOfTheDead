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
			AttackSpeed=2;
			AttackDamage=10;
			AttackRange=5;
			TargetableDistance=50;
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
		self.Move:Init();
		
		local level = self.Configuration.Level-1;
		self.Humanoid.MaxHealth = math.max(100 + 100*level, 100);
		self.Humanoid.Health = self.Humanoid.MaxHealth;
		
		self.Properties.AttackDamage = 10 + 3*level;
		
		self.RandomClothing(self.Name);
		self.NekronMask();

		if self.Configuration.Level >= 10 then
			self:AddComponent(ZombieModule.HeavyAttack1);
		end

		--self.Prefab:SetAttribute("Debug", true);
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
	self:AddComponent(ZombieModule.BasicAttack2);
	self:AddComponent(ZombieModule.Idle);
	self:AddComponent(ZombieModule.NekronMask);

	--== NPC Logic;
	self.Garbage:Tag(self.Think:Connect(function()
		self.BehaviorTree:RunTree("ZombieTree", true);
		self.Humanoid:SetAttribute("AggressLevel", self.AggressLevel);
	end));

	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	self.Humanoid.Died:Connect(self.OnDeath);
	
	
	return self;
end
