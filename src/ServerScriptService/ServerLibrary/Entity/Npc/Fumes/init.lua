local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local ZombieModule = script.Parent.Zombie;

local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);

-- Note; Function called for each zombie before zombie parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Prefab = npc;
		SpawnPoint = spawnPoint; -- CFrame;
		
		Properties = {
			AttackSpeed = 2.3;
			AttackDamage = 10;
			AttackRange = 8;
		};

		Configuration = {
			Level=1;
			MoneyReward={Min=15; Max=20};
			ExperiencePool=40;
		};
	};

	--== Initialize;	
	function self.Initialize()
		local level = self.Configuration.Level-1;
		
		if self.HardMode then
			self.Humanoid.MaxHealth = math.max(123000 + 4000*level, 100);
			self.Properties.AttackDamage = 60;
			self.Move.SetDefaultWalkSpeed = 16;
			
		else
			self.Humanoid.MaxHealth = math.max(8000 + 2000*level, 100);
			self.Properties.AttackDamage = 30;
			self.Move.SetDefaultWalkSpeed = 10;
			
		end
		self.Humanoid.Health = self.Humanoid.MaxHealth;
		self.Move:Init();

		self.Garbage:Tag(self.Prefab:FindFirstChild("FumesEmitter", true));
		self.Think:Fire();
		coroutine.yield();
	end

	--== Components;
	
	self:AddComponent("AntiSit");
	self:AddComponent("WeakPoint");
	self:AddComponent("DropReward");
	self:AddComponent("BehaviorTree");
	self:AddComponent("CrateReward");
	self:AddComponent("Wield");
	self:AddComponent(ZombieModule.OnDeath);
	self:AddComponent(ZombieModule.OnHealthChanged);
	self:AddComponent(ZombieModule.OnDamaged);
	self:AddComponent(ZombieModule.OnTarget);
	self:AddComponent(ZombieModule.BasicAttack2);

	--== NPC Logic;
	self.Garbage:Tag(self.Think:Connect(function()
		self.BehaviorTree:RunTree(script.FumesTree, true);
	end));

	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	self.Garbage:Tag(self.Humanoid.Died:Connect(self.OnDeath));
	
	
	return self;
end
