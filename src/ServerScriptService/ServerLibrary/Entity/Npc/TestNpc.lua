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
			WalkSpeed={Min=8; Max=12};
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
--		self.Humanoid.MaxHealth = 100 + 200*(self.Configuration.Level-1);
--		self.Humanoid.Health = self.Humanoid.MaxHealth;
--		self.Properties.AttackDamage = 10 + 4*(self.Configuration.Level-1);
--		self.Configuration.ExperiencePool = self.Configuration.ExperiencePool + 10*(self.Configuration.Level-1);
--		
--		self.LevelVisuals();
--		self.Properties.AttackCooldown = tick();
--		
--		if modBranchConfigs.CurrentBranch.Name == "Dev" then self.Configuration.ExperiencePool = 100; end;
		repeat until not self.Update();
	end
	
	--== Components;
--	self:AddComponent("Movement");
--	self:AddComponent("Follow");
--	self:AddComponent("Logic");
--	self:AddComponent("DropReward");
--	self:AddComponent(ZombieModule.OnDeath);
--	self:AddComponent(ZombieModule.OnHealthChanged);
--	self:AddComponent(ZombieModule.OnDamaged);
--	self:AddComponent(ZombieModule.OnTarget);
--	self:AddComponent(ZombieModule.BasicAttack1);
--	self:AddComponent(ZombieModule.LevelVisuals);
	
	--== NPC Logic;
--	self.Logic:AddAction("Idle", function()
--		repeat
--			if self.Logic.Cancelled then return; end;
--			if (self.SpawnPoint.p-self.RootPart.Position).Magnitude <= 32 then
--				self.Movement:EndMovement();
--				
--				if self.Logic.Cancelled then return; end;
--				if random:NextInteger(0,10) > 8 then
--					self.PlayAnimation("Idle");
--					modAudio.Play("ZombieIdle"..random:NextInteger(1, 4), self.RootPart).PlaybackSpeed = random:NextNumber(0.8, 1.2);
--				end
--				
--				if self.Logic.Cancelled then return; end;
--				self.Logic.ActionWait(random:NextNumber(5, 10));
--				
--				if self.Logic.Cancelled then return; end;
--				self.Movement:IdleMove(20);
--				
--				if self.Logic.Cancelled then return; end;
--				self.Logic.ActionWait(random:NextNumber(6, 32));
--			else
--				self.Movement:Move(self.SpawnPoint.p);
--			end
--			self.Logic.ActionWait(10);
--		until self.Logic.Cancelled;
--	end, function()
--		self.Movement:EndMovement();
--		self.StopAnimation("Idle");
--	end);
--	
--	self.Logic:AddAction("Attack", function(enemiod, position)
--		if self.Properties.AttackCooldown == nil then self.Properties.AttackCooldown = tick(); end;
--		if tick()-self.Properties.AttackCooldown > self.Properties.AttackSpeed then
--			if position then self.Movement:Face(position) end;
--			self.Properties.AttackCooldown = tick();
--			self.BasicAttack1(enemiod);
--		end
--	end);
--	
--	function self.Update()
--		if self.IsDead or self.Humanoid.RootPart == nil then return false end;
--		local targetHumanoid = self.Target and self.Target:FindFirstChildWhichIsA("Humanoid") or nil;
--		local targetRootPart = self.Enemy and self.Enemy.RootPart;
--		if self.Target ~= nil and targetRootPart ~= nil and targetHumanoid.Health > 0 then
--			self.Humanoid.WalkSpeed = random:NextInteger(self.Properties.WalkSpeed.Min, self.Properties.WalkSpeed.Max);
--			self.Follow(targetRootPart, 0.5);
--			local targetPlayer = game.Players:GetPlayerFromCharacter(self.Enemy.Character);
--			if targetPlayer then
--				self.Enemy.Distance = targetPlayer:DistanceFromCharacter(self.RootPart.Position);
--				if self.Enemy.Distance <= self.Properties.AttackRange then
--					self.Logic:Action("Attack", targetHumanoid, targetRootPart.CFrame.p);
--				end
--			end
--		else
--			self.Humanoid.WalkSpeed = random:NextInteger(self.Properties.WalkSpeed.Min*0.25, self.Properties.WalkSpeed.Max*0.4);
--			self.Follow();
--			--self.Logic:SetAction("Idle");
--		end
--		
--		self.Logic:Wait(1);
--		return true;
--	end
	function self.Update()
		if self.IsDead or self.Humanoid.Health <= 0 or self.Humanoid.RootPart == nil then return false end;
		wait(5);
		return true;
	end
	
	--== Connections;
--	self.Humanoid.HealthChanged:Connect(self.OnHealthChanged);
--	self.Humanoid.Died:Connect(self.OnDeath);
	
return self end
