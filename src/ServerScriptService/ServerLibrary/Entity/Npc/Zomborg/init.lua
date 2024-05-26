local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local TweenService = game:GetService("TweenService");
local RunService = game:GetService("RunService");

local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);

local remoteGenerateArcParticles = modRemotesManager:Get("GenerateArcParticles");

local ZombieModule = script.Parent.Zombie;
--== Modules
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);
local modAudio = require(game.ReplicatedStorage.Library.Audio);

local Arc = {
	Color = Color3.fromRGB(255, 0, 4);
	Color2 = Color3.fromRGB(8, 0, 255);
	Amount = 2;
	Thickness = 0.35;
};
-- Note; Function called for each zombie before zombie parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Name = npc.Name;
		Prefab = npc;
		SpawnPoint = spawnPoint;
		Humanoid = npc:FindFirstChildWhichIsA("Humanoid");
		RootPart = npc.PrimaryPart;
		PathAgent = {AgentRadius=2; AgentHeight=6;};
		
		Properties = {
			WalkSpeed = {Min=12; Max=16};
			AttackSpeed = 1.5;
			AttackDamage = 45;
			AttackRange = 7;
		};
		
		Configuration = {
			Level=1;
			MoneyReward={Min=60; Max=80};
			ExperiencePool=50;
		};
	};

	--== Initialize;
	self:SetClientScript(script:WaitForChild("ZomborgEffects"));
	
	function self.Initialize()
		self.Properties.AttackCooldown = tick();
		self.Properties.StunCooldown = tick();
		self.Properties.ShieldTriggers = {self.Humanoid.MaxHealth*0.3; self.Humanoid.MaxHealth*0.6; self.Humanoid.MaxHealth*0.9};
		self.Properties.ExplosionDamage = 30;
		self.Properties.ExplosionRange = 85;
		self.Properties.MaxImmunity = 1;

		self.EffectRemote = Instance.new("RemoteEvent");
		self.EffectRemote.Name = "ZomborgRemote";
		self.EffectRemote.Parent = self.Prefab;
		
		--self.LocalScripts = {};
		--for a=1, #self.Enemies do
		--	if self.Enemies[a].Character then
		
		--		local clientZomborg = script.ZomborgEffects:Clone();
		--		table.insert(self.LocalScripts, clientZomborg);
		--		local npcTag = clientZomborg:WaitForChild("Npc");
		--		npcTag.Value = self.Prefab;
		
		--		self.EffectRemote = Instance.new("RemoteEvent");
		--		self.EffectRemote.Name = "EffectRemote";
		--		self.EffectRemote.Parent = self.Prefab;
		
		--		clientZomborg.Parent = self.Enemies[a].Character;
		--	end
		--end
		--for a=1, #self.LocalScripts do
		--	game.Debris:AddItem(self.LocalScripts[a], 0);
		--end
			
		self.LevelVisuals();
		repeat until not self.Update();
		
		wait(5);
	end
	
	--== Components;
	self:AddComponent("AntiSit");
	self:AddComponent("Follow");
	self:AddComponent("Movement");
	self:AddComponent("Logic");
	self:AddComponent("CrateReward");
	self:AddComponent(ZombieModule.OnDeath);
	self:AddComponent(ZombieModule.OnHealthChanged);
	self:AddComponent(ZombieModule.OnDamaged);
	self:AddComponent(ZombieModule.OnTarget);
	self:AddComponent(ZombieModule.BasicAttack1);
	self:AddComponent(ZombieModule.LevelVisuals);
	
	--== NPC Logic;
	self.Logic:AddAction("Attack", function(enemiod, position)
		if tick()-self.Properties.AttackCooldown > self.Properties.AttackSpeed then
			self.Properties.AttackCooldown = tick();
			self.BasicAttack1(enemiod);
		end
	end);
	
	self.Logic:AddAction("Stun", function(targetPlayer)
		if tick()-self.Properties.StunCooldown > 10 then
			self.Properties.StunCooldown = tick();
			local targetHumanoid = self.Enemy and self.Enemy.Humanoid or nil;
			local bodyPart = self.Enemy and self.Enemy.Character and self.Enemy.Character:FindFirstChild("UpperTorso") or nil;
			
			if targetPlayer and self.Enemy and bodyPart then
				self.Follow();
				self.PlayAnimation("ShieldCharge",0.1);
				modAudio.Play("Electrocute", self.RootPart);
				self.Movement:Face(bodyPart.Position);
				
				self.EffectRemote:FireAllClients("shock", bodyPart);
				modStatusEffects.Stun(targetPlayer, 2);
				self.Enemy.Ignore = true;
				self.NextTarget();
				wait(1);
				self.StopAnimation("ShieldCharge",0.5);
				self.Enemy.Ignore = nil;
			end
		end
	end);
	
	self.Logic:AddAction("ChargeShield", function()
		if self.IsDead then return end;
		local size = 1;
		local shield = Instance.new("Part");
		shield.Color = Color3.fromRGB(255, 0, 0);
		shield.CanCollide = false;
		shield.Shape = Enum.PartType.Ball;
		shield.Size = Vector3.new(size, size, size);
		shield.Material = Enum.Material.ForceField;
		shield.Transparency = 1;
		shield.Massless = true;
		shield.CFrame = self.Prefab.LeftHand.CFrame;
		shield.Anchored = true;
		shield.Parent = self.Prefab;
		Debugger.Expire(shield, 3);
		
		if self.EntityStatus:GetOrDefault("ElectricMod") ~= nil then
			self.Properties.MaxImmunity = 0.8;
		end
		
		local attackers = self.Status:GetAttackers();
		for a=0.35, 1.01, 0.00338 do
			self.Immunity = math.clamp(a, 0, self.Properties.MaxImmunity);
			shield.Transparency = 1-(a*0.6);
			local shieldSize = size+a*3;
			shield.Size = Vector3.new(shieldSize, shieldSize, shieldSize);

			if self.IsDead then return end;
			shield.CFrame = self.Prefab.LeftHand.CFrame;
			if a%0.1 then
				local rng = Vector3.new(random:NextNumber(-1, 1), random:NextNumber(-1, 1), random:NextNumber(-1, 1));
				local rngDir = rng.Unit*(shieldSize/2);
				for b=1, #attackers do
					local p = attackers[b];
					remoteGenerateArcParticles:FireClient(p, 0.2, shield.Position, shield.Position+rngDir, Arc.Color, Arc.Color2, Arc.Amount, Arc.Thickness);
				end
			end
			RunService.Heartbeat:Wait();
		end
		self.Immunity = math.clamp(1, 0, self.Properties.MaxImmunity);
		for a=0, 30*3 do
			if a%15 then
				local rng = Vector3.new(random:NextNumber(-1, 1), random:NextNumber(-1, 1), random:NextNumber(-1, 1));
				local rngDir = rng.Unit*(shield.Size.X/2);
				for b=1, #attackers do
					local p = attackers[b];
					remoteGenerateArcParticles:FireClient(p, 0.2, shield.Position, shield.Position+rngDir, Arc.Color, Arc.Color2, Arc.Amount, Arc.Thickness);
				end
			end
			if self.IsDead then return end;
			RunService.Heartbeat:Wait();
		end
		for a=0, 1, 0.1 do
			shield.Transparency = (a*0.5);
			shield.Size = Vector3.new(a*self.Properties.ExplosionRange, a*self.Properties.ExplosionRange, a*self.Properties.ExplosionRange);
			if self.IsDead then return end;
			RunService.Heartbeat:Wait();
		end
		if self.Arena then
			if self.IsDead then return end;
			local objs = self.Arena.Scene.Physics:GetChildren();
			for a=1, #objs do
				local o = objs[a]:IsA("BasePart") and objs[a] or objs[a].PrimaryPart;
				if o:CanSetNetworkOwnership() then
					local dist = (o.Position-self.RootPart.Position).Magnitude;
					local dir = (o.Position-self.RootPart.Position+Vector3.new(0, 5, 0)).Unit;
					if dist <= self.Properties.ExplosionRange then
						local power = (1-dist/self.Properties.ExplosionRange);
						if objs[a].Name == "drum" then
							o:SetNetworkOwner(nil);
							o.Velocity = dir*power*200;
						elseif objs[a].Name == "Crate" then
							o:SetNetworkOwner(nil);
							o.Velocity = dir*power*100;
						end
					end
				end
			end
		end
		modAudio.Play("Explosion4", self.RootPart).PlaybackSpeed = 1.5;
		if self.IsDead then return end;
		for a=1, #attackers do
			local p = attackers[a];
			local humanoid = p and p.Character and p.Character:FindFirstChild("Humanoid");
			if humanoid then
				local dist = p:DistanceFromCharacter(self.RootPart.Position);
				local dmg = math.clamp(self.Properties.ExplosionDamage*(1-dist/self.Properties.ExplosionRange), 0, 9999);
				self:DamageTarget(humanoid.Parent, dmg);
			end
		end
		if self.IsDead then return end;
		for a=0, 1, 0.1 do
			shield.Transparency = (a*0.5);
			shield.Size = Vector3.new(a*self.Properties.ExplosionRange, a*self.Properties.ExplosionRange, a*self.Properties.ExplosionRange);
			RunService.Heartbeat:Wait();
		end
		modAudio.Play("Explosion4", self.RootPart).PlaybackSpeed = 0.7;
		for a=1, #attackers do
			local p = attackers[a];
			local humanoid = p and p.Character and p.Character:FindFirstChild("Humanoid");
			if humanoid then
				local dist = p:DistanceFromCharacter(self.RootPart.Position);
				local dmg = math.clamp(self.Properties.ExplosionDamage*(1-dist/self.Properties.ExplosionRange), 0, 9999);
				self:DamageTarget(humanoid.Parent, dmg);
			end
		end
		self.Immunity = 0;
		game.Debris:AddItem(shield, 0);
		self.StopAnimation("ShieldCharge",1);
		self.Properties.Shielding = false;
		self.Properties.StunCooldown = tick()-7;
		self.Properties.MaxImmunity = 1;
	end);
	
	function self.Update()
		if self.IsDead or self.Humanoid.RootPart == nil then return false; end;
		
		for a=1, #self.Properties.ShieldTriggers do
			if self.Humanoid.Health <= self.Properties.ShieldTriggers[a] then
				table.remove(self.Properties.ShieldTriggers, a);
				self.Properties.Shielding = true;
				self.Follow();
				self.PlayAnimation("ShieldCharge",2);
				self.Logic:Action("ChargeShield");
				break;
			end
		end
		
		if not self.Properties.Shielding then
			local targetHumanoid = self.Enemy and self.Enemy.Humanoid or nil;
			local targetRootPart = self.Enemy and self.Enemy.RootPart;
			if self.Enemy ~= nil and targetRootPart ~= nil and targetHumanoid.Health > 0 then
				self.Follow(targetRootPart, 1);
				
				local targetPlayer = game.Players:GetPlayerFromCharacter(self.Enemy.Character);
				if targetPlayer then
					self.Logic:Action("Stun", targetPlayer);
					self.Enemy.Distance = targetPlayer:DistanceFromCharacter(self.RootPart.Position);
					if self.Enemy.Distance < self.Properties.AttackRange then
						self.Logic:Action("Attack", targetHumanoid, targetRootPart.CFrame.p);
					end
				end
			else
				self.Follow();
			end
		end
		
		self.NextTarget();
		self.Logic:Wait(1);
		return true;
	end
	
	--== Connections;
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	
return self end
