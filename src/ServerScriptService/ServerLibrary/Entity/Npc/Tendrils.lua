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
			AttackSpeed = 2;
			AttackRange = 5;

			AttackDamage = nil;
		};

		Configuration = {
			Level=1;
			MoneyReward={Min=4; Max=5};
			ExperiencePool=45;
			ResourceDrop=modRewardsLibrary:Find("tendrils");
		};
		
		KnockbackResistant = true;
	};

	--== Initialize;	
	function self.Initialize()
		local level = math.max(self.Configuration.Level, 0);
		
		self.Humanoid.MaxHealth = math.max(200*level, 200);
		self.Humanoid.Health = self.Humanoid.MaxHealth;
		
		self.Properties.AttackDamage = 20 + 2*level;
		self.MeleeImmunity = 1;

		self.Move:Init();
		
		self.UpperTorso = self.Prefab:WaitForChild("UpperTorso");
		self.LowerTorsoJoint = self.Prefab:WaitForChild("LowerTorso"):WaitForChild("Root");
		
		self.Think:Fire();
		coroutine.yield();
	end

	--== Components;
	self:AddComponent("AntiSit");
	self:AddComponent("WeakPoint");
	self:AddComponent("DropReward");
	self:AddComponent("IsInVision");
	self:AddComponent(ZombieModule.OnDeath);
	self:AddComponent(ZombieModule.OnHealthChanged);
	self:AddComponent(ZombieModule.OnDamaged);
	self:AddComponent(ZombieModule.OnTarget);
	self:AddComponent(ZombieModule.BasicAttack2);

	--== Signals;
	self.Garbage:Tag(self.Think:Connect(function()
		self.BehaviorTree:RunTree("TendrilsTree", true);
		self.Humanoid:SetAttribute("AggressLevel", self.AggressLevel);
		
	end));

	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	self.Humanoid.Died:Connect(function()
		self.OnDeath()
		if self.TendrilRoot and self.TendrilRoot.Parent ~= nil then
			game.Debris:AddItem(self.TendrilRoot.Parent, 0);
		end
	end);
	
	
	return self;
end
