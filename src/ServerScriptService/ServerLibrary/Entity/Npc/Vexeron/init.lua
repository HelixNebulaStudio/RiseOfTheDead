local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local remotes = game.ReplicatedStorage.Remotes;
local remoteCameraShakeAndZoom = remotes.CameraShakeAndZoom;

local ZombieModule = script.Parent.Zombie;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modExperience = require(game.ServerScriptService.ServerLibrary.Experience);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);

-- Note; Function called for each zombie before zombie parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Name = npc.Name;
		Prefab = npc;
		SpawnPoint = spawnPoint;
		Humanoid = npc:FindFirstChildWhichIsA("Humanoid");
		RootPart = npc.PrimaryPart;
		PathAgent = {AgentRadius=20; AgentHeight=11;};
		
		Properties = {
			WalkSpeed = {Min=16; Max=18};
			AttackSpeed = 4;
			AttackDamage = 30;
			AttackRange = 20;
			SpeedRatio = 1;
		};
		
		Configuration = {
			Level=1;
			MoneyReward={Min=2000; Max=3500};
			ExperiencePool=1000;
			VexeronLength = 8;
		};
		
		KnockbackResistant = true;
		DespawnPrefab = 30;
	};
	
	--== Initialize;
	self:SetClientScript(script:WaitForChild("VexeronEffect"));
	
	function self.Initialize()
		self.BodyMovers = {};
		self.BodyMovers.BodyVelocity = Instance.new("BodyVelocity");
		self.BodyMovers.BodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge);
		self.BodyMovers.BodyVelocity.Velocity = Vector3.new(0, 0, 0);
		self.BodyMovers.BodyVelocity.P = 50;
		self.BodyMovers.BodyVelocity.Parent = self.RootPart;
		
		self.BodyMovers.BodyGyro = Instance.new("BodyGyro");
		self.BodyMovers.BodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge);
		self.BodyMovers.BodyGyro.P = 40000;
		self.BodyMovers.BodyGyro.Parent = self.RootPart;
		
		self.Humanoid.PlatformStand = true;
		self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true);
		self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true);
		
		local twistAngleLimit = 65;
		
		self.VexBody = self.Prefab:WaitForChild("VexeronBody");
		
		if self.HardMode then
			self.Configuration.VexeronLength = 16;
			
			self.Humanoid.MaxHealth = 2300400;
			self.Humanoid.Health = self.Humanoid.MaxHealth;
			
			self.Properties.AttackDamage = 50;
		else
			
			self.VexBody.Material = Enum.Material.Sand;
			self.VexBody.Color = Color3.fromRGB(121, 86, 75);
		end
		-- CustomHealthbar
		self.BodyWeights = {};
		
		local prevLowerLink = self.VexBody:WaitForChild("LowerLink");
		for a=1, self.Configuration.VexeronLength do
			local new = self.VexBody:Clone();
			new.Name = new.Name..a;
			
			if self.HardMode then
				new.Size = self.VexBody.Size * 1.6;
				local nULink = new:WaitForChild("UpperLink");
				local nLLink = new:WaitForChild("LowerLink");
				nULink.Position = Vector3.new(0, 8, 0);
				nLLink.Position = Vector3.new(0, -8, 0);
			else
				new.Size = self.VexBody.Size * 1.1;
				local nULink = new:WaitForChild("UpperLink");
				local nLLink = new:WaitForChild("LowerLink");
				nULink.Position = Vector3.new(0, 5, 0);
				nLLink.Position = Vector3.new(0, -5, 0);
			end
			
			local constraint = Instance.new("BallSocketConstraint");
			constraint.Attachment0 = new:WaitForChild("UpperLink");
			constraint.Attachment1 = prevLowerLink;
			constraint.LimitsEnabled = true;
			constraint.TwistLimitsEnabled = true;
			constraint.UpperAngle = twistAngleLimit;
			constraint.TwistLowerAngle = -twistAngleLimit;
			constraint.TwistUpperAngle = twistAngleLimit;
			constraint.Parent = new;
			prevLowerLink = new:WaitForChild("LowerLink");
			
			local bodyVelocity = Instance.new("BodyVelocity");
			bodyVelocity.Name = "Weight";
			local force = 1000000;
			bodyVelocity.MaxForce = Vector3.new(force, force, force);
			bodyVelocity.Velocity = Vector3.new(0, 0, 0);
			bodyVelocity.P = 1500;
			bodyVelocity.Parent = new;
			
			table.insert(self.BodyWeights, bodyVelocity);
			
			new.Parent = self.Prefab;
		end
		
		local bodyParts = self.Prefab:GetChildren();
		for a=1, #bodyParts do
			if bodyParts[a]:IsA("BasePart") then
				bodyParts[a]:SetNetworkOwner(nil);
				if bodyParts[a].Name:match("VexeronBody") then
					if self.HardMode then
						self.CustomHealthbar:Create(bodyParts[a].Name, 50000, bodyParts[a]);
					else
						self.CustomHealthbar:Create(bodyParts[a].Name, 25000, bodyParts[a]);
					end
				end
			end
		end
		
		function self.CustomHealthbar:OnDamaged(amount, fromPlayer, storageItem, bodyPart)
			if self.IsDead or bodyPart == nil then return end;
			local healthInfo = self.Healths[bodyPart.Name];
			if healthInfo then
				if healthInfo.Health > 0 then
					self:TakeDamage(bodyPart.Name, amount);
					
				else
					return true;
					
				end
			end
		end
		
		self.CustomHealthbar.OnDeath:Connect(function(name, healthInfo)
			local bodyPart = self.Prefab:FindFirstChild(name);
			if bodyPart == nil then return end;
			
			bodyPart.Color = Color3.fromRGB(50, 50, 50);
			self.Properties.AttackDamage = math.clamp(self.Properties.AttackDamage-3, 15, 30);
			self.Properties.SpeedRatio = math.clamp(self.Properties.SpeedRatio-0.05, 0.5, 1);
			if RunService:IsStudio() then 
				--Debugger:Warn("[Studio] Set speed 0 for testing")
				--self.Properties.SpeedRatio = 0;
				Debugger:Warn("[Studio] SpeedRatio=", self.Properties.SpeedRatio);
			end
			
			self.BodyMovers.BodyVelocity.P = self.BodyMovers.BodyVelocity.P*self.Properties.SpeedRatio;
			
			
			self.Status:TakeDamagePackage(modDamagable.NewDamageSource{
				Damage=(self.HardMode and 100000 or 7500);
				TargetPart=self.RootPart;
			});
			
			local netOwners = self.NetworkOwners or {};
			for a=1, #netOwners do
				local player = netOwners[a];
				remoteCameraShakeAndZoom:FireClient(player, 30, 0, 2, 2, true);
			end

			modAudio.Play("TicksZombieExplode", bodyPart.Position).PlaybackSpeed = math.random(30,40)/100;
			modAudio.Play("VexeronPain", bodyPart.Position).PlaybackSpeed = math.random(90,110)/100;
			
		end)
		-- CustomHealthbar
		
		self.Humanoid.WalkSpeed = self.Properties.WalkSpeed.Max;
		self.LevelVisuals();

		local VexeronRemote = Instance.new("RemoteEvent");
		VexeronRemote.Name = "VexeronRemote";
		VexeronRemote.Parent = self.Prefab;

		self.Garbage:Tag(VexeronRemote.OnServerEvent:Connect(function(player, hitPart)
			if player.Character == nil then return end;
			if not hitPart:IsDescendantOf(self.Prefab) then return end;

			local isEnemy = false;
			for a=1, #self.Enemies do
				if self.Enemies[a] and self.Enemies[a].Character == player.Character then
					isEnemy = true;
					break;
				end
			end
			if not isEnemy then return end;

			self:DamageTarget(player.Character, self.Properties.AttackDamage);
			if self.HardMode then
				modStatusEffects.Knockback(player, hitPart, 50);
			end
		end))
		
		self.UpdateVelocity = function()
			self.BodyMovers.BodyVelocity.Velocity = self.BodyMovers.BodyGyro.CFrame.UpVector * self.BodyMovers.BodyVelocity.P;
			if self.BodyWeights == nil then return end;
			for a=1, #self.BodyWeights do
				if self.BodyWeights[a].Parent then
				self.BodyWeights[a].Velocity = self.BodyWeights[a].Parent.CFrame.UpVector * self.BodyMovers.BodyVelocity.P;
				end
			end
		end
		
		self.Garbage:Tag(self.BodyMovers.BodyVelocity:GetPropertyChangedSignal("P"):Connect(self.UpdateVelocity));
		self.Garbage:Tag(self.BodyMovers.BodyGyro:GetPropertyChangedSignal("CFrame"):Connect(self.UpdateVelocity));
		
		local PhysicsService = game:GetService("PhysicsService");
		for _, v in next, self.Prefab:GetDescendants() do
			if v:IsA("BasePart") then
				v.CollisionGroup = "CollisionOff";
			end
		end
		
		repeat until self.Update == nil or not self.Update();
		modAudio.Play("VexeronGrowl", self.Head.Position);
		
		self.BodyWeights = nil;
		task.wait(5);
	end
	
	--== Components;
	self:AddComponent("AntiSit");
	self:AddComponent("CustomHealthbar");
	self:AddComponent("CrateReward");
	self:AddComponent(ZombieModule.OnDeath);
	self:AddComponent(ZombieModule.OnHealthChanged);
	self:AddComponent(ZombieModule.OnDamaged);
	self:AddComponent(ZombieModule.OnTarget);
	self:AddComponent(ZombieModule.LevelVisuals);
	
	self.PointTo = function(point, lerpIntensity)
		local newFrontCf = CFrame.new(self.RootPart.Position, point) * CFrame.Angles(-math.pi/2, 0, 0);
		
		self.BodyMovers.BodyGyro.CFrame = self.BodyMovers.BodyGyro.CFrame:Lerp(newFrontCf, math.clamp(lerpIntensity or (self.IsHard and 0.04 or 0.01), 0.01, 1));
	end
	
	self.MoveToPoint = function(point)
		local dist = 20;
		repeat
			dist = (self.RootPart.Position-point).Magnitude;
			self.PointTo(point, dist);
			task.wait();
		until self.IsDead or dist < 25;
	end
	
	local swimPointsA = {
		Vector3.new(-90.9, -14, 464.3);
		Vector3.new(-107.789, -14, 488.187);
		Vector3.new(-180.739, -14, 488.187);
		Vector3.new(-207.939, -14, 458.237);
		Vector3.new(-207.939, -14, 413.387);
		Vector3.new(-159.589, -14, 413.387);
		Vector3.new(-148.189, -14, 379.437);
		Vector3.new(-107.589, -14, 405.937);
		Vector3.new(-67.989, -14, 393.337);
		Vector3.new(-67.989, -14, 425.487);
		Vector3.new(-91.289, -14, 449.837);
	};
	
	local swimPointsB = {
		Vector3.new(-66.739, -14, 480.237);
		Vector3.new(-197.789, -14, 446.837);
		Vector3.new(-69.639, -14, 423.187);
		Vector3.new(-196.939, -14, 392.037);
	}
	
	local hasAttacked = false;
	
	local attackCooldown = tick();
	local isAttacking = false;
	function self.Update()
		if self.IsDead or self.Humanoid.RootPart == nil then return false; end;
		
		local targetHumanoid = self.Enemy and self.Enemy.Humanoid or nil;
		local targetRootPart = self.Enemy and self.Enemy.RootPart;
		if targetRootPart and targetHumanoid and targetHumanoid.Health > 0 then
			self.BodyMovers.BodyVelocity.P = (self.IsHard and 90 or 50)*self.Properties.SpeedRatio;
			
			local targetPoint = targetRootPart.Position;
			
			local attackTimer = (self.IsHard and 8 or 12);
			if tick()-attackCooldown >= attackTimer then
				self.PointTo(targetPoint, 0.1);
				
				if tick()-attackCooldown >= (attackTimer+6) then
					attackCooldown = tick();
				end
			else
				local dist = (targetPoint-self.RootPart.Position).Magnitude;
				if dist > 400 then
					self.PointTo(targetPoint, 1);
					
				elseif dist > 200 then
					self.PointTo(targetPoint, 0.5);
					
				else
					self.PointTo(targetPoint);
				end
			end
			
		end
		
		self.NextTarget();
		task.wait();
		return true;
	end
	
	--== Connections;
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	
return self end
