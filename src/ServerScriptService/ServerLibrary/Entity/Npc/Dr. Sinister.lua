local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local ZombieModule = script.Parent.Zombie;

local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);
--==

return function(npc, spawnPoint)
	--== Configurations;
	local self = modNpcComponent{
		Prefab = npc;
		SpawnPoint = spawnPoint;
		
		Properties = {
			BasicEnemy=true;
			AttackSpeed=1;
			AttackRange=8; 
			TargetableDistance=70;

			AttackDamage=nil;
		};
		
		Configuration = {
			Level=1;
			MoneyReward={Min=4; Max=8};
			ExperiencePool=50;
		};
		
	};
	
	--== Initialize;
	function self.Initialize()
		local level = math.max(self.Configuration.Level, 0);

		self.Humanoid.MaxHealth = math.clamp(2000*level, 2000, 102400);
		self.Humanoid.Health = self.Humanoid.MaxHealth;

		self.Properties.AttackDamage = 25 + 2*level;
		
		self.Move.SetDefaultWalkSpeed = 15;
		self.Move:Init();

		self.Prefab:SetAttribute("EntityHudHealth", true);
		
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
	self:AddComponent(ZombieModule.BasicAttack2);
	
	
	--== Signals;
	self.Garbage:Tag(self.Think:Connect(function()
		self.BehaviorTree:RunTree("DrSinisterTree", true);
	end));

	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	self.Humanoid.Died:Connect(self.OnDeath);
	
	
return self end
