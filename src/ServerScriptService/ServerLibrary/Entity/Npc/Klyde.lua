local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local RunService = game:GetService("RunService");

local BanditModule = script.Parent.Bandit;
local EnemyModule = script.Parent.Enemy;
local HumanModule = script.Parent.Human;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);

-- Note; Function called for each zombie before zombie parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Prefab = npc;
		Name = npc.Name;
		Head = npc:WaitForChild("Head");
		Humanoid = npc:WaitForChild("Bandit");
		RootPart = npc.PrimaryPart;
		SpawnPoint = spawnPoint; -- CFrame;
		Smart = true;
		
		Properties = {
			WalkSpeed={Min=6; Max=12};
			AttackSpeed=2;
			AttackDamage=10;
			AttackRange={Min=16; Max=32};
			TargetableDistance=256;
		};
		
		Configuration = {
			Level=1;
			MoneyReward={Min=45; Max=60};
			ExperiencePool=40;
			Audio={Hurt=false;};
		};
	};
	
	self.Speeches = {
		"Come out, come out, whereeever you are!";
		"Come ooon, you think you can out run bullets?";
		"Ooooooh Yeeeeah!!";
		"Bring it on kiddos!";
		"Woooooo! There's plenty more where that came from!";
		"Daance! Monkey, dance!";
		"Dance! Hahahaha! Dance!";
		"The more you moove, the more fun it gets!";
		"Praise BioX for this amazing catastrophe!";
	}
	
	--== Initialize;
	function self.Initialize()
		self.Humanoid.Health = self.Humanoid.MaxHealth;
		self.Configuration.ExperiencePool = 35;
		
		self.Properties.AttackCooldown = tick();

		if self.HardMode then
			self.Humanoid.MaxHealth = 75000 + ((#self.NetworkOwners-1) * 33000);
			self.Humanoid.Health = self.Humanoid.MaxHealth;
			self.KnockbackResistant = true;
			self.Properties.AttackDamage = 20;
		end
		
		self.Wield.Equip("ak47");
		pcall(function()
			self.Wield.ToolModule.Configurations.MinBaseDamage = self.Properties.AttackDamage;
		end);
		
		if self.HardMode then
			self.Wield.OnWieldHit = function(targetModel)
				local player = game.Players:GetPlayerFromCharacter(targetModel);
				if player then
					modStatusEffects.Burn(player, 50, 7);
				end
			end
		end
				
		--== Chatter;
		spawn(function()
			repeat
				if self.Speeches == nil then return end;
				local players = {};
				for a=1, #self.Enemies do
					local character = self.Enemies[a].Character;
					table.insert(players, game.Players:FindFirstChild(character.Name));
				end
				self.Chat(players, self.Speeches[random:NextInteger(1, #self.Speeches)]);
			until self.IsDead or self.Humanoid.RootPart == nil or not wait(random:NextNumber(32, 64));
		end)
				
		self.Wield.Targetable.Humanoid = 1;
		self.Wield.Targetable.Destructible = 500;
		
		repeat until not self.Update();
		
		wait(5);
	end
	
	--== Components;
	self:AddComponent("Movement");
	self:AddComponent("Follow");
	self:AddComponent("Logic");
	self:AddComponent("IsInVision");
	self:AddComponent("CrateReward");
	self:AddComponent("Wield");
	self:AddComponent(HumanModule.Chat);
	self:AddComponent(EnemyModule.OnHealthChanged);
	self:AddComponent(EnemyModule.OnDamaged);
	self:AddComponent(EnemyModule.OnDeath);
	self:AddComponent(BanditModule.OnTarget);
	self:AddComponent(BanditModule.Idle);
	
	--== NPC Logic;
	self.Logic:AddAction("Idle", self.Idle.Begin, self.Idle.Cancel);
	
	function self.Update()
		if self.IsDead or self.Humanoid.RootPart == nil then return false end;
		local followGap = random:NextNumber(self.Properties.AttackRange.Min, self.Properties.AttackRange.Max);
		
		if self.Enemy and self.Enemy.Humanoid and self.Enemy.Humanoid.Health > 0 then
			self.Logic:SetState("Aggro");
			
			self.Movement:SetWalkSpeed("default", 32);
			self.Follow(self.Enemy.Humanoid.RootPart, followGap, 10);
			
			self.Enemy.Distance = (self.Humanoid.RootPart.CFrame.p - self.Enemy.Humanoid.RootPart.CFrame.p).Magnitude;
			if self.Enemy.Distance <= 50 then
				repeat
					local follow = true;
					if not self.IsDead and self.Enemy and self.Enemy.Humanoid and self.Enemy.Humanoid.RootPart and self.Enemy.Humanoid.Health > 0 then
						
						self.Enemy.Distance = (self.RootPart.CFrame.p - self.Enemy.Humanoid.RootPart.CFrame.p).Magnitude;
						if self.Wield.ToolModule and not self.Wield.ToolModule.Properties.Reloading 
						and self.IsInVision(self.Enemy.Humanoid.RootPart) then
							
							self.Wield.SetEnemyHumanoid(self.Enemy.Humanoid);
							self.Movement:Face(self.Enemy.Humanoid.RootPart.Position);
							self.Wield.PrimaryFireRequest();
							
							if self.Enemy.Distance > 12 then
								self.Follow();
								follow = false;
							end
						end
					else
						self.Enemy = nil;
					end
					if follow and self.Enemy then self.Follow(self.Enemy.Humanoid.RootPart, followGap, 10); end
					self.Logic:Timeout("Aggro", 0.1);
				until self.IsDead or self.Enemy == nil or self.Enemy.Distance >= 50;
				if self.Enemy == nil then
					self.NextTarget();
				end
			else
				if self.Wield.ToolModule then
					self.Wield.ReloadRequest();
				end
			end
			
			self.Logic:Timeout("Aggro", 1);
			
		else
			self.Logic:SetState("Idle");
			
			self.NextTarget();
			self.Movement:SetWalkSpeed("default", 16);
			self.Follow();
			self.Logic:Action("Idle");
			
		end

		self.Logic:Timeout("Idle", 10);
		return true;
	end
	
	--== Connections;
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	
return self end
