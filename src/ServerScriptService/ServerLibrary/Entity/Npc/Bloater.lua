local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local TweenService = game:GetService("TweenService");

local ZombieModule = script.Parent.Zombie;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

local dripEmitter = script:WaitForChild("SporeDripEmitter");
-- Note; Function called for each zombie before zombie parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Prefab = npc;
		SpawnPoint = spawnPoint;

		AggressLevel = 0;
		
		Properties = {
			BasicEnemy=true;
			WalkSpeed={Min=15; Max=15};
			AttackSpeed=2;
			AttackDamage=5;
			AttackRange=7;
			TargetableDistance=100;
		};
		
		Configuration = {
			Level=1;
			MoneyReward={Min=4; Max=8};
			ExperiencePool=35;
			ResourceDrop=modRewardsLibrary:Find("bloater");
		};
	};
	
	--== Initialize;
	function self.Initialize()
		local level = math.max(self.Configuration.Level-1, 0);

		self.Move.SetDefaultWalkSpeed = 10;
		self.Move:Init();
		
		self.Humanoid.MaxHealth = math.max(50 + 100*level);
		self.Humanoid.Health = self.Humanoid.MaxHealth;
		
		self.Properties.AttackDamage = 30 + 2*level;
		
		self.RandomClothing(self.Name, false);
		
		local sporesModel = self.Prefab:WaitForChild("Spores");
		local sporesParts = sporesModel:GetChildren();
		
		local function shuffleArray(array)
			if array == nil then return end;
			local n=#array
			for i=1,n-1 do
				local l= random:NextInteger(i,n)
				array[i],array[l]=array[l],array[i]
			end
		end
		shuffleArray(sporesParts);
		for a=1, #sporesParts do
			if a > 10 then
				game.Debris:AddItem(sporesParts[a], 0);
				
			else
				local sporePart = sporesParts[a];
				sporePart.Transparency = 0;
				
				if math.random(1, 3) == 1 then
					local newDrip = dripEmitter:Clone();
					newDrip.Rate = math.random(3, 8);
					newDrip.Speed = NumberRange.new(3, 6);
					newDrip.Parent = sporePart.SporeEmitter;
				end
			end
		end
		
		self.Think:Fire();
		coroutine.yield();
	end
	
	--== Components;
	self:AddComponent("AntiSit");
	self:AddComponent("WeakPoint");
	self:AddComponent("DropReward");
	self:AddComponent("RandomClothing");
	self:AddComponent("IsInVision");
	self:AddComponent(ZombieModule.OnDeath);
	self:AddComponent(ZombieModule.OnHealthChanged);
	self:AddComponent(ZombieModule.OnDamaged);
	self:AddComponent(ZombieModule.OnTarget);
	self:AddComponent(ZombieModule.HeavyAttack1);
	self:AddComponent(ZombieModule.DizzyCloud);
	
	--== NPC Logic;
	self.Garbage:Tag(self.Think:Connect(function()
		self.BehaviorTree:RunTree("BloaterTree", true);
		self.Humanoid:SetAttribute("AggressLevel", self.AggressLevel);
	end));
	
	--== Connections;
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	self.Garbage:Tag(self.Humanoid.Died:Connect(function(...)
		game.Debris:AddItem(self.Prefab:FindFirstChild("Spores"), 0);
		self.OnDeath(...);
		self.DizzyCloud(math.clamp(self.Configuration.Level, 10, 30));
	end));
	
return self end
