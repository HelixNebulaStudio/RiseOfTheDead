local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local RunService = game:GetService("RunService");
local PhysicsService = game:GetService("PhysicsService");

local BanditModule = game.ServerScriptService.ServerLibrary.Entity.Npc.Bandit;
local EnemyModule = game.ServerScriptService.ServerLibrary.Entity.Npc.Enemy;
local HumanModule = game.ServerScriptService.ServerLibrary.Entity.Npc.Human;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);
local modProjectile = require(game.ReplicatedStorage.Library.Projectile);

local modBanditGunmen = require(script:WaitForChild("BanditGunmen"));

local modAudio = require(game.ReplicatedStorage.Library.Audio);

local remotes = game.ReplicatedStorage.Remotes;
local remoteCameraShakeAndZoom = remotes.CameraShakeAndZoom;
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
			ExperiencePool=40;
			Audio={Hurt=false;};
		};
	};
	
	--== Initialize;
	function self.Initialize()
		local heliPrefab;

		if self.HardMode then
			heliPrefab = game.ServerStorage.PrefabStorage.Objects.HardBanditHelicopterRig:Clone();
		else
			heliPrefab = game.ServerStorage.PrefabStorage.Objects.BanditHelicopterRig:Clone();
		end
		
		local heliBase = heliPrefab:WaitForChild("Root");
		local animator = heliPrefab:WaitForChild("AnimationController"):WaitForChild("Animator");
		
		local bodyPosition = heliBase:WaitForChild("BodyPosition");
		local bodyGyro = heliBase:WaitForChild("BodyGyro");
		
		self.State = "Circle"; --Circle Molotov
		
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
		};
		
		--heliPrefab:SetPrimaryPartCFrame(CFrame.new(self.Helicopter.Position.X, 80, self.Helicopter.Position.Z-300));
		heliPrefab.Parent = self.Prefab;
		
		heliBase:SetNetworkOwner(nil);
		-- Load animations;
		self.Helicopter.Animations.OpenDoors = animator:LoadAnimation(script:WaitForChild("OpenDoors"));
		
		local heliParts = heliPrefab:GetChildren();
		for a=1, #heliParts do
			if heliParts[a]:IsA("BasePart") then
				heliParts[a]:SetNetworkOwner(nil);
				
				local partName = heliParts[a].Name;
				if partName == "TopCover" then
					self.CustomHealthbar:Create(partName, 10000, heliParts[a]);
					
				elseif partName == "TailPart" then
					self.CustomHealthbar:Create(partName, 25000, heliParts[a]);
					
				elseif partName == "FrontTip" then
					self.CustomHealthbar:Create(partName, 10000, heliParts[a]);
					
				end
			end
		end
		
		
		self.Helicopter.BodyPosition.MaxForce = Vector3.new(math.huge, math.huge, math.huge);
		self.Helicopter.BodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge);
		self.Helicopter.BodyPosition.Position = self.RootPart.Position;
		
		--== Circling
		self.CircleRad = 0;
		local circlingRate = math.pi/(360*2.5);
		local invertCircling = true;
		local flipCirclingTimer = tick();
		
		function self.HelicopterUpdate()
			if true then return end;
			if self.isCircling then
				local cf = CFrame.new(self.CirclingPoint) * CFrame.Angles(0, self.CircleRad, 0) * CFrame.new(self.CirclingRadius, 0, 0);
				self.CircleRad = self.CircleRad + circlingRate * (invertCircling and 1 or -1);
				if tick()-flipCirclingTimer > 35 then
					flipCirclingTimer = tick();
					invertCircling = not invertCircling;
				end
				
				self.Helicopter.BodyPosition.Position = cf.p;
				self.Helicopter.RotRoll = 0.5 * (invertCircling and -1 or 1);
				self.Helicopter.RotYaw = 0.5;
			end
			
			local diff = (heliBase.Position - self.Helicopter.BodyPosition.Position);
			local dir = diff.Unit;
			
			self.Helicopter.WorldRotationY = math.atan2(dir.Z, -dir.X);
			
			local midAng, maxAng = math.rad(-90), math.rad(90);
			local rotZ = -math.clamp(math.atan(dir.Z)/2, midAng, maxAng);
			local rotX = math.clamp(math.atan(dir.X)/2, midAng, maxAng);
			self.Helicopter.BodyGyro.CFrame = CFrame.Angles(rotZ, 0, rotX) 
				* CFrame.Angles(0, self.Helicopter.WorldRotationY, 0) 
				* CFrame.Angles(self.Helicopter.RotRoll, self.Helicopter.RotYaw, self.Helicopter.RotPitch);
		end
		
		function self.Helicopter.Move(target)
			if true then return end;
			local origin = heliBase.Position;
			local dir = (origin-target)
			local dist = dir.Magnitude;
			
			if dist < 1 then return end;
			
			self.Helicopter.WorldRotationY = math.atan2(dir.Z, -dir.X);
			
			local waypoints = dist/self.Helicopter.Speed;
			local step = 1/waypoints;
			
			if heliBase:CanSetNetworkOwnership() then
				heliBase:SetNetworkOwner(nil);
			end
			
			for a=0, 1, step/10 do
				local newPos = origin:Lerp(target, math.clamp(a, 0, 1));
				self.Helicopter.BodyPosition.Position = newPos;
				
				task.wait(0.1);
				self.HelicopterUpdate();
			end
		end
		
		function self.CustomHealthbar:OnDamaged(amount, fromPlayer, storageItem, bodyPart)
			if self.IsDead or bodyPart == nil then return end;
			if self.Healths[bodyPart.Name] then
				self:TakeDamage(bodyPart.Name, amount);
			end
		end
		
		self.CustomHealthbar.OnDeath:Connect(function(name, healthInfo)
			local part = healthInfo.BasePart;
			if part then
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
				
				local netOwners = self.NetworkOwners or {};
				local partName = part.Name;
				if partName == "TopCover" then
					self.Helicopter.Altitude = 50;
					for a=1, #netOwners do
						local player = netOwners[a];
						remoteCameraShakeAndZoom:FireClient(player, 30, 0, 2, 2, true);
					end
					
				elseif partName == "TailPart" then
					for a=1, #netOwners do
						local player = netOwners[a];
						remoteCameraShakeAndZoom:FireClient(player, 30, 0, 2, 2, true);
					end
					
				elseif partName == "FrontTip" then
					for a=1, #netOwners do
						local player = netOwners[a];
						remoteCameraShakeAndZoom:FireClient(player, 30, 0, 2, 2, true);
					end
					
				end
			end
		end)
		
		heliPrefab:WaitForChild("PSeat1"):Sit(self.Humanoid);
		self.PlayAnimation("Sit");
		
		local function initClientHeliScript(classPlayer)
			if classPlayer == nil then return end;
			
			local character = classPlayer.Character;
			local clientEffect = script.HelicopterEffect:Clone();
			local prefabTag = clientEffect:WaitForChild("Prefab");
			prefabTag.Value = self.Helicopter.Prefab;
			
			local isNetworkOwnerTag = clientEffect:WaitForChild("IsNetworkOwner");
			if self.NetworkOwners then
				for a=1, #self.NetworkOwners do
					if self.NetworkOwners[a] == classPlayer:GetInstance() then
						isNetworkOwnerTag = true;
						break;
					end
				end
			end
			
			clientEffect.Parent = character;
		end
		
		for _, player in pairs(game.Players:GetPlayers()) do
			initClientHeliScript(shared.modPlayers.Get(player));
		end
		
		self.Garbage:Tag(shared.modPlayers.OnPlayerSpawn:Connect(initClientHeliScript));
		
		self.Helicopter.GunmenSeats = {heliPrefab:WaitForChild("Stand1"); heliPrefab:WaitForChild("Stand2");};
		
		local gunmenSpawned = false;
		local gunmenModules = {};
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
						
						local deathDebounce = false;
						banditNpcModule.Humanoid.Died:Connect(function()
							if deathDebounce then return end deathDebounce = true;
							game.Debris:AddItem(banditNpc, 3);
							for a=#gunmenModules, 1, -1 do
								if gunmenModules[a] == banditNpcModule then
									table.remove(gunmenModules, a);
								end
							end
						end)
					
						-- Sit on heli;
						banditNpcModule.Seat = self.Helicopter.GunmenSeats[a];
					end, modBanditGunmen);
				end
			end
		end
		
		self.Helicopter.Move(self.Helicopter.Position + Vector3.new(0, self.Helicopter.Altitude, 200));
		
		
		self.ProjectileConfig = require(game.ReplicatedStorage.Library.Tools.molotov)();
		
		self.Helicopter.DropOrigins = {};
		for _, obj in pairs(heliBase:GetChildren()) do
			if obj.Name == "DropOrigin" then
				table.insert(self.Helicopter.DropOrigins, obj);
			end
		end
		
		self.Garbage:Tag(self.Humanoid.Died:Connect(function()
			self:KillNpc();
			for a=1, #gunmenModules do
				if gunmenModules[a] then
					if gunmenModules[a].Humanoid then gunmenModules[a].Humanoid.Health = 0; end
					game.Debris:AddItem(gunmenModules[a].Prefab, 0);
				end
			end
		end));
		
		for _, v in next, self.Prefab:GetDescendants() do
			if v:IsA("BasePart") then
				v.CollisionGroup = "CollisionOff";
			end
		end
		
		while not self.IsDead do
			if #gunmenModules > 0 then
				self.Immunity = 0.5;
				if not self.Helicopter.Animations.OpenDoors.IsPlaying then
					self.Helicopter.Animations.OpenDoors:Play();
				end
				
			else
				self.Immunity = nil;
				if self.Helicopter.Animations.OpenDoors.IsPlaying then
					self.Helicopter.Animations.OpenDoors:Stop();
				end
				
				if gunmenSpawned then
					self.State = "Molotov";
					gunmenSpawned = false;
					self.isCircling = false;
				end
			end
			
			if self.Update == nil or self.Update() == false then
				break;
				
			else
				self.HelicopterUpdate();
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
						projectileObject.TargetableEntities = {Humanoid=1;};
						projectileObject.NetworkOwners = self.NetworkOwners;
						if projectileObject.Prefab:CanSetNetworkOwnership() then projectileObject.Prefab:SetNetworkOwner(nil); end
						
						modProjectile.ServerSimulate(projectileObject, origin.p, origin.LookVector * 20, {workspace.Environment});
					end
					task.wait(0.15);
				end
			end)
			
			self.Helicopter.Move(self.Helicopter.Position + Vector3.new(-flybyDir.X, self.Helicopter.Altitude, -flybyDir.Z));
			if self.Helicopter.Animations.OpenDoors.IsPlaying then
				self.Helicopter.Animations.OpenDoors:Stop();
			end
			self.Helicopter.Speed = 50;
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
	
return self end