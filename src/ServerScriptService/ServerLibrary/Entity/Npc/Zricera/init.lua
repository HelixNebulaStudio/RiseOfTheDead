local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local CollectionService = game:GetService("CollectionService");

local remotes = game.ReplicatedStorage.Remotes;
local remoteCameraShakeAndZoom = remotes.CameraShakeAndZoom;

local ZombieModule = script.Parent.Zombie;
--== Modules
local modNpcComponent = Debugger:Require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);
local modAudio = Debugger:Require(game.ReplicatedStorage.Library.Audio);
local modExperience = Debugger:Require(game.ServerScriptService.ServerLibrary.Experience);
local modProjectile = Debugger:Require(game.ReplicatedStorage.Library.Projectile);
local modTouchHandler = Debugger:Require(game.ReplicatedStorage.Library.TouchHandler);
local modStatusEffects = Debugger:Require(game.ReplicatedStorage.Library.StatusEffects);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);

local touchHandler;

-- Note; Function called for each zombie before zombie parented to workspace;
local flamePrefab = script:WaitForChild("Flame");
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Name = npc.Name;
		Prefab = npc;
		SpawnPoint = spawnPoint;
		Humanoid = npc:FindFirstChildWhichIsA("Humanoid");
		RootPart = npc.PrimaryPart;
		PathAgent = {AgentRadius=20; AgentHeight=6;};
		
		Properties = {
			WalkSpeed = {Min=16; Max=20};
			AttackSpeed = 4;
			AttackDamage = 50;
			AttackRange = 20;
		};
		
		Configuration = {
			Level=1;
			MoneyReward={Min=1500; Max=1700};
			ExperiencePool=1000;
		};
		
		DespawnPrefab = 30;
	};
	
	--== Initialize;
	self:SetClientScript(script:WaitForChild("ZriceraEffect"));
	
	function self.Initialize()
		if touchHandler == nil then
			touchHandler = modTouchHandler.new("FireSteps", 0.5);

			function touchHandler:OnPlayerTouch(player, basePart, part)
				if player then modStatusEffects.Burn(player, 35, 5); end;
				game.Debris:AddItem(basePart, 0);
			end
			
			function touchHandler:OnPartTouch(basePart, part)
				if CollectionService:HasTag(part, "Flammable") then
					local modFlammable = require(game.ServerScriptService.ServerLibrary.Flammable);
					modFlammable:Ignite(part);
				end
			end
		end
		
		if self.HardMode then
			self.CustomHealthbar:Create("Left Arm", 300000, self.Prefab:WaitForChild("LeftArm"));
			self.CustomHealthbar:Create("Right Arm", 300000, self.Prefab:WaitForChild("RightArm"));
			self.CustomHealthbar:Create("Left Leg", 100000, self.Prefab:WaitForChild("LeftLeg"));
			self.CustomHealthbar:Create("Right Leg", 100000, self.Prefab:WaitForChild("RightLeg"));

			self.Humanoid.MaxHealth = 1200300;
			self.Humanoid.Health = self.Humanoid.MaxHealth;
			
		else
			self.CustomHealthbar:Create("Left Arm", 15000, self.Prefab:WaitForChild("LeftArm"));
			self.CustomHealthbar:Create("Right Arm", 15000, self.Prefab:WaitForChild("RightArm"));
			self.CustomHealthbar:Create("Left Leg", 5000, self.Prefab:WaitForChild("LeftLeg"));
			self.CustomHealthbar:Create("Right Leg", 5000, self.Prefab:WaitForChild("RightLeg"));
			
			for _, obj in pairs(self.Prefab:GetChildren()) do
				if obj:IsA("BasePart") and obj.Material == Enum.Material.Foil then
					obj.Material = Enum.Material.Pebble;
					obj.Color = Color3.fromRGB(218, 134, 122);
				end
			end
		end
		
		function self.CustomHealthbar:OnDamaged(amount, fromPlayer, storageItem, bodyPart)
			if bodyPart == nil then return end;
			if bodyPart.Name == "LeftHand" or bodyPart.Name == "LeftArm" or bodyPart.Name == "LeftShoulder" then
				self:TakeDamage("Left Arm", amount);
				
			elseif bodyPart.Name == "RightHand" or bodyPart.Name == "RightArm" or bodyPart.Name == "RightShoulder" then
				self:TakeDamage("Right Arm", amount);
				
			elseif bodyPart.Name == "LeftFeet" or bodyPart.Name == "LeftHip" or bodyPart.Name == "LeftLeg" then
				self:TakeDamage("Left Leg", amount);
				
			elseif bodyPart.Name == "RightFeet" or bodyPart.Name == "RightHip" or bodyPart.Name == "RightLeg" then
				self:TakeDamage("Right Leg", amount);
			end
		end
		
		self.CustomHealthbar.OnDeath:Connect(function(name, healthInfo)
			if name == "Left Arm" then
				self.Prefab.LeftArm.Color = Color3.fromRGB(50, 50, 50);
			elseif name == "Right Arm" then
				self.Prefab.RightArm.Color = Color3.fromRGB(50, 50, 50);
			elseif name == "Left Leg" then
				self.Prefab.LeftLeg.Color = Color3.fromRGB(50, 50, 50);
			elseif name == "Right Leg" then
				self.Prefab.RightLeg.Color = Color3.fromRGB(50, 50, 50);
			end
		end)
		
		self.Properties.LeapCooldown = tick();
		self.Properties.ThrowPlayerCooldown = tick();
		self.Humanoid.WalkSpeed = self.Properties.WalkSpeed.Max;
		self.Properties.AttackCooldown = tick();
		
		self.FireSplitterCooldown = tick();
		self.SleepHealCooldown = tick();
		self.SleepHealScale = 2;
		
		self.LevelVisuals();

		
		local lastLavaSpawn = tick();
		
		local circlePi = math.pi*2;
		local function spawnLava(position)
			if tick()-lastLavaSpawn <= 0.1 then return end;
			lastLavaSpawn = tick();
			
			local raycastParams = RaycastParams.new();
			raycastParams.FilterType = Enum.RaycastFilterType.Include;
			raycastParams.IgnoreWater = true;
			raycastParams.FilterDescendantsInstances = {workspace.Environment};
			raycastParams.CollisionGroup = "Raycast";
			
			local lavaCount = 6;
			
			for a=1, lavaCount do
				
				local ringPos = position + (CFrame.Angles(0, circlePi/lavaCount*a , 0) * CFrame.new(0, 0, 3)).Position;

				local raycastResult = workspace:Raycast(ringPos + Vector3.new(0, 3, 0), Vector3.new(0, -16, 0), raycastParams);
				if raycastResult then
					local newFlame = flamePrefab:Clone();
					newFlame.CFrame = CFrame.new(raycastResult.Position);
					newFlame.Parent = workspace.Entities;
					Debugger.Expire(newFlame, 10);
					touchHandler:AddObject(newFlame);
					
				end
				
			end
			
		end
		
		local runningTracks = self.AnimationController:GetTrackGroup("Running");
		for a=1, #runningTracks do
			local track = runningTracks[a].Track;
			self.Garbage:Tag(track:GetMarkerReachedSignal("Step"):Connect(function(paramString)
				if paramString == "1" then
					if self.Prefab:FindFirstChild("RightHand") and not self.CustomHealthbar.Healths["Right Arm"].IsDead then
						spawnLava(self.Prefab.RightHand.Position);
					end

				elseif paramString == "2" then
					if self.Prefab:FindFirstChild("LeftHand") and not self.CustomHealthbar.Healths["Left Arm"].IsDead then
						spawnLava(self.Prefab.LeftHand.Position);
					end

				end
			end));
		end
		
		modAudio.Play("ZriceriaRoar", self.RootPart).Volume = 1;
		modAudio.Play("Fire", self.RootPart, true).Volume = 3;
		repeat until not self.Update();
		
		wait(5);
	end
	
	--== Components;
	self:AddComponent("AntiSit");
	self:AddComponent("CustomHealthbar");
	self:AddComponent("Follow");
	self:AddComponent("Movement");
	self:AddComponent("Logic");
	self:AddComponent("CrateReward");
	self:AddComponent(ZombieModule.OnDeath);
	self:AddComponent(ZombieModule.OnHealthChanged);
	self:AddComponent(ZombieModule.OnDamaged);
	self:AddComponent(ZombieModule.OnTarget);
	self:AddComponent(ZombieModule.Throw);
	self:AddComponent(ZombieModule.Leap);
	self:AddComponent(ZombieModule.BasicAttack1);
	self:AddComponent(ZombieModule.LevelVisuals);
	
	--== NPC Logic;
	self.Logic:AddAction("Attack", function(enemiod, position)
		if self.Properties.AttackCooldown == nil then self.Properties.AttackCooldown = tick(); end;
		if tick()-self.Properties.AttackCooldown > self.Properties.AttackSpeed then
			self.Properties.AttackCooldown = tick();
			self.BasicAttack1(enemiod);
		end
	end);
	self.Logic:AddAction("Throw", function(targetHumanoid)
		if (self.Properties.ThrowPlayerCooldown == nil or tick()-self.Properties.ThrowPlayerCooldown > 6) then
			self.Properties.ThrowPlayerCooldown = tick();
			self.PlayAnimation("ThrowPlayer",0.05);
			

			local frostStatus = self.EntityStatus:GetOrDefault("FrostMod");
			self.Throw(targetHumanoid.Parent, 100, frostStatus and 28 or 40);
		end
	end);
	self.Logic:AddAction("Leap", function(targetRootPart)
		if self.CustomHealthbar.Healths["Left Leg"].IsDead and self.CustomHealthbar.Healths["Right Leg"].IsDead then 
			self.Humanoid.WalkSpeed = 20;
			return 
		end;
		if self.Properties.LeapCooldown == nil or tick()-self.Properties.LeapCooldown > 4 then
			self.Properties.LeapCooldown = tick();
			self.Follow();
			self.PlayAnimation("Leap", 0.3);
			wait(0.3);
			modAudio.Play("ZombieAttack"..random:NextInteger(1, 3), self.RootPart).PlaybackSpeed = random:NextNumber(1.1, 1.4);
			
			local frostStatus = self.EntityStatus:GetOrDefault("FrostMod");
			self.Leap(targetRootPart.CFrame.p, frostStatus and 170 or 200);
			
			wait(0.5);
			self.StopAnimation("Leap", 0.4);
			self.Follow(targetRootPart, 5);
		end
	end);
	
	function self.Update()
		if self.IsDead or self.Humanoid.RootPart == nil then return false; end;
		
		local targetHumanoid = self.Enemy and self.Enemy.Humanoid or nil;
		local targetRootPart = self.Enemy and self.Enemy.RootPart;
		if self.Enemy ~= nil and targetRootPart ~= nil and targetHumanoid.Health > 0 then
			self.Follow(targetRootPart, 5);
			local targetPlayer = game.Players:GetPlayerFromCharacter(self.Enemy.Character);
			if targetPlayer then
				self.Enemy.Distance = targetPlayer:DistanceFromCharacter(self.RootPart.Position);
				if self.Enemy.Distance < self.Properties.AttackRange then
					self.Logic:Action("Attack", targetHumanoid, targetRootPart.CFrame.p);
				end
				if self.Enemy.Distance < 25 then
					modAudio.Play("ZombieAttack"..random:NextInteger(1, 3), self.RootPart).Volume = 2;
					self.Logic:Action("Throw", targetHumanoid);
					self.Follow();
					wait(random:NextNumber(2, 4));
				end
				if self.Enemy and self.Enemy.Distance > 50 and self.Properties.Speed and self.Properties.Speed > 5 then
					self.Logic:Action("Leap", targetRootPart);
				end
			end
		else
			self.Follow();
		end
		if self.HardMode then
			local rpOffset = {
				Vector3.new(-3, 0, 0);
				Vector3.new(3, 0, 0);
				Vector3.new(0, 0, 3);
				Vector3.new(0, 0, -3);
			};
			
			local projTravelTime = 0.5;
			if tick()-self.FireSplitterCooldown >= 10 then
				self.FireSplitterCooldown = tick();
				
				self.Humanoid.WalkSpeed = 0;
				
				self.PlayAnimation("SplitFire");
				modAudio.Play("ZriceraFireBreath", self.RootPart);
				wait(0.2)
				local fireLaunchPoint = self.Prefab:FindFirstChild("Helmet"):FindFirstChild("FireLaunchPoint");
				for a=1, 14 do
					if self.Enemies then
						local randomEnemy = self.Enemies[random:NextInteger(1, #self.Enemies)];
						local rootPart = randomEnemy and randomEnemy.Humanoid and randomEnemy.Humanoid.Health > 0 and randomEnemy.Humanoid.RootPart;
						if rootPart then
							local origin = fireLaunchPoint.WorldPosition;
							local targetPoint = rootPart.Position;
							
							self.Movement:Face(targetPoint);
							
							--local projectileObject = modProjectile.Fire("liquidFlame", CFrame.new(origin));
							--projectileObject.ArcTracerConfig.ProjectileAcceleration=Vector3.new(0, -100, 0);
							--projectileObject.Owner = self.Prefab;
							--local velocity = projectileObject.ArcTracer:GetVelocityByTime(origin, targetPoint, projTravelTime);
							--modProjectile.ServerSimulate(projectileObject, origin, velocity, {workspace.Environment});
							
							for b=1, 4 do
								local projectileObject = modProjectile.Fire("liquidFlame", CFrame.new(origin));
								projectileObject.ArcTracerConfig.ProjectileAcceleration=Vector3.new(0, -100, 0);
								projectileObject.Owner = self.Prefab;

								local newDamageSource = modDamagable.NewDamageSource{
									Dealer = self.Prefab;
								};
								projectileObject.DamageSource = newDamageSource;
								
								local velocity = projectileObject.ArcTracer:GetVelocityByTime(origin, targetPoint + rpOffset[b], projTravelTime + random:NextNumber(-0.4, 0.4));
								modProjectile.ServerSimulate(projectileObject, origin, velocity, {workspace.Environment});
							end
						end
					end
					wait(0.3);
				end
				
				self.Humanoid.WalkSpeed = 20;
			end

			if tick()-self.SleepHealCooldown >= 20 and self.Humanoid.Health <= self.Humanoid.MaxHealth*0.045 and self.SleepHealScale < 5 then
				self.SleepHealCooldown = tick();
				self.Humanoid.WalkSpeed = 0;
				self.PlayAnimation("Sleep");
				
				wait(1);
				
				local healTicks = 10;
				local missingHp = ((self.Humanoid.MaxHealth/self.SleepHealScale)-(self.Humanoid.MaxHealth*0.045))/healTicks;
				for a=1, healTicks do

					self.Status:TakeDamagePackage(modDamagable.NewDamageSource{
						Damage=-missingHp;
						TargetPart=self.RootPart;
					});
					
					wait(0.5)
					if self.Humanoid.Health <= 0 then
						break;
					end
				end
				
				self.SleepHealScale = self.SleepHealScale +1;
				self.Humanoid.WalkSpeed = 20;
			end
		end
		self.NextTarget();
		self.Logic:Wait(1);
		return true;
	end
	
	--== Connections;
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	self.Garbage:Tag(self.Humanoid.Running:connect(function(speed) self.Properties.Speed = speed; end));
	
return self end
