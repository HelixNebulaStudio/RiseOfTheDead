local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local ZombieModule = script.Parent.Zombie;

local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
local modTables = require(game.ReplicatedStorage.Library.Util.Tables);

local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);
--==

return function(npc, spawnPoint)
	--== Configurations;
	local self = modNpcComponent{
		Prefab = npc;
		SpawnPoint = spawnPoint;

		AggressLevel = 0;
		
		Properties = {
			BasicEnemy=true;
			AttackRange=40;
			TargetableDistance=200;

			AttackDamage=nil;
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
		local level = math.max(self.Configuration.Level, 0);
		
		self.Humanoid.MaxHealth = math.max(50*level, 50);
		self.Humanoid.Health = self.Humanoid.MaxHealth;

		self.Properties.AttackDamage = 35 + (1*level);
		
		self.Move.SetDefaultWalkSpeed = 35;
		self.Move:Init();
		--
		
		self.RandomClothing(self.Name, false);

		local ticksModel = self.Prefab:WaitForChild("ExplosiveTickBlobs");
		local tickBlobs = ticksModel:GetChildren();
		
		modTables.Shuffle(tickBlobs);
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
	
	--== Signals;
	self.Garbage:Tag(self.Think:Connect(function()
		self.BehaviorTree:RunTree("TicksTree", true);
		self.Humanoid:SetAttribute("AggressLevel", self.AggressLevel);
	end));
	
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	self.Garbage:Tag(self.Humanoid.Died:Connect(function(...)
		game.Debris:AddItem(self.Prefab:FindFirstChild("Blobs"), 0);
		self.OnDeath(...);
	end));
	
	
	return self;
end
