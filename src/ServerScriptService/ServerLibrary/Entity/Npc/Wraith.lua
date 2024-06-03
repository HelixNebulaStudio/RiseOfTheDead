local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local CollectionService = game:GetService("CollectionService");

local ZombieModule = script.Parent.Zombie;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);

-- Note; Function called for each zombie before zombie parented to workspace;
task.spawn(function()
	local loopActive = false;
	
	CollectionService:GetInstanceAddedSignal("WraithBlackoutLights"):Connect(function(lightPart)
		
		if lightPart:GetAttribute("WraithBlackoutTick") == nil then
			lightPart.Material = Enum.Material.Plastic;

			for _, obj in pairs(lightPart:GetDescendants()) do
				if obj:IsA("Light") and obj:GetAttribute("DefaultEnabled") == true then
					obj.Enabled = false;
				end
			end
		end;

		lightPart:SetAttribute("WraithBlackoutTick", tick());
		
	end)
	
	while true do
		task.wait(1);
		
		local offLights = CollectionService:GetTagged("WraithBlackoutLights");
		if #offLights <= 0 then
			task.wait(20);
			continue;
		end

		for a=1, #offLights do
			local lightPart = offLights[a];

			if tick()-(lightPart:GetAttribute("WraithBlackoutTick") or 0) < 6 then
				continue
			end
			
			lightPart.Material = Enum.Material.Neon;

			for _, obj in pairs(lightPart:GetDescendants()) do
				if obj:IsA("Light") and obj:GetAttribute("DefaultEnabled") == true then
					obj.Enabled = true;
				end
			end
			
			task.delay(0.5, function()
				lightPart:SetAttribute("WraithBlackoutTick", nil);
				lightPart:RemoveTag("WraithBlackoutLights");
				
			end)
		end
	end
end)

return function(npc, spawnPoint)
	local self = modNpcComponent{
		Prefab = npc;
		Name = npc.Name;
		Head = npc:WaitForChild("Head");
		Humanoid = npc:WaitForChild("Zombie");
		RootPart = npc.PrimaryPart;
		SpawnPoint = spawnPoint; -- CFrame;
		PathAgent = {AgentRadius=1; AgentHeight=4;};
		
		Properties = {
			BasicEnemy=true;
			WalkSpeed={Min=12; Max=16};
			AttackSpeed=2;
			AttackDamage=10;
			AttackRange=6;
			TargetableDistance=50;
		};
		
		Configuration = {
			Level=1;
			MoneyReward={Min=2; Max=4};
			ExperiencePool=20;
			ResourceDrop=modRewardsLibrary:Find("zombie");
		};
	};
	
	--== Initialize;
	function self.Initialize()
		self.Humanoid.MaxHealth = 100 + 20*(self.Configuration.Level-1);
		self.Humanoid.Health = self.Humanoid.MaxHealth;
		self.Properties.AttackDamage = 10 + 3*(self.Configuration.Level-1);
		
		self.Properties.AttackCooldown = tick();
		
		self.Humanoid.HealthDisplayDistance = 20;
		
		self.Prefab:SetAttribute("Invisible", true);
		
		local wraithSmoke = game.ReplicatedStorage.Particles.WraithSmoke:Clone();
		wraithSmoke.Parent = self.RootPart;
		
		for _, obj in pairs(self.Prefab:GetChildren()) do
			if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
				obj.Transparency = 1;
				
			elseif obj:IsA("Shirt") then
				game.Debris:AddItem(obj, 0);

			elseif obj:IsA("Pants") then
				game.Debris:AddItem(obj, 0);
				
			end
		end
		
		local eyesPrefab = script:WaitForChild("WraithEyes"):Clone();
		eyesPrefab.Parent = self.Prefab;
		
		local faceDecal = self.Prefab:FindFirstChild("face", true);
		faceDecal.Transparency = 1;

		self.Movement:SetWalkSpeed("default", 16);
		
		if self.Configuration.Level >= 10 then
			self:AddComponent(ZombieModule.HeavyAttack1);
		end
		
		self.Think:Fire();
		
		local lastPosition = self.RootPart.Position;
		while not self.IsDead do
			if (self.RootPart.Position - lastPosition).Magnitude >= 4 then
				lastPosition = self.RootPart.Position;
				
				local overlapParam = OverlapParams.new();
				overlapParam.FilterType = Enum.RaycastFilterType.Include;
				overlapParam.FilterDescendantsInstances = CollectionService:GetTagged("LightSourcePart");

				local hitParts = workspace:GetPartBoundsInRadius(lastPosition, 64, overlapParam);
				local hitList = {};
				
				for a=1, #hitParts do
					local lightPart = hitParts[a];
					
					if lightPart:IsA("BasePart") and lightPart.Material == Enum.Material.Neon then
						lightPart:AddTag("WraithBlackoutLights");
					end
				end
				
			end
			task.wait(1);
		end
		
		game.Debris:AddItem(self.Prefab:FindFirstChild("WraithEyes"), 0);
	end
	
	--== Components;
	self:AddComponent("AntiSit");
	self:AddComponent("Movement");
	self:AddComponent("Follow");
	self:AddComponent("WeakPoint");
	self:AddComponent("DropReward");
	self:AddComponent("BehaviorTree");
	self:AddComponent(ZombieModule.OnDeath);
	self:AddComponent(ZombieModule.OnHealthChanged);
	self:AddComponent(ZombieModule.OnDamaged);
	self:AddComponent(ZombieModule.OnTarget);
	self:AddComponent(ZombieModule.BasicAttack1);
	self:AddComponent(ZombieModule.Idle);
	
	--== NPC Logic;
	self.Garbage:Tag(self.Think:Connect(function()
		self.BehaviorTree:RunTree("ZombieTree", true);
	end));
	
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	self.Humanoid.Died:Connect(self.OnDeath);
	
return self end
