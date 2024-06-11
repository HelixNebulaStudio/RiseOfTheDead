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
			AttackSpeed=0.5;
			AttackRange=8;
			TargetableDistance=70;

			AttackDamage=nil;
		};
		
		Configuration = {
			Level=1;
			MoneyReward={Min=4; Max=8};
			ExperiencePool=30;
			ResourceDrop=modRewardsLibrary:Find("growler");
		};
	};
	
	--== Initialize;
	function self.Initialize()
		local level = math.max(self.Configuration.Level, 0);

		self.Humanoid.MaxHealth = math.max(100 + 100*level, 200);
		self.Humanoid.Health = self.Humanoid.MaxHealth;

		self.Properties.AttackDamage = 10 + level/3;

		self.Move.SetDefaultWalkSpeed = 15+math.floor(level/10);
		self.Move:Init();
		--

		self.JointsDestroyed = {};
		self.JointsStrength = {
			RightShoulder=8;
			RightElbow=4;
			LeftShoulder=8;
			LeftElbow=4;
		};

		self.RandomClothing(self.Name);
		
		
		local driedFleshModel = self.Prefab:WaitForChild("DriedNekronFlesh");
		local fleshParts = driedFleshModel:GetChildren();
		
		modTables.Shuffle(fleshParts);
		for a=1, #fleshParts do
			if a > 3 then
				Debugger.Expire(fleshParts[a], 0);
			else
				local part = fleshParts[a];
				part.Transparency = 0;
			end
		end
		
		function self.CustomHealthbar:OnDamaged(amount, fromPlayer: Player, storageItem, bodyPart)
			if bodyPart == nil then return end;
			
			if bodyPart.Name == "Handle" and (bodyPart.Parent.Name == "LeftShield" or bodyPart.Parent.Name == "RightShield") then
				self:TakeDamage(bodyPart.Parent.Name, amount);
				return true;
			end

			return;
		end
		
		local shieldPrefix = {"Left"; "Right"};
		for a=1, #shieldPrefix do
			local prefix = shieldPrefix[a];
			local name = prefix.."Shield";
			
			local shieldAccessory = self.Prefab:FindFirstChild(name);
			
			self.CustomHealthbar:Create(name, math.max(self.Humanoid.MaxHealth*0.1, 50), shieldAccessory.Handle);
			self.CustomHealthbar:SetGuiSize(name, 1, 0.25);
			self.CustomHealthbar:SetGuiDistance(name, 32);
			self.CustomHealthbar:ToggleLabel(name, false);
		end

		self.CustomHealthbar.OnDeath:Connect(function(name, healthInfo)
			local bodyPart = healthInfo.BasePart;
			if not workspace:IsAncestorOf(bodyPart) then return end;
			
			bodyPart:BreakJoints();
			bodyPart.CanCollide = true;
			bodyPart.Parent = workspace.Debris;
			
			game.Debris:AddItem(healthInfo.BasePart, 2);
		end)
		
		
		self.Think:Fire();
		coroutine.yield();
	end
	
	--== Components;
	self:AddComponent("AntiSit");
	self:AddComponent("WeakPoint");
	self:AddComponent("DropReward");
	self:AddComponent("BehaviorTree");
	self:AddComponent("RandomClothing");
	self:AddComponent("IsInVision");
	self:AddComponent("CustomHealthbar");
	self:AddComponent(ZombieModule.OnDeath);
	self:AddComponent(ZombieModule.OnHealthChanged);
	self:AddComponent(ZombieModule.OnDamaged);
	self:AddComponent(ZombieModule.OnTarget);
	self:AddComponent(ZombieModule.BasicAttack2);
	self:AddComponent(ZombieModule.HeavyAttack1);
	
	--== Signals;
	self.Garbage:Tag(self.Think:Connect(function()
		self.BehaviorTree:RunTree("GrowlerTree", true);
		self.Humanoid:SetAttribute("AggressLevel", self.AggressLevel);
	end));
	
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	self.Humanoid.Died:Connect(function(...)
		game.Debris:AddItem(self.Prefab:FindFirstChild("DriedNekronFlesh"), 0);
		self.OnDeath(...);
	end);
	
	return self;
end
