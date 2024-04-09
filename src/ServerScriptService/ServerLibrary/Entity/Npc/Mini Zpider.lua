local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local TweenService = game:GetService("TweenService");
local PhysicsService = game:GetService("PhysicsService");

local ZombieModule = script.Parent.Zombie;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);
local modAudio = require(game.ReplicatedStorage.Library.Audio);

-- Note; Function called for each zombie before zombie parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Name = npc.Name;
		Prefab = npc;
		SpawnPoint = spawnPoint;
		Humanoid = npc:FindFirstChildWhichIsA("Humanoid");
		RootPart = npc.PrimaryPart;
		PathAgent = {AgentRadius=3; AgentHeight=1.5;};
		
		Properties = {
			WalkSpeed = {Min=25; Max=30};
			AttackSpeed = 1;
			AttackDamage = 15;
			AttackRange = 5;
		};
		
		Configuration = {
			Level=1;
			MoneyReward={Min=5; Max=20};
			ExperiencePool=2;
			Audio={
				Attack="SpiderAttack1";
				Death="SpiderDeath1";
				Hurt=false;
			};
		};
	};
	
	--== Initialize;
	function self.Initialize()
		self.Properties.AttackCooldown = tick();
		self.Humanoid.WalkSpeed = random:NextNumber(self.Properties.WalkSpeed.Min, self.Properties.WalkSpeed.Max);
		
		repeat until not self.Update();
	end
	
	--== Components;
	self:AddComponent("Movement");
	self:AddComponent("Follow");
	self:AddComponent("Logic");
	self:AddComponent(ZombieModule.OnDeath);
	self:AddComponent(ZombieModule.OnHealthChanged);
	self:AddComponent(ZombieModule.OnDamaged);
	self:AddComponent(ZombieModule.OnTarget);
	self:AddComponent(ZombieModule.BasicAttack1);
	self:AddComponent(ZombieModule.Leap);
	
	--== NPC Logic;
	self.Logic:AddAction("Attack", function(enemiod, position)
		if self.Properties.AttackCooldown == nil then self.Properties.AttackCooldown = tick(); end;
		if tick()-self.Properties.AttackCooldown > self.Properties.AttackSpeed then
			self.Properties.AttackCooldown = tick();
			self.BasicAttack1(enemiod);
		end
	end);
	
	self.Logic:AddAction("Leap", function(targetRootPart)
		if self.Properties.LeapCooldown == nil or tick()-self.Properties.LeapCooldown > 4 then
			self.Properties.LeapCooldown = tick();
			self.Follow();
			wait(0.3);
			if self.IsDead then return end;
			self.Leap(targetRootPart.CFrame.p, 80)
			wait(0.5);
			if self.IsDead then return end;
			self.Follow(targetRootPart, 1);
		end
	end);
	
	function self.Update()
		if self.IsDead or self.Humanoid.RootPart == nil then return false; end;
		
		local targetHumanoid = self.Enemy and self.Enemy.Humanoid or nil;
		local targetRootPart = self.Enemy and self.Enemy.RootPart;
		if self.Enemy ~= nil and targetRootPart ~= nil and targetHumanoid.Health > 0 then
			self.Follow(targetRootPart, 1);
			local targetPlayer = game.Players:GetPlayerFromCharacter(self.Enemy.Character);
			if targetPlayer then
				self.Enemy.Distance = targetPlayer:DistanceFromCharacter(self.RootPart.Position);
				if self.Enemy.Distance < self.Properties.AttackRange then
					self.Logic:Action("Attack", targetHumanoid, targetRootPart.CFrame.p);
				else
					self.Logic:Action("Leap", targetRootPart);
				end
			end
		else
			self.Follow();
		end
		self.Logic:Wait(1);
		return true;
	end
	
	--== Connections;
	self.Humanoid.HealthChanged:Connect(self.OnHealthChanged);
	
return self end
