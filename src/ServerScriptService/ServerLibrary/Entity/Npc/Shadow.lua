local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local RunService = game:GetService("RunService");


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
		
		Properties = {
			WalkSpeed = {Min=0; Max=0};
			AttackSpeed = 0.5;
			AttackDamage = 5;
			AttackRange = 38;
		};
		
		Configuration = {
			Level=1;
			MoneyReward={Min=25; Max=30};
			ExperiencePool=80;
			CrateId="shadow";
		};
	};
	
	--== Initialize;
	function self.Initialize()
		self.Properties.VanishCooldown = tick();
		self.Properties.AttackCooldown = tick();
		self.Properties.BlinkCooldown = tick();
		
		self.LevelVisuals();
		repeat until not self.Update();
		
		wait(5);
	end
	
	--== Components;
	self:AddComponent("Movement");
	self:AddComponent("Logic");
	self:AddComponent("CrateReward");
	self:AddComponent(ZombieModule.OnDeath);
	self:AddComponent(ZombieModule.OnHealthChanged);
	self:AddComponent(ZombieModule.OnDamaged);
	self:AddComponent(ZombieModule.OnTarget);
	self:AddComponent(ZombieModule.BasicAttack1);
	self:AddComponent(ZombieModule.Vanish);
	self:AddComponent(ZombieModule.Blink);
	self:AddComponent(ZombieModule.LevelVisuals);
	
	--== NPC Logic;
	self.Logic:AddAction("Attack", function(enemiod, position)
		if self.Properties.AttackCooldown == nil then self.Properties.AttackCooldown = tick(); end;
		if tick()-self.Properties.AttackCooldown > self.Properties.AttackSpeed then
			self.Properties.AttackCooldown = tick();
			self.BasicAttack1(enemiod);
		end
	end);
	
	function self.Update()
		if self.IsDead or self.Humanoid.RootPart == nil then return false; end;
		
		local targetHumanoid = self.Enemy and self.Enemy.Humanoid or nil;
		local targetRootPart = self.Enemy and self.Enemy.RootPart;
		if self.Enemy ~= nil and targetRootPart ~= nil and targetHumanoid.Health > 0 then
			local targetPlayer = game.Players:GetPlayerFromCharacter(self.Enemy.Character);
			if targetPlayer then
				if targetHumanoid.RootPart then self.Movement:Face(targetHumanoid.RootPart.Position); end;
				self.Enemy.Distance = targetPlayer:DistanceFromCharacter(self.RootPart.Position);
				if self.Enemy.Distance < self.Properties.AttackRange then
					self.Logic:Action("Attack", targetHumanoid, targetRootPart.CFrame.p);
				elseif self.Properties.BlinkCooldown == nil or tick()-self.Properties.BlinkCooldown > 5 then
					self.Properties.BlinkCooldown = tick();
					self.Blink(targetHumanoid);
				end
				if self.Properties.VanishCooldown == nil or tick()-self.Properties.VanishCooldown > 8 then
					self.Properties.VanishCooldown = tick();
					self.Vanish(random:NextNumber(3, 6));
				end
			end
		end
		
		self.NextTarget();
		self.Logic:Wait(0.1);
		return true;
	end
	
	--== Connections;
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	self.Humanoid.Died:Connect(self.OnDeath);
	
return self end
