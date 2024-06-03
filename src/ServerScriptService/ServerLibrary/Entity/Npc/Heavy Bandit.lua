local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local BanditModule = script.Parent.Bandit;
local EnemyModule = script.Parent.Enemy;
local HumanModule = script.Parent.Human;
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
		Humanoid = npc:WaitForChild("Bandit");
		RootPart = npc.PrimaryPart;
		SpawnPoint = spawnPoint; -- CFrame;
		Smart = true;
		
		Properties = {
			BasicEnemy=true;
			Hostile=true;
			WalkSpeed={Min=8; Max=20};
			AttackSpeed=2;
			--AttackDamage=200;
			AttackRange={Min=16; Max=32};
			TargetableDistance=128;
		};
		
		Configuration = {
			Level=1;
			MoneyReward={Min=2; Max=4};
			ExperiencePool=100;
			Audio={Hurt=false;};
			ResourceDrop=modRewardsLibrary:Find("bandit");
		};
	};
	
	self.Speeches = {
		"Hasta la vista, noobs";
		"Hand over the cache!";
		"Say hello to my little friend!";
	}
	
	--== Initialize;
	function self.Initialize()
		self.Humanoid.MaxHealth = 64000 + 2000*(self.Configuration.Level-1);
		self.Humanoid.Health = self.Humanoid.MaxHealth;
		
		self.Properties.AttackDamage = math.clamp(20 + 2*(self.Configuration.Level-1), 20, 40);
		
		self.RandomSkin{Type="Heavy"};
		self.Properties.AttackCooldown = tick();
		self.Properties.FeelsSafe = tick();
		self.Properties.AttractCooldown = tick();
		
		self.Properties.WeaponId = "minigun";
		
		self.Wield.Targetable.Humanoid = 0.1;
		self.Wield.Targetable.Rat = 0.1;
		
		task.delay(0.5,function()
			while self.DeploySeat do
				self.RootPart:SetNetworkOwner(nil);
				self.DeploySeat:Sit(self.Humanoid);
				task.wait(0.1);
			end
			self:AddComponent("AntiSit");
		end)

		repeat until not self.Update();
	end
	
	--== Components;
	self:AddComponent("Movement");
	self:AddComponent("Follow");
	self:AddComponent("Logic");
	self:AddComponent("IsInVision");
	self:AddComponent("DropReward");
	self:AddComponent("Wield");
	
	self:AddComponent(HumanModule.AttractZombies);
	self:AddComponent(HumanModule.Chat);
	self:AddComponent(HumanModule.Chatter);
	
	self:AddComponent(EnemyModule.OnHealthChanged);
	self:AddComponent(EnemyModule.OnDeath);
	self:AddComponent(EnemyModule.OnDamaged);
	self:AddComponent(BanditModule.OnTarget);
	
	self:AddComponent(BanditModule.RandomSkin);
	self:AddComponent(BanditModule.Idle);
	
	--== NPC Logic;
	self.Logic:AddAction("Idle", self.Idle.Begin, self.Idle.Cancel);
	
	function self.Update()
		if self.IsDead or self.Humanoid.RootPart == nil then return false end;
		if self.Disabled then wait(0.1) return true end;
		
		local followGap = random:NextNumber(self.Properties.AttackRange.Min, self.Properties.AttackRange.Max);
		
		if self.Enemy and self.Enemy.Humanoid and self.Enemy.Humanoid.Health > 0 then
			self.Logic:SetState("Aggro");
			
			self.Humanoid.WalkSpeed = random:NextInteger(self.Properties.WalkSpeed.Max, self.Properties.WalkSpeed.Max+5);
			self.Follow(self.Enemy.Humanoid.RootPart, followGap, 10);
			
			if self.Enemy.Distance <= (self.Properties.TargetableDistance or 50) then
				if self.Wield.ToolModule == nil then
					self.Wield.Equip(self.Properties.WeaponId);
					pcall(function()
						self.Wield.ToolModule.Configurations.MinBaseDamage = self.Properties.AttackDamage;
					end);
				end
				
				repeat
					local follow = true;
					if self.Enemy and self.Enemy.Humanoid and self.Enemy.Humanoid.RootPart and self.Enemy.Humanoid.Health > 0 then
						self.NextTarget();
						
						local targetIsInVision = self.Enemy and self.IsInVision(self.Enemy.Humanoid.RootPart);
						if self.Wield.ToolModule and not self.Wield.ToolModule.Properties.Reloading and targetIsInVision then
							if self.Enemy.NpcModule and self.Enemy.NpcModule.UpdateDropReward then self.Enemy.NpcModule:UpdateDropReward(); end
							self.Wield.SetEnemyHumanoid(self.Enemy.Humanoid);
							self.Movement:Face(self.Enemy.Humanoid.RootPart.Position);
							
							self.LostVisionOfTargetTick = nil;
							self.Wield.PrimaryFireRequest();
							
							if self.Enemy.Distance > 12 then
								self.Follow();
								follow = false;
							end
							
						else
							if self.LostVisionOfTargetTick == nil then
								self.LostVisionOfTargetTick = tick();
							end
							
							if self.Wield.ToolModule and tick()-self.LostVisionOfTargetTick >= math.random(20,30)/10 then
								self.Wield.Controls.Mouse1Down = false;
							end
							
						end
					else
						self.Enemy = nil;
					end
					
					if follow and self.Enemy then self.Follow(self.Enemy.Humanoid.RootPart, followGap, 10); end
					self.Logic:Timeout("Aggro", 0.1);
				until self.IsDead or self.Enemy == nil or self.Enemy.Distance >= (self.Properties.TargetableDistance or 50);
				self.Properties.FeelsSafe = tick();
			else
				if self.Wield.ToolModule then
					self.Wield.ReloadRequest();
				end
			end
			
			self.Logic:Timeout("Aggro", 1);
			
		else
			self.Logic:SetState("Idle");
			
			if tick()-self.Properties.FeelsSafe >= 30 then
				self.Wield.Unequip();
			end
			self.Humanoid.WalkSpeed = random:NextInteger(self.Properties.WalkSpeed.Min, self.Properties.WalkSpeed.Min+5);
			self.Follow();
			self.Logic:Action("Idle");
			
		end

		self.Logic:Timeout("Idle", 10);
		return true;
	end
	
	--== Connections;
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	self.Humanoid.Died:Connect(self.OnDeath);
	
return self end
