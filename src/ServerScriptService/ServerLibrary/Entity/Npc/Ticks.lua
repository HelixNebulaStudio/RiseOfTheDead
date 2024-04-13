local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local TweenService = game:GetService("TweenService");

local ZombieModule = script.Parent.Zombie;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);

local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);

-- Note; Function called for each zombie before zombie parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Prefab = npc;
		SpawnPoint = spawnPoint;

		AggressLevel = 0;
		
		Properties = {
			BasicEnemy=true;
			WalkSpeed={Min=35; Max=35};
			AttackRange=40;
			AttackDamage=20;
			TargetableDistance=200;
		};
		
		Configuration = {
			Level=1;
			MoneyReward={Min=2; Max=4};
			ExperiencePool=15;
			ResourceDrop=modRewardsLibrary:Find("tickszombie");
		};
	};
	
	--== Initialize;
	function self.Initialize()
		local level = math.max(self.Configuration.Level-1, 0);
		
		self.Move.SetDefaultWalkSpeed = 35;
		self.Move:Init();
		
		self.Humanoid.MaxHealth = math.max(50 + 50*level);
		self.Humanoid.Health = self.Humanoid.MaxHealth;
		self.Properties.AttackDamage = 30 + (1*level);
		
		self.RandomClothing(self.Name, false);
		
		local ticksModel = self.Prefab:WaitForChild("ExplosiveTickBlobs");
		local tickBlobs = self.Prefab:WaitForChild("ExplosiveTickBlobs"):GetChildren();
		
		local function shuffleArray(array)
			if array == nil then return end;
			local n=#array
			for i=1,n-1 do
				local l= random:NextInteger(i,n)
				array[i],array[l]=array[l],array[i]
			end
		end
		shuffleArray(tickBlobs);
		for a=1, #tickBlobs do
			if a > 10 then
				game.Debris:AddItem(tickBlobs[a], 0);
				
			else
				tickBlobs[a].Transparency = 0;
				local newSize = math.random(50,350)/1000
				tickBlobs[a].Size = Vector3.new(newSize, newSize);
				
			end
		end
		
		for _, obj in pairs(self.Head:GetChildren()) do
			if obj:IsA("BasePart") and obj.Name == "Blobs" then
				obj.Parent = ticksModel;
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
	self:AddComponent(ZombieModule.OnDeath);
	self:AddComponent(ZombieModule.OnHealthChanged);
	self:AddComponent(ZombieModule.OnDamaged);
	self:AddComponent(ZombieModule.OnTarget);
	
	--== NPC Logic;
	self.Garbage:Tag(self.Think:Connect(function()
		self.BehaviorTree:RunTree("TicksTree", true);
		self.Humanoid:SetAttribute("AggressLevel", self.AggressLevel);
	end));
	
	--== Connections;
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	self.Garbage:Tag(self.Humanoid.Died:Connect(function(...)
		game.Debris:AddItem(self.Prefab:FindFirstChild("Blobs"), 0);
		self.OnDeath(...);
	end));
	
return self end
