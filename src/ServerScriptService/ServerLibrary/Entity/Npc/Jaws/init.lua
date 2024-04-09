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
		PathAgent = {AgentRadius=1; AgentHeight=4;};
		
		Immunity = 1;
		Detectable = false;
		
		Properties = {
			BasicEnemy=true;
			WalkSpeed={Min=0; Max=0};
			AttackSpeed=1;
			AttackDamage=20;
			AttackRange=15;
			TargetableDistance=64;
		};
		
		Configuration = {
			Level=1;
			MoneyReward={Min=2; Max=4};
			ExperiencePool=20;
			ResourceDrop=modRewardsLibrary:Find("zombie");
		};
		
		Audio = {
			Death = "ZombieDeath5";
			Attack = "ZombieAttack4";
		};
		
		DropRewardOffset = Vector3.new(0, 2, 0);
	};
	
	--== Initialize;
	function self.Initialize()
		self.Prefab:SetAttribute("EntityHudHealth", true);
		
		self.Humanoid.MaxHealth = 20000 + 3000*(self.Configuration.Level-1);
		self.Humanoid.Health = self.Humanoid.MaxHealth;
		
		self.Properties.AttackCooldown = tick();
		
		
		self.JawPrefabs = {
			self.Prefab:WaitForChild("LJaw");
			self.Prefab:WaitForChild("RJaw");
		}
		
		for a=1, #self.JawPrefabs do
			--self.JawPrefabs[a].Parent = nil;
			
			local key = self.JawPrefabs[a].Name:sub(1,1);
			local insidePart = self.JawPrefabs[a]:WaitForChild("Insides");
			
			self.CustomHealthbar:Create(key.."WeakSpot", 1, insidePart);
		end
		
		self.DamageWeakSpotCount = 0;
		function self.CustomHealthbar:OnDamaged(amount, fromPlayer, storageItem, bodyPart)
			if bodyPart == nil then return end;

			if bodyPart.Name == "Insides" then
				self.Npc.DamageWeakSpotCount = self.Npc.DamageWeakSpotCount + math.clamp(amount/2000, 0.3, 1);
				
				return {
					Immunity = 0;
					Amount = amount;
				};
			end
		end
		
		
		self.JawMotors = {};
		
		for _, obj in pairs(self.Head:GetChildren()) do
			if obj:IsA("Motor6D") then
				table.insert(self.JawMotors, obj);
			end
		end

		self.Head.Parent = nil;
		for a=1, #self.JawPrefabs do
			self.JawPrefabs[a].Parent = nil;
		end
		
		
		self.Think:Fire();
		coroutine.yield();
		task.spawn(function()
			self.Prefab:BreakJoints();
			self.Head.Anchored = false;
		end)
		task.wait(1);
	end
	
	--== Components;
	self:AddComponent("AntiSit");
	self:AddComponent("DropReward");
	self:AddComponent("BehaviorTree");
	self:AddComponent("CustomHealthbar");
	self:AddComponent(ZombieModule.OnDeath);
	self:AddComponent(ZombieModule.OnHealthChanged);
	self:AddComponent(ZombieModule.OnDamaged);
	self:AddComponent(ZombieModule.OnTarget);
	self:AddComponent(ZombieModule.BasicAttack1);
	
	--== NPC Logic;
	self.Garbage:Tag(self.Think:Connect(function()
		self.BehaviorTree:RunTree(script.JawsTree, true);
	end));

	self.Garbage:Tag(function()
		game.Debris:AddItem(self.Head, 0);
		for a=1, #self.JawPrefabs do
			game.Debris:AddItem(self.JawPrefabs[a], 0);
		end
	end)
	
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	self.Garbage:Tag(self.Humanoid.Died:Connect(self.OnDeath));
	
return self end
