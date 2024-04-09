local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local CultistModule = script;
local BanditModule = script.Parent.Bandit;
local EnemyModule = script.Parent.Enemy;
local HumanModule = script.Parent.Human;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

-- Note; Function called for each zombie before zombie parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Prefab = npc;
		Name = npc.Name;
		Head = npc:WaitForChild("Head");
		Humanoid = npc:WaitForChild("Cultist");
		RootPart = npc.PrimaryPart;
		SpawnPoint = spawnPoint; -- CFrame;
		Smart = true;
		
		Properties = {
			WalkSpeed={Min=8; Max=20};
			AttackSpeed=1;
			AttackDamage=20;
			AttackRange=6;
			TargetableDistance=256;
		};
		
		Configuration = {
			Level=1;
			MoneyReward={Min=2; Max=4};
			ExperiencePool=40;
			Audio={Hurt=false;};
			ResourceDrop=modRewardsLibrary:Find("bandit");
		};
	};
	
	self.Speeches = {};
	
	--== Initialize;
	function self.Initialize()
		self.Humanoid.MaxHealth = 400 + 200*(self.Configuration.Level-1);
		self.Humanoid.Health = self.Humanoid.MaxHealth;
		
		--if self.Properties.AttackDamage == nil then
		--	self.Properties.AttackDamage = math.clamp(200 + 50*(self.Configuration.Level-1), 200, 600);
		--end
		
		self.RandomSkin();
		self.Properties.AttackCooldown = tick();
		self.Wield.Equip("survivalknife");
		pcall(function()
			self.Wield.ToolModule.Configurations.Damage = 15;
			self.Wield.ToolModule.Configurations.PrimaryAttackAnimationSpeed = 0.2;
		end);
		
		self.Wield.Targetable.Humanoid = 1;
		repeat until not self.Update();
	end
	
	function self.CantFollow(destination)
		Debugger:Log("CantFollow");
		if self.CutsceneMode then return end;
		self.Prefab:Destroy();
		--if self.Teleporting then return end;
		--self.Teleporting = true;
		--wait(1);
		--if self and self.Enemy and self.Enemy.Character then
		--	local player = game.Players:GetPlayerFromCharacter(self.Enemy.Character);
		--	if player then
		--		local profile = modProfile:Get(player);
		--		if profile and profile.LastDoorCFrame then
		--			self.RootPart.CFrame = profile.LastDoorCFrame;
		--		end
		--	end
		--end
		
		--self.RootPart.Position = destination+Vector3.new(0, 2, 0);
		--self.Teleporting = false;
	end
	
	--== Components;
	self:AddComponent("AntiSit");
	self:AddComponent("Movement");
	self:AddComponent("Follow");
	self:AddComponent("Logic");
	self:AddComponent("IsInVision");
	self:AddComponent("DropReward");
	self:AddComponent("Wield");
	
	self:AddComponent(HumanModule.Chat);
	self:AddComponent(HumanModule.Chatter);
	
	self:AddComponent(EnemyModule.OnHealthChanged);
	self:AddComponent(EnemyModule.OnDeath);
	self:AddComponent(EnemyModule.OnDamaged);
	
	self:AddComponent(BanditModule.OnTarget);
	self:AddComponent(BanditModule.Idle);
	
	self:AddComponent(CultistModule.RandomSkin);
	
	--== NPC Logic;
	function self.Update()
		if self == nil then return false end;
		if self.IsDead or self.Humanoid.RootPart == nil then return false end;
		
		if self.CutsceneMode then
			wait(0.1);
		else
			if self.Enemy and self.Enemy.Humanoid and self.Enemy.Humanoid.Health > 0 and self.Enemy.Humanoid.RootPart then
				local enemyRootPart = self.Enemy.Humanoid.RootPart;
				self.Logic:SetState("Aggro");

				self.Humanoid.WalkSpeed = random:NextInteger(self.Properties.WalkSpeed.Max, self.Properties.WalkSpeed.Max+5);
				self.Follow(enemyRootPart, 0.5);

				self.Enemy.Distance = (self.RootPart.CFrame.p - enemyRootPart.CFrame.p).Magnitude;
				repeat
					if self then
						if self.Enemy and self.Enemy.Humanoid and enemyRootPart and self.Enemy.Humanoid.Health > 0 then
							if self.Enemy.Distance <= self.Properties.AttackRange then
								self.Wield.SetEnemyHumanoid(self.Enemy.Humanoid);
								self.Movement:LookAt(enemyRootPart.Position);
								self.Movement:Face(enemyRootPart.Position);
								self.Wield.PrimaryFireRequest();
							end
						else
							self.Enemy = nil;
						end
						if self.Humanoid and self.Humanoid.RootPart and self.Enemy and self.Enemy.Humanoid then
							self.Follow(enemyRootPart, 0.5);
							self.Movement:LookAt(enemyRootPart.Position);
							self.Enemy.Distance = (self.Humanoid.RootPart.CFrame.p - enemyRootPart.CFrame.p).Magnitude;
						else
							if self.Prefab then self.Prefab:Destroy() end;	
						end
					else
						break;
					end
					self.Logic:Timeout("Aggro", 0.1);

				until self.IsDead or self.Enemy == nil or self.Enemy.Distance >= 50;

				if self.Enemy == nil then
					self.NextTarget();
				end
				self.Logic:Timeout("Aggro", 1);

			else
				self.Logic:SetState("Idle");

				self.NextTarget();
				self.Humanoid.WalkSpeed = random:NextInteger(self.Properties.WalkSpeed.Min, self.Properties.WalkSpeed.Min+5);
				self.Follow();

			end
		end

		self.Logic:Timeout("Idle", 10);
		return true;
	end
	
	--== Connections;
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	self.Garbage:Tag(self.Humanoid.Died:Connect(self.OnDeath));
	
return self end
