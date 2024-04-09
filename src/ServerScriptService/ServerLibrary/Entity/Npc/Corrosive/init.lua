local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local TweenService = game:GetService("TweenService");
local PhysicsService = game:GetService("PhysicsService");

local ZombieModule = script.Parent.Zombie;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modGarbageHandler = require(game.ReplicatedStorage.Library.GarbageHandler);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);

local corrosiveScript = script:WaitForChild("Damager");
local corrosiveSmoke = script:WaitForChild("Smoke");
-- Note; Function called for each zombie before zombie parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Name = npc.Name;
		Prefab = npc;
		SpawnPoint = spawnPoint;
		Humanoid = npc:FindFirstChildWhichIsA("Humanoid");
		RootPart = npc.PrimaryPart;
		PathAgent = {AgentRadius=2; AgentHeight=6;};
		
		Properties = {
			WalkSpeed = {Min=8; Max=12};
			AttackSpeed = 2;
			AttackDamage = 10;
			AttackRange = 6;
		};
		
		Configuration = {
			Level=1;
			MoneyReward={Min=25; Max=30};
			ExperiencePool=70;
		};
	};
	
	--== Initialize;
	function self.Initialize()
		local level = self.Configuration.Level-1;

		if self.HardMode then
			self.Humanoid.MaxHealth = math.max(500000 + 10000*level, 100);

		else
			self.Humanoid.MaxHealth = math.max(16000 + 3000*level, 100);

		end
		self.Humanoid.Health = self.Humanoid.MaxHealth;
		
		--self.Humanoid.MaxHealth = 8000 + 6000*(self.Configuration.Level-1);
		--self.Humanoid.Health = self.Humanoid.MaxHealth;
		
		self.Properties.AttackCooldown = tick();

		self.GooCache = modGarbageHandler.new();
		self.LevelVisuals();
		
		repeat until not self.Update();
	end
	
	--== Components;
	self:AddComponent("Follow");
	self:AddComponent("Logic");
	self:AddComponent("DropReward");
	self:AddComponent("CrateReward");
	self:AddComponent(ZombieModule.OnDeath);
	self:AddComponent(ZombieModule.OnHealthChanged);
	self:AddComponent(ZombieModule.OnDamaged);
	self:AddComponent(ZombieModule.OnTarget);
	self:AddComponent(ZombieModule.BasicAttack1);
	self:AddComponent(ZombieModule.LevelVisuals);
	
	--== NPC Logic;
	self.Logic:AddAction("Attack", function(enemiod, position)
		if self.Properties.AttackCooldown == nil then self.Properties.AttackCooldown = tick(); end;
		if tick()-self.Properties.AttackCooldown > self.Properties.AttackSpeed then
			self.Properties.AttackCooldown = tick();
			self.BasicAttack1(enemiod);
			
			local player = game.Players:FindFirstChild(enemiod.Parent.Name);
			if player then
				modStatusEffects.Slowness(player, 10, 2);
			end
		end
	end);
	self.Logic:AddAction("AcidPool", function()
		spawn(function()
			local stomach = npc:FindFirstChild("Corrosive_Stomach");
			if stomach then
				local ray = Ray.new(stomach.CFrame.p, Vector3.new(0, -16, 0));
				local hit, position = workspace:FindPartOnRayWithWhitelist(ray, {workspace.Environment; workspace.Terrain}, true);
				if hit then
					local dropletPart = Instance.new("Part");
					local dropletMesh = Instance.new("SpecialMesh");
					local size = random:NextNumber(5, 15);
					
					local despawnTime = (size);
					Debugger.Expire(dropletPart, despawnTime);
					
					dropletMesh.MeshType = Enum.MeshType.Sphere;
					dropletMesh.Scale = Vector3.new(1, 0.1, 1);
					dropletMesh.Parent = dropletPart;
					dropletPart.Size = Vector3.new(0.8, 10, 0.8);
					dropletPart.Material = Enum.Material.Neon;
					local colorOffset = random:NextNumber(-0.05, 0.05);
					dropletPart.Color = Color3.new(stomach.Color.R+colorOffset, stomach.Color.G+colorOffset, stomach.Color.B+colorOffset);
					dropletPart.CanCollide = false;
					dropletPart.Anchored = true;
					dropletPart.CFrame = CFrame.new(stomach.CFrame.p);
					dropletPart.Parent = workspace.Entities;
					self.GooCache:Tag(dropletPart);
					
					TweenService:Create(dropletPart, TweenInfo.new(0.2), {Position=position}):Play();
					wait(0.15);
					local newScr = corrosiveScript:Clone();
					newScr.Parent = dropletPart;
					newScr.Disabled = false;
					TweenService:Create(dropletPart, TweenInfo.new(0.1), {Size=Vector3.new(1.2, 3, 1.2)}):Play();
					wait(0.1);
					TweenService:Create(dropletPart, TweenInfo.new(2), {Size=Vector3.new(size, 3, size)}):Play();
				end
			end
		end)
	end)
	
	function self.Update()
		if self.IsDead or self.Humanoid.RootPart == nil then self.GooCache:Destruct(); return false; end;
		
		local targetHumanoid = self.Enemy and self.Enemy.Humanoid or nil;
		local targetRootPart = self.Enemy and self.Enemy.RootPart;
		if self.Enemy ~= nil and targetRootPart ~= nil and targetHumanoid.Health > 0 then
			self.Follow(targetRootPart, 1);
			local targetPlayer = game.Players:GetPlayerFromCharacter(self.Enemy.Character);
			if targetPlayer then
				self.Enemy.Distance = targetPlayer:DistanceFromCharacter(self.RootPart.Position);
				if self.Enemy.Distance < self.Properties.AttackRange then
					self.Logic:Action("Attack", targetHumanoid, targetRootPart.CFrame.p);
				end
			end
		else
			self.Follow();
		end
		self.NextTarget();
		
		self.Logic:Wait(1);
		self.Logic:Action("AcidPool");
		return true;
	end
	
	--== Connections;
	self.Garbage:Tag(self.Humanoid.StateChanged:Connect(function(old, new)
		--if self.DefaultWaistC0 == nil then
		--	self.DefaultWaistC0 = self.WaistMotor.C0;
		--end
		
		--if new == Enum.HumanoidStateType.Swimming then
		--	self.WaistMotor.C0 = CFrame.new(self.DefaultWaistC0.Position) * CFrame.fromOrientation(math.rad(-30), math.rad(180), 0);
		--else
		--	self.WaistMotor.C0 = self.DefaultWaistC0;
		--end
		
	end));
	self.Humanoid.HealthChanged:Connect(self.OnHealthChanged);
	self.Garbage:Tag(self.Humanoid.Died:Connect(self.OnDeath));
	
return self end
