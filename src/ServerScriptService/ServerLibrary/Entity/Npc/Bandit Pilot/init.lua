local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local BanditModule = script.Parent.Bandit;
local EnemyModule = script.Parent.Enemy;
local HumanModule = script.Parent.Human;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);
local modProjectile = require(game.ReplicatedStorage.Library.Projectile);
local modAoeHighlight = require(game.ReplicatedStorage.Particles.AoeHighlight);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);

local modBanditGunmen = require(script:WaitForChild("BanditGunmen"));

local modAudio = require(game.ReplicatedStorage.Library.Audio);

local remotes = game.ReplicatedStorage.Remotes;
local remoteCameraShakeAndZoom = remotes.CameraShakeAndZoom;

local rocketTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.In, -1, true, 0);
local ropeDeployTweenInfo = TweenInfo.new(5);

-- Note; Function called for each NPC before parented to workspace;
return function(npc, spawnPoint)
	local self = modNpcComponent{
		Prefab = npc;
		Name = npc.Name;
		Head = npc:WaitForChild("Head");
		Humanoid = npc:WaitForChild("Bandit");
		RootPart = npc.PrimaryPart;
		SpawnPoint = spawnPoint; -- CFrame;
		Smart = true;
		
		Properties = {
			Hostile=false;
			WalkSpeed={Min=8; Max=20};
			AttackSpeed=2;
			--AttackDamage=200;
			AttackRange={Min=16; Max=32};
			TargetableDistance=50;
		};
		
		Configuration = {
			Level=1;
			MoneyReward={Min=3700; Max=4300};
			ExperiencePool=1000;
			Audio={Hurt=false;};
		};
		DespawnPrefab = 30;
	};
	
	--== Initialize;
	self:SetClientScript(script:WaitForChild("HelicopterEffect"));
	
	function self.Initialize()
		local heliPrefab;
		
		self.State = "RocketSpam"; --Circle Molotov HeavyGunmen RocketSpam
		self.StartCirclingTick = tick();

		self.BaseHealth = self.Humanoid.Health;
		self.BaseMaxHealth = self.Humanoid.MaxHealth;
		
		if self.HardMode then
			heliPrefab = game.ServerStorage.PrefabStorage.Objects.HardBanditHelicopterRig:Clone();
			
			if self.HealthRescaled ~= true then
				self.Humanoid.MaxHealth = 960000;
				self.Humanoid.Health = self.Humanoid.MaxHealth;
			end

			self.Immunity = 1; -- Start with 1 immunity;
			
		else
			heliPrefab = game.ServerStorage.PrefabStorage.Objects.BanditHelicopterRig:Clone();
			self.State = "Circle";
			
		end
		
		local heliBase = heliPrefab:WaitForChild("Root");
		local animator = heliPrefab:WaitForChild("AnimationController"):WaitForChild("Animator");
		
		local bodyPosition = heliBase:WaitForChild("BodyPosition");
		local bodyGyro = heliBase:WaitForChild("BodyGyro");
		
		self.Helicopter = {
			Prefab = heliPrefab;
			PrimaryPart = heliBase;
			BodyPosition = bodyPosition;
			BodyGyro = bodyGyro;
			WorldRotationY = math.rad(0);
			Speed = 50;
			
			RotRoll = 0;
			RotYaw = 0;
			RotPitch = 0;
			Animations = {};
			
			Altitude = 60;
			Position = self.SpawnPoint.p;
			
			DeployRopes = {};
			DeploySeat = {};
		};
		
		heliPrefab.Name = "Helicopter";
		heliPrefab:PivotTo(CFrame.new(self.Helicopter.Position.X, self.Helicopter.Position.Y+ self.Helicopter.Altitude+60 , self.Helicopter.Position.Z-300))
		heliPrefab.Parent = self.Prefab;
		
		heliBase:SetNetworkOwner(nil);
		-- Load animations;
		self.Helicopter.Animations.OpenDoors = animator:LoadAnimation(script:WaitForChild("OpenDoors"));
		
		local heliParts = heliPrefab:GetChildren();
		for a=1, #heliParts do
			local heliPart = heliParts[a];
			if heliPart:IsA("BasePart") then
				heliPart:SetNetworkOwner(nil);
				
				local partName = heliPart.Name;
				if partName == "TopCover" then
					heliPart:AddTag("EntityDestructibles");
					self.CustomHealthbar:Create("Top Rotor", self.HardMode and 25000 or 10000, heliPart);

				elseif (self.HardMode and partName == "TailHitbox") or partName == "TailPart" then
					heliPart:AddTag("EntityDestructibles");
					self.CustomHealthbar:Create("Tail Rotor", self.HardMode and 25000 or 25000, heliPart);
					
				elseif partName == "FrontTip" then
					heliPart:AddTag("EntityDestructibles");
					self.CustomHealthbar:Create("Controls", self.HardMode and 50000 or 10000, heliPart);

				elseif partName == "LLauncherHitbox" or partName == "RLauncherHitbox" then
					heliPart:AddTag("EntityDestructibles");
					self.CustomHealthbar:Create(partName == "LLauncherHitbox" and "Left Missile Launcher" or "Right Missile Launcher", 40000, heliPart);
					
				elseif partName == "RopePoint" then
					heliPart:SetNetworkOwner(nil);

				elseif heliPart.Name == "DeploySeatL" or heliPart.Name == "DeploySeatR" then
					table.insert(self.Helicopter.DeploySeat, heliPart);
					
				end
				
			end
		end
		
		
		self.Helicopter.BodyPosition.MaxForce = Vector3.new(math.huge, math.huge, math.huge);
		self.Helicopter.BodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge);
		
		--== Circling
		self.CircleRad = -math.pi/2;
		local circlingRate = math.pi/(360*2.5);
		local invertCircling = true;
		local flipCirclingTimer = tick();
		
		function self.HelicopterUpdate()
			if self.isCircling then
				local cf = CFrame.new(self.CirclingPoint) * CFrame.Angles(0, self.CircleRad, 0) * CFrame.new(self.CirclingRadius, 0, 0);
				self.CircleRad = self.CircleRad + circlingRate * (invertCircling and 1 or -1);
				if tick()-flipCirclingTimer > 35 then
					flipCirclingTimer = tick();
					invertCircling = not invertCircling;
				end
				
				self.Helicopter.BodyPosition.Position = cf.p;
				
				if self.State == "RocketSpam" then
					self.Helicopter.RotRoll = 0.05 * (invertCircling and -1 or 1);
					self.Helicopter.RotYaw = 1.4 * (invertCircling and 1 or -1);
					self.Helicopter.RotPitch = -0.5;
					
				else
					self.Helicopter.RotRoll = 0.5 * (invertCircling and -1 or 1);
					self.Helicopter.RotYaw = 0.5;
					self.Helicopter.RotPitch = 0;
					
				end
			end
			
			local diff = (heliBase.Position - self.Helicopter.BodyPosition.Position);
			local dir = diff.Unit;
			
			local mag = diff.Magnitude;
			
			if mag > 4 then
				self.Helicopter.WorldRotationY = math.atan2(dir.Z, -dir.X);

				local midAng, maxAng = math.rad(-90), math.rad(90);
				local rotZ = -math.clamp(math.atan(dir.Z)/2, midAng, maxAng);
				local rotX = math.clamp(math.atan(dir.X)/2, midAng, maxAng);
				self.Helicopter.BodyGyro.CFrame = CFrame.Angles(rotZ, 0, rotX) 
					* CFrame.Angles(0, self.Helicopter.WorldRotationY, 0) 
					* CFrame.Angles(self.Helicopter.RotRoll, self.Helicopter.RotYaw, self.Helicopter.RotPitch);
				
			else
				self.Helicopter.BodyGyro.CFrame = CFrame.Angles(math.sin(tick()/2)/4, 0, math.sin(tick()/2)/4); -- Roll, Yaw, Pitch
				
			end
			
		end
		
		function self.Helicopter.Move(target)
			local origin = heliBase.Position;
			local dir = (origin-target)
			local dist = dir.Magnitude;
			
			if heliBase:CanSetNetworkOwnership() then
				heliBase:SetNetworkOwner(nil);
			end
			self.Helicopter.WorldRotationY = math.atan2(dir.Z, -dir.X);
			
			if dist < 4 then
				self.Helicopter.ReachedDestination = true;
				return 
			else
				self.Helicopter.ReachedDestination = false;
			end;
			
			local waypoints = dist/self.Helicopter.Speed;
			local step = 1/waypoints;
			
			
			for a=0, 1, step/10 do
				local newPos = origin:Lerp(target, math.clamp(a, 0, 1));
				self.Helicopter.BodyPosition.Position = newPos;
				
				task.wait(0.1);
			end
		end
		
		function self.CustomHealthbar:OnDamaged(amount, fromPlayer, storageItem, bodyPart)
			if self.IsDead or bodyPart == nil then return end;
			
			local healthInfo = self:GetFromPart(bodyPart);
			if healthInfo then
				self:TakeDamage(healthInfo.Name, amount);

				local part = healthInfo.BasePart;
				if tick()-(healthInfo.LastSoundEffect or 0) > 1.5 then
					healthInfo.LastSoundEffect = tick();
					
					modAudio.Play("VechicleExplosion", part).PlaybackSpeed = math.random(90,110)/100;
				end
				
				if self.Npc.HardMode then
					return true;
				end
			end

			return;
		end
		
		local debrisParts;
		local function harmImmunity()
			self.Immunity = math.clamp(self.Immunity - 0.3, 0.1, 1);
			
			if debrisParts == nil then
				debrisParts = self.Helicopter.Prefab:FindFirstChild("DebrisParts") and self.Helicopter.Prefab.DebrisParts:GetChildren() or nil;
			end
			
			for a=1, math.random(3, 5) do
				local debrisPart = table.remove(debrisParts, a);
				if debrisPart then
					game.Debris:AddItem(debrisPart, 10);
					debrisPart.Parent = workspace.Debris;
					debrisPart:BreakJoints();
				end
			end
		end
		
		self.CustomHealthbar.OnDeath:Connect(function(name, healthInfo)
			local part = healthInfo.BasePart;
			if part then
				local netOwners = self.NetworkOwners or {};
				local partName = part.Name;

				if partName == "TopCover" then
					if self.HardMode then harmImmunity() end
					

					self.Status:TakeDamagePackage(modDamagable.NewDamageSource{
						Damage=self.BaseMaxHealth*0.08;
						TargetPart=self.RootPart;
					});
					
					self.Helicopter.Altitude = 50;
					for a=1, #netOwners do
						local player = netOwners[a];
						remoteCameraShakeAndZoom:FireClient(player, 30, 0, 2, 2, true);
					end
					
				elseif (self.HardMode and partName == "TailHitbox") or partName == "TailPart" then
					if self.HardMode then harmImmunity() end
					

					self.Status:TakeDamagePackage(modDamagable.NewDamageSource{
						Damage=self.BaseMaxHealth*0.05;
						TargetPart=self.RootPart;
					});
					for a=1, #netOwners do
						local player = netOwners[a];
						remoteCameraShakeAndZoom:FireClient(player, 30, 0, 2, 2, true);
					end
					
				elseif partName == "FrontTip" then
					if self.HardMode then harmImmunity() end
					

					self.Status:TakeDamagePackage(modDamagable.NewDamageSource{
						Damage=self.BaseMaxHealth*0.1;
						TargetPart=self.RootPart;
					});
					for a=1, #netOwners do
						local player = netOwners[a];
						remoteCameraShakeAndZoom:FireClient(player, 30, 0, 2, 2, true);
					end

				elseif partName == "LLauncherHitbox" or partName == "RLauncherHitbox" then
					game.Debris:AddItem(part, 0);
					
					if partName == "LLauncherHitbox" then
						self.Helicopter.LeftLaunchers = nil;
					else
						self.Helicopter.RightLaunchers = nil;
					end
					
					local launcherModel = self.Helicopter.Prefab:FindFirstChild(partName == "LLauncherHitbox" and "LeftLauncher" or "RightLauncher");
					if launcherModel then
						part = launcherModel.PrimaryPart;
						launcherModel:BreakJoints();
					end
					
					task.delay(2, function()
						if self.State == "RocketSpam" then
							self.State = "Molotov";
						end
					end)
					
				end
				
				part.Color = Color3.fromRGB(25, 25, 25);

				local smoke = Instance.new("Smoke");
				smoke.Color = Color3.fromRGB(0, 0, 0);
				smoke.Size = 5;
				smoke.RiseVelocity = 10;
				smoke.Opacity = 1;
				smoke.Parent = part;

				local fire = Instance.new("Fire");
				fire.Heat = 15;
				fire.Size = 10;
				fire.Parent = part;
				
				modAudio.Play("VechicleExplosion", part);
			end
		end)
		
		heliPrefab:WaitForChild("PSeat1"):Sit(self.Humanoid);
		self.PlayAnimation("Sit");

		self.Helicopter.GunmenSeats = {heliPrefab:WaitForChild("Seat7"); heliPrefab:WaitForChild("Seat8");};
		
		local gunmenSpawned = false;
		local gunmenModules = {};
		self.GunmenModules = gunmenModules;
		
		function self.Helicopter.RespawnGunmen()
			if self.IsDead then return end;
			if gunmenSpawned then return end;
			gunmenSpawned = true;
			
			if #gunmenModules <= 0 then
				for a=1, 2 do
					self.NpcService.Spawn("Bandit", CFrame.new(self.Helicopter.Position) * CFrame.new(0, 200, 0), function(banditNpc, banditNpcModule)
						
						table.insert(gunmenModules, banditNpcModule);
						banditNpcModule.Arena = self.Arena;
						banditNpcModule.HardMode = self.HardMode;
						banditNpcModule.NetworkOwners = self.NetworkOwners;
						
						banditNpcModule.Properties.TargetableDistance = 4096;
						banditNpcModule.OnTarget(self.NetworkOwners or game.Players:GetPlayers());
						
						local humanoid = banditNpcModule.Humanoid;
						
						local deathDebounce = false;
						humanoid.Died:Connect(function()
							if deathDebounce then return end 
							deathDebounce = true;

							game.Debris:AddItem(banditNpc, 3);
							for a=#gunmenModules, 1, -1 do
								if gunmenModules[a] == banditNpcModule then
									table.remove(gunmenModules, a);
								end
							end
						end, modBanditGunmen);
						
						self.Humanoid.Died:Connect(function()
							humanoid.Health = 0;
							game.Debris:AddItem(banditNpc, 1);
							if banditNpcModule.Destroy then
								banditNpcModule:Destroy();
							end
						end);

						-- Sit on heli;
						banditNpcModule.Seat = self.Helicopter.GunmenSeats[a];
					end, modBanditGunmen);
				end
			end
		end

		task.spawn(function()
			while not self.IsDead do
				self.HelicopterUpdate();
				task.wait();
			end
		end)
		
		self.Helicopter.Move(self.Helicopter.Position + Vector3.new(0, self.Helicopter.Altitude, 200));
		
		
		self.ProjectileConfig = require(game.ReplicatedStorage.Library.Tools.molotov)();
		
		self.Helicopter.DropOrigins = {};
		for _, obj in pairs(heliBase:GetChildren()) do
			if obj.Name == "DropOrigin" then
				table.insert(self.Helicopter.DropOrigins, obj);
				
			elseif obj.Name == "DropdownRope" or obj.Name == "RopePointJoint" then
				table.insert(self.Helicopter.DeployRopes, obj);
				
			end
		end
		
		local heavyBanditsModules = {};
		self.HeavyBanditsModules = heavyBanditsModules;
		
		local function despawnHeavyGunmen()
			for a=1, #gunmenModules do
				if gunmenModules[a] then
					game.Debris:AddItem(gunmenModules[a].Prefab, 0);
					
					gunmenModules[a]:KillNpc();
				end
			end
			table.clear(gunmenModules);

			for a=1, #heavyBanditsModules do
				if heavyBanditsModules[a] then
					game.Debris:AddItem(heavyBanditsModules[a].Prefab, 0);

					heavyBanditsModules[a]:KillNpc();
				end
			end
			table.clear(heavyBanditsModules);

			self:KillNpc();
		end
		
		self.Garbage:Tag(self.Prefab.Destroying:Connect(despawnHeavyGunmen))
		self.Humanoid.Died:Connect(despawnHeavyGunmen);
		
		self.Helicopter.LeftLaunchers = {};
		self.Helicopter.RightLaunchers = {};
		for _, v: BasePart in next, self.Prefab:GetDescendants() do
			if v:IsA("BasePart") then
				
				v.CollisionGroup = "CollisionOff";
				
				if v.Name == "LLauncherBase" then
					for _, lp in pairs(v:GetChildren()) do
						if lp.Name == "LauncherPoint" then
							table.insert(self.Helicopter.LeftLaunchers, lp);
						end
					end
					
				elseif v.Name == "RLauncherBase" then
					for _, lp in pairs(v:GetChildren()) do
						if lp.Name == "LauncherPoint" then
							table.insert(self.Helicopter.RightLaunchers, lp);
						end
					end
				end
			end
		end
		
		while not self.IsDead do
			if #gunmenModules > 0 then
				if self.HardMode ~= true then
					self.Immunity = 0.5;
				end
				if not self.Helicopter.Animations.OpenDoors.IsPlaying then
					self.Helicopter.Animations.OpenDoors:Play();
				end
				
			else
				-- gunmen all died;
				
				if self.HardMode ~= true then
					self.Immunity = nil;
				end
				if self.Helicopter.Animations.OpenDoors.IsPlaying then
					self.Helicopter.Animations.OpenDoors:Stop();
				end
				
				if gunmenSpawned then
					if self.HardMode == true then
						self.HeavySpawnsCount = 0;
						self.State = "HeavyGunmen";
						
					else
						self.State = "Molotov";
						
					end
					gunmenSpawned = false;
					self.isCircling = false;
				end
			end
			
			if self.Update == nil or self.Update() == false then
				break;
			end
			task.wait();
		end
		
		Debugger:Log(self.Name,"Died");
	end
	
	--== NPC Logic;
	function self.Update()
		if self.IsDead then return false; end;
		if self.Humanoid == nil then return false; end;
		self.Helicopter.PrimaryPart:SetNetworkOwner(nil);
		
		if self.State == "Circle" then
			if self.isCircling ~= true then
				self.CirclingPoint = self.Helicopter.Position + Vector3.new(0, self.Helicopter.Altitude, 0);
				self.CirclingRadius = 100;
				self.isCircling = true;
				
				local cf = CFrame.new(self.CirclingPoint) * CFrame.Angles(0, self.CircleRad, 0) * CFrame.new(self.CirclingRadius, 0, 0);
				self.Helicopter.Move(cf.p);
			end
			self.Helicopter.RespawnGunmen();
			
			if tick()-self.StartCirclingTick >= 60 then
				self.isCircling = false;
				
				for _, gunmenModule in pairs(self.GunmenModules) do
					Debugger.Expire(gunmenModule.Prefab);
				end
				table.clear(self.GunmenModules);
			end
			
		elseif self.State == "HeavyGunmen" then
			self.Helicopter.Move(self.Helicopter.Position + Vector3.new(0, self.Helicopter.Altitude, 0));
			self.Helicopter.Speed = 50;
			
			if self.Helicopter.ReachedDestination then
				task.wait(1);
				
				if not self.Helicopter.Animations.OpenDoors.IsPlaying then
					self.Helicopter.Animations.OpenDoors:Play();
				end
				for a=1, #self.Helicopter.DeployRopes do
					local ropeObj = self.Helicopter.DeployRopes[a];
					if ropeObj.Name == "RopePointJoint" then
						ropeObj.Enabled = false;
						
					else
						ropeObj.Visible = true;
						TweenService:Create(ropeObj, ropeDeployTweenInfo, {
							Length = 45;
						}):Play();
					end
				end
				
				for a=1, 2 do
					self.NpcService.Spawn("Heavy Bandit", CFrame.new(self.Helicopter.Position) * CFrame.new(0, 200, 0), function(banditNpc, banditNpcModule)
						game.Debris:AddItem(banditNpc, 300);
						table.insert(self.HeavyBanditsModules, banditNpcModule)
						
						banditNpcModule.Arena = self.Arena;
						banditNpcModule.HardMode = self.HardMode;
						banditNpcModule.NetworkOwners = self.NetworkOwners;
						banditNpcModule.Properties.TargetableDistance = 4096;
						banditNpcModule.ForgetEnemies = false;

						local deathDebounce = false;
						banditNpcModule.Humanoid.Died:Connect(function()
							if deathDebounce then return end
							deathDebounce = true;

							game.Debris:AddItem(banditNpc, 3);
						end)

						self.Humanoid.Died:Connect(function()
							banditNpcModule.Humanoid.Health = 0;
							game.Debris:AddItem(banditNpc, 1);
							banditNpcModule:Destroy();
						end);
						
						banditNpcModule.OnTarget(self.NetworkOwners or game.Players:GetPlayers());

						-- Sit on heli;
						banditNpcModule.DeploySeat = self.Helicopter.DeploySeat[a];
						task.delay(4, function()
							banditNpcModule.DeploySeat = nil;
							banditNpcModule.Humanoid.Jump = true;
						end)
					end);
				end
				
				task.wait(10);
				for a=1, #self.Helicopter.DeployRopes do
					TweenService:Create(self.Helicopter.DeployRopes[a], ropeDeployTweenInfo, {
						Length = 1;
					}):Play();
				end
				task.wait(5);

				for a=1, #self.Helicopter.DeployRopes do
					local ropeObj = self.Helicopter.DeployRopes[a];
					if ropeObj.Name == "RopePointJoint" then
						ropeObj.Enabled = true;
					else
						ropeObj.Visible = false;
					end
				end
				
				task.wait(6);
				self.HeavySpawnsCount = self.HeavySpawnsCount +1;
				
				
				if self.HeavySpawnsCount > 2 then
					if self.Helicopter.LeftLaunchers or self.Helicopter.RightLaunchers then
						self.State = "RocketSpam";
						
					else
						self.State = "Molotov";
						
					end
					
				end
			end

		elseif self.State == "RocketSpam" and (self.Helicopter.LeftLaunchers or self.Helicopter.RightLaunchers) then
			self.CirclingPoint = self.Helicopter.Position + Vector3.new(0, self.Helicopter.Altitude, 0);
			self.CirclingRadius = 100;
			self.isCircling = true;

			local cf = CFrame.new(self.CirclingPoint) * CFrame.Angles(0, self.CircleRad, 0) * CFrame.new(self.CirclingRadius, 0, 0);
			self.Helicopter.Move(cf.p);
			
			if self.LastBarrage == nil then
				self.LastBarrage = tick();
				
			elseif tick()-self.LastBarrage >= math.random(8, 11) then
				self.LastBarrage = tick();

				task.spawn(function()
					for a=1, 10 do
						local rngTarget = self.OnTargetPickRandom();
						if rngTarget and rngTarget.Humanoid and rngTarget.Humanoid.RootPart then
							local targetRp = rngTarget.Humanoid.RootPart;
							local targetPoint = targetRp.Position;
							
							local travelTime = math.random(90, 120)/100;
							
							local selectedLaunchers = self.Helicopter.LeftLaunchers or self.Helicopter.RightLaunchers;
							if math.random(1, 2) == 1 then
								selectedLaunchers = self.Helicopter.RightLaunchers or self.Helicopter.LeftLaunchers;
							end
							
							if selectedLaunchers == nil then
								return;
							end
							local pickLauncher = selectedLaunchers[math.random(1, #selectedLaunchers)];

							local origin = pickLauncher.WorldCFrame;

							local groundCframe = modAoeHighlight:Ray(targetRp.Position, Vector3.new(0, -8, 0));
							
							if groundCframe then
								local new = modAoeHighlight.newCylinder(travelTime);
								new.CFrame = groundCframe
								new.Size = Vector3.new(2, 2, 1);
								new.Parent = workspace.Debris;

								TweenService:Create(new, rocketTweenInfo, {Size = Vector3.new(32,32,1)}):Play();
								
								local projectileObject = modProjectile.Fire("zomborgRocket", CFrame.new(origin.Position));
								projectileObject.TargetableEntities = {Humanoid=1;};
								projectileObject.NetworkOwners = self.NetworkOwners;
								
								projectileObject.Damage = self.RocketBarrageDamage;
								
								if projectileObject.Prefab:CanSetNetworkOwnership() then projectileObject.Prefab:SetNetworkOwner(nil); end

								local velocity = projectileObject.ArcTracer:GetVelocityByTime(origin.Position, targetPoint, travelTime);
								modProjectile.ServerSimulate(projectileObject, origin.Position, velocity);
								
							end
							
						end
						
						task.wait(0.3);
					end
				end)
			
			end
			
		elseif self.State == "Molotov" then
			self.Helicopter.RotRoll = 0;
			self.Helicopter.RotYaw = 0;
			
			local random = math.random(1, 4);
			local flybyDir = Vector3.new(0, self.Helicopter.Altitude, 150);
			if random == 1 then
				flybyDir = Vector3.new(150, self.Helicopter.Altitude, 0);
				
			elseif random == 2 then
				flybyDir = Vector3.new(75, self.Helicopter.Altitude, 75);
				
			elseif random == 3 then
				flybyDir = Vector3.new(-75, self.Helicopter.Altitude, 75);
				
			end
			
			self.Helicopter.Move(self.Helicopter.Position + flybyDir);
			self.Helicopter.Speed = 200;
			
			if not self.Helicopter.Animations.OpenDoors.IsPlaying then
				self.Helicopter.Animations.OpenDoors:Play();
			end
			
			for a=1, #(self.NetworkOwners or {}) do
				local player = self.NetworkOwners[a];
				remoteCameraShakeAndZoom:FireClient(player, 10, 0, 4, 2, true);
			end
			
			task.spawn(function()
				task.wait(0.6);
				for a=1, 6 do
					for b=1, #self.Helicopter.DropOrigins do
						local origin = self.Helicopter.DropOrigins[b].WorldCFrame;
						
						local projectileObject = modProjectile.Fire("molotov", origin, Vector3.new());
						projectileObject.TargetableEntities = {Humanoid=1; Zombie=1; Bandit=1; Rat=1;};
						projectileObject.NetworkOwners = self.NetworkOwners;
						projectileObject.ArcTracerConfig.IgnoreEntities = true;
						
						if projectileObject.Prefab:CanSetNetworkOwnership() then projectileObject.Prefab:SetNetworkOwner(nil); end
						
						modProjectile.ServerSimulate(projectileObject, origin.p, origin.LookVector * 20, {workspace.Environment});
					end
					task.wait(0.2);
				end
			end)
			
			self.Helicopter.Move(self.Helicopter.Position + Vector3.new(-flybyDir.X, self.Helicopter.Altitude, -flybyDir.Z));
			if self.Helicopter.Animations.OpenDoors.IsPlaying then
				self.Helicopter.Animations.OpenDoors:Stop();
			end
			self.Helicopter.Speed = 50;
			
			task.wait(2);
			
			self.StartCirclingTick = tick();
			self.State = "Circle";
			
		end
		
		return true;
	end
	
	--== Components;
	self:AddComponent("CustomHealthbar");
	
	self:AddComponent("CrateReward");
	self:AddComponent(EnemyModule.OnDamaged);
	self:AddComponent(EnemyModule.OnDeath);
	self:AddComponent(HumanModule.OnHealthChanged);
	self:AddComponent(HumanModule.Chat);
	self:AddComponent(HumanModule.Actions);
	
	self:AddComponent(BanditModule.OnTarget);
	
	--== Signals
	self.Humanoid.Died:Connect(self.OnDeath);

return self end
