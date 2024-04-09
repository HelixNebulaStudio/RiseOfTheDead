local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local PhysicsService = game:GetService("PhysicsService");

local NpcModule = script.Parent.Parent;
local BanditModule = NpcModule.Bandit;
local EnemyModule = NpcModule.Enemy;
local HumanModule = NpcModule.Human;
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
			Hostile=false;
			WalkSpeed={Min=8; Max=20};
			AttackSpeed=2;
			AttackRange={Min=16; Max=32};
			TargetableDistance=50;
		};
		
		Configuration = {
			Level=1;
			MoneyReward={Min=2; Max=4};
			ExperiencePool=40;
			Audio={Hurt=false;};
		};
	};
	
	--== Initialize;
	function self.Initialize()
		self.Humanoid.MaxHealth = 3000 + 200*(self.Configuration.Level-1);
		self.Humanoid.Health = self.Humanoid.MaxHealth;
		self.Humanoid.HealthDisplayDistance = 512;
		
		self.RandomSkin();
		
		self.Wield.Targetable.Humanoid = 1;
		
		self.RootPart:SetNetworkOwner(nil);
		task.delay(0.5, function()
			self.Seat:Sit(self.Humanoid);
			
			for _, v in next, self.Prefab:GetDescendants() do
				if v:IsA("BasePart") then
					v.CollisionGroup = "CollisionOff";
				end
			end
		end)
		
		if self.Seat.Name == "Stand1" then
			self.SetAnimation("Sitting", {script.Gunmen1});
			
		elseif self.Seat.Name == "Stand2" then
			self.SetAnimation("Sitting", {script.Gunmen2});
			
		end
		
		self.Wield.Equip("fnfal");
		pcall(function()
			self.Wield.ToolModule.Configurations.MinBaseDamage = 3;
			self.Wield.ToolModule.Properties.ReloadSpeed = (math.random(35, 55)/10);
		end);
		
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
	function self.Update()
		if not self.Seat:IsDescendantOf(workspace.Entity) then self.Humanoid.Health = 0; return false end;
		if self.IsDead or self.Humanoid.RootPart == nil then return false end;
		self.PlayAnimation("Sitting");
		
		self.NextTarget();
		if self.Enemy and self.Enemy.Humanoid and self.Enemy.Humanoid.RootPart and self.Enemy.Humanoid.Health > 0 then
			self.Wield.SetEnemyHumanoid(self.Enemy.Humanoid);
			self.Wield.PrimaryFireRequest();
		end
		
		task.wait(0.1)
		return true;
	end
	
	--== Connections;
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	
return self end
