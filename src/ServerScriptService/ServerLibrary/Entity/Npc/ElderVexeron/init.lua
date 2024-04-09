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
local modItemDrops = require(game.ServerScriptService.ServerLibrary.ItemDrops);

local modVexSpitter = require(script:WaitForChild("VexSpitter"));

-- Note; Function called for each zombie before zombie parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Name = npc.Name;
		Prefab = npc;
		SpawnPoint = spawnPoint;
		Humanoid = npc:FindFirstChildWhichIsA("Humanoid");
		RootPart = npc.PrimaryPart;
		PathAgent = {AgentRadius=20; AgentHeight=11;};
		Immortal = 0;
		Immunity = 1;
		
		Properties = {
			WalkSpeed = {Min=16; Max=18};
			AttackSpeed = 4;
			AttackDamage = 30;
			AttackRange = 20;
			MovementSpeed = 10;
		};
		
		Configuration = {
			Level=1;
			MoneyReward={Min=2000; Max=3500};
			ExperiencePool=1000;
			VexeronLength = 8;
		};
		
		KnockbackResistant = true;
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

		self.Configuration.VexeronLength = 8;
		self.Humanoid.MaxHealth = 256000;
		self.Humanoid.Health = self.Humanoid.MaxHealth;
		self.Properties.AttackDamage = 10;
		
		self.VexSpitter = {};
		self.SpitterCount = 0;
		
		self.SpitterKillCount = 0;
		self.SnoozeState = 0;
		self.SnoozeTimer = tick();
		
		self.SporeObjects = {};
		self.VeinLaunched = 0;
		
		-- CustomHealthbar
		self.BodyWeights = {};
		
		local prevLowerLink = self.VexBody:WaitForChild("LowerLink");
		
		for a=1, self.Configuration.VexeronLength do
			local new = self.VexBody:Clone();
			new.Name = new.Name..a;
			
			
			new.Size = self.VexBody.Size * 4;
			local nULink = new:WaitForChild("UpperLink");
			local nLLink = new:WaitForChild("LowerLink");
			nULink.Position = Vector3.new(0, 20, 0);
			nLLink.Position = Vector3.new(0, -20, 0);
				

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
			local force = 25000000;
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
			end
		end

		function self.CustomHealthbar:OnDamaged(amount, fromPlayer, storageItem, bodyPart)
			if self.IsDead or bodyPart == nil then return end;
			if self.Healths[bodyPart.Name] then
				self:TakeDamage(bodyPart.Name, amount);
				
				return true;
			end
		end

		self.CustomHealthbar.OnDeath:Connect(function(name, healthInfo)
			local bodyPart = self.Prefab:FindFirstChild(name);
			if bodyPart and bodyPart.Name:match("VexeronSpitterHead") then
				bodyPart.Color = Color3.fromRGB(50, 50, 50);
				
				local newExplosion = Instance.new("Explosion");
				newExplosion.DestroyJointRadiusPercent = 0;
				newExplosion.Position = bodyPart.Position;
				newExplosion.Parent = self.Prefab;
				
				self.Properties.AttackDamage = math.clamp(self.Properties.AttackDamage-3, 15, 30);
				
				bodyPart:ClearAllChildren();
				bodyPart.CanCollide = true;
				game.Debris:AddItem(bodyPart, 10);
				modAudio.Play("TicksZombieExplode", workspace).PlaybackSpeed = random:NextNumber(0.35, 0.4);
				modAudio.Play("VexeronPain", bodyPart).PlaybackSpeed = random:NextNumber(0.35, 0.4);
				
				task.spawn(function()
					local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
					local itemDrop = modItemDrops.ChooseDrop(modRewardsLibrary:Find("tendrils"));
					if itemDrop then
						modItemDrops.Spawn(itemDrop, CFrame.new(bodyPart.Position), nil, false);
					end
				end)
				
				for a=#self.VexSpitter, 1, -1 do
					if self.VexSpitter[a].SpitterHead.Name == name then
						self.VexSpitter[a].SpitterHead:ClearAllChildren();
						table.remove(self.VexSpitter, a);
						
					end
				end
				
				if self.SnoozeState == 0 then
					self.SpitterKillCount = self.SpitterKillCount +1;
					Debugger:Log("self.SpitterKillCount", self.SpitterKillCount);
					if self.SpitterKillCount > 4 then
						Debugger:Log("Is going to snooze");
						if workspace.Environment:FindFirstChild("Game") and workspace.Environment.Game:FindFirstChild("ElderVexDoor") then
							game.Debris:AddItem(workspace.Environment.Game.ElderVexDoor, 0);
						end
						
						self.Properties.MovementSpeed = 50;
						self.SpitterKillCount = 0;
						self.SnoozeState = 1;
						self.SnoozeTimer = tick();
						self.Prefab:SetAttribute("IsSnoozing", true);
						
						modAudio.Play("VexeronGrowl", bodyPart).PlaybackSpeed = 0.3;
						
						if self.SunkenShipOnSleep then
							self.SunkenShipOnSleep();
						end
					end
					
				end;
			end
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
			
			if player.Character:FindFirstChild("vexling") and player:DistanceFromCharacter(self.VexBody.Position) <= 50 then
				local profile = shared.modProfile:Get(player);
				if profile.Cache.Mission77_EnterElderVex then
					profile.Cache.Mission77_EnterElderVex(self);
					
					self.OnEatPlayer();
				end
				return;
			end
			
			if hitPart.Name:match("VexeronBody") then
				self:DamageTarget(player.Character, self.Properties.AttackDamage);
				modStatusEffects.Knockback(player, hitPart, 100);
			end
		end))

		self.UpdateVelocity = function()
			self.BodyMovers.BodyVelocity.Velocity = self.BodyMovers.BodyGyro.CFrame.UpVector * self.BodyMovers.BodyVelocity.P;
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
		self.BodyWeights = nil;
		task.wait(5);
	end

	--== Components;
	self:AddComponent("AntiSit");
	self:AddComponent("CustomHealthbar");
	self:AddComponent(ZombieModule.OnDeath);
	self:AddComponent(ZombieModule.OnHealthChanged);
	self:AddComponent(ZombieModule.OnDamaged);
	self:AddComponent(ZombieModule.OnTarget);
	self:AddComponent(ZombieModule.LevelVisuals);

	self.PointTo = function(point, lerpIntensity)
		local newFrontCf = CFrame.new(self.RootPart.Position, point) * CFrame.Angles(-math.pi/2, 0, 0);

		self.BodyMovers.BodyGyro.CFrame = self.BodyMovers.BodyGyro.CFrame:Lerp(newFrontCf, lerpIntensity or 0.01);
	end

	self.MoveToPoint = function(point)
		local dist = 20;
		repeat
			dist = (self.RootPart.Position-point).Magnitude;
			self.PointTo(point, dist);
			task.wait();
		until self.IsDead or dist < 25;
	end

	local hasAttacked = false;

	local attackCooldown = tick();
	local spawnSpitterCooldown = tick()+5;
	local isAttacking = false;
	function self.Update()
		if self.IsDead or self.Humanoid.RootPart == nil then return false; end;
		
		local targetHumanoid = self.Enemy and self.Enemy.Humanoid or nil;
		local targetRootPart = self.Enemy and self.Enemy.RootPart;
		
		if self.SnoozeState == 1 then
			
			if tick()-self.SnoozeTimer >= 300 then
				Debugger:Log("Waking up");
				
				self.Prefab:SetAttribute("IsSnoozing", false);
				modAudio.Play("VexeronGrowl", self.RootPart).PlaybackSpeed = random:NextNumber(0.35, 0.4);
				self.SnoozeState = 0;
				self.Properties.MovementSpeed = 15;--30;
				--self.Properties.AttackDamage = 100;
				
				if self.SunkenShipOnWakeUp then
					self.SunkenShipOnWakeUp();
				end
			end

			local targetPoint = Vector3.new(0, -100, 0);
			self.PointTo(targetPoint);
			
			
		elseif targetRootPart and targetHumanoid and targetHumanoid.Health > 0 then
			self.BodyMovers.BodyVelocity.P = self.Properties.MovementSpeed;

			local targetPoint = targetRootPart.Position;
			
			if tick()-spawnSpitterCooldown >= 2 then
				spawnSpitterCooldown = tick();
				
				if self.VexBodies == nil then
					self.VexBodies = {};

					local bodyParts = self.Prefab:GetChildren();
					for a=1, #bodyParts do
						if bodyParts[a]:IsA("BasePart") then
							if bodyParts[a].Name:match("VexeronBody") and bodyParts[a].Name ~= "VexeronBody" then
								table.insert(self.VexBodies, bodyParts[a]);
							end
						end
					end
					
					self.Garbage:Tag(function()
						table.clear(self.VexBodies);
					end)
				end
				
				if self.VexBodies then
					
					for a=1, #self.Enemies do
						local targetRootPart = self.Enemies[a] and self.Enemies[a].RootPart;

						if #self.VexSpitter < 5 then
							
							local vexBody = self.VexBodies[math.random(1, #self.VexBodies)];
							local vexSpitterObject = modVexSpitter.Spawn(vexBody.Position, self.Prefab, {
								WeldTo=vexBody;
							});
							table.insert(self.VexSpitter, vexSpitterObject);
							self.SpitterCount = self.SpitterCount +1;
							vexSpitterObject.SpitterHead.Name = vexSpitterObject.SpitterHead.Name .. self.SpitterCount;
							
							local spitterHeadHealthObj = self.CustomHealthbar:Create(vexSpitterObject.SpitterHead.Name, 4000, vexSpitterObject.SpitterHead);
						end

						if #self.VexSpitter > 0 then
							local vexSpitter;
							
							for i=1, 3 do
								vexSpitter = self.VexSpitter[math.random(1, #self.VexSpitter)];
								
								if vexSpitter and vexSpitter.SpitterHead then
									local targetDistance = (targetRootPart.Position - self.RootPart.Position).Magnitude;
									if targetDistance <= 350 then
										vexSpitter:FireProj(targetRootPart);
										
										break;
									end
								end
							end
							
						end
						
					end
					
				end
			end
			
			local attackTimer = 5;
			if tick()-attackCooldown >= attackTimer then
				self.PointTo(targetPoint, 0.1);

				if tick()-attackCooldown >= (attackTimer+6) then
					attackCooldown = tick();
				end
			else
				local dist = (targetPoint-self.RootPart.Position).Magnitude;
				if dist > 800 then
					self.PointTo(targetPoint, 1);

				elseif dist > 400 then
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

