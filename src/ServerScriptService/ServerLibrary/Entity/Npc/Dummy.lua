local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local ZombieModule = script.Parent.Zombie;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

-- Note; Function called for each zombie before zombie parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Prefab = npc;
		Name = npc.Name;
		Head = npc:WaitForChild("Head");
		Humanoid = npc:WaitForChild("Zombie");
		RootPart = npc.PrimaryPart;
		SpawnPoint = spawnPoint; -- CFrame;
		
		Properties = {
			BasicEnemy=true;
			WalkSpeed={Min=8; Max=12};
			AttackSpeed=2;
			AttackDamage=10;
			AttackRange=5;
			TargetableDistance=50;
		};
		
		Configuration = {
			Level=1;
			MoneyReward={Min=2; Max=5};
			ExperiencePool=20;
			ResourceDrop=modRewardsLibrary:Find("zombie");
		};
	};
	
	--== Initialize;
	function self.Initialize()
--		self.Humanoid.MaxHealth = 100 + 100*(self.Configuration.Level-1);
--		self.Humanoid.Health = self.Humanoid.MaxHealth;
--		self.Properties.AttackDamage = 5 + 6*self.Configuration.Level;
--		
--		self.LevelVisuals();
--		self.Properties.AttackCooldown = tick();
		repeat until not self.Update();
		Debugger:Log("Update died.")
	end
	
	--== Components;
--	self:AddComponent("Movement"); -- tested
--	self:AddComponent("Follow"); -- tested
--	self:AddComponent("Logic"); -- tested
--	self:AddComponent("DropReward");
--	self:AddComponent(ZombieModule.OnDeath);
--	self:AddComponent(ZombieModule.OnHealthChanged);
--	self:AddComponent(ZombieModule.OnDamaged);
--	self:AddComponent(ZombieModule.OnTarget);
--	self:AddComponent(ZombieModule.BasicAttack1);
--	self:AddComponent(ZombieModule.LevelVisuals);
--	self:AddComponent(ZombieModule.Idle);
	
	--== NPC Logic;
--	self.Logic:AddAction("Idle", self.Idle.Begin, self.Idle.Cancel);
--	
--	self.Logic:AddAction("Attack", function(enemiod, position)
--		if self.Properties.AttackCooldown == nil then self.Properties.AttackCooldown = tick(); end;
--		if tick()-self.Properties.AttackCooldown > self.Properties.AttackSpeed then
--			if position then self.Movement:Face(position) end;
--			self.Properties.AttackCooldown = tick();
--			self.BasicAttack1(enemiod);
--		end
--	end);
	
	function self.Update()
		if self == nil or self.IsDead or self.Humanoid.RootPart == nil then return false end;
--		local targetHumanoid = self.Target and self.Target:FindFirstChildWhichIsA("Humanoid") or nil;
--		local targetRootPart = self.Enemy and self.Enemy.RootPart;
--		
--		if self.Target ~= nil and targetRootPart ~= nil and targetHumanoid.Health > 0 then
--			self.Humanoid.WalkSpeed = random:NextInteger(self.Properties.WalkSpeed.Min, self.Properties.WalkSpeed.Max);
--			self.Follow(targetRootPart, 0.5);
--			if self.Enemy.Distance <= self.Properties.AttackRange then
--				self.Logic:Action("Attack", targetHumanoid, targetRootPart.CFrame.p);
--			end
--		else
--			self.Humanoid.WalkSpeed = random:NextInteger(self.Properties.WalkSpeed.Min*0.25, self.Properties.WalkSpeed.Max*0.4);
--			self.Follow();
--			self.Logic:SetAction("Idle");
--		end
--		
--		self.Logic:Wait(1);
		wait(2);
		return true;
	end
	
	--== Connections;
	--	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	--	self.Humanoid.Died:Connect(self.OnDeath);
	
return self end
