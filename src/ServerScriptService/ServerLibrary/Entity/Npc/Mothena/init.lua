local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local remotes = game.ReplicatedStorage.Remotes;
local remoteCameraShakeAndZoom = remotes.CameraShakeAndZoom;

local RunService = game:GetService("RunService");

local ZombieModule = script.Parent.Zombie;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modExperience = require(game.ServerScriptService.ServerLibrary.Experience);
local modProjectile = require(game.ReplicatedStorage.Library.Projectile);

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
			AttackDamage = 50;
			AttackRange = 20;
			
			--TargetableDistance = 4096;
		};
		
		Configuration = {
			Level=1;
			MoneyReward={Min=4800; Max=5200};
			ExperiencePool=1000;
		};
		DespawnPrefab = 30;
	};
	
	--== Initialize;
	self:SetClientScript(script:WaitForChild("MothenaEffect"));
	
	function self.Initialize()
		self.CustomHealthbar:Create("Left Wing", 50000, self.Prefab:WaitForChild("LeftWing"));
		self.CustomHealthbar:Create("Right Wing", 50000, self.Prefab:WaitForChild("RightWing"));
		
		function self.CustomHealthbar:OnDamaged(amount, fromPlayer, storageItem, bodyPart)
			if bodyPart == nil then return end;
			if bodyPart.Name == "LeftWing" then
				self:TakeDamage("Left Wing", amount);
				
			elseif bodyPart.Name == "RightWing" then
				self:TakeDamage("Right Wing", amount);

			elseif bodyPart.Name:match("PoisonIvy") then
				self:TakeDamage(bodyPart.Name, amount);

			end
		end
		
		local moveFreq = 50;
		
		self.CustomHealthbar.OnDeath:Connect(function(name, healthInfo)
			if name == "Left Wing" then
				self.Prefab.LeftWing.Color = Color3.fromRGB(50, 50, 50);
				moveFreq = moveFreq - 20;
				
			elseif name == "Right Wing" then
				self.Prefab.RightWing.Color = Color3.fromRGB(50, 50, 50);
				moveFreq = moveFreq - 20;
				
			elseif name:match("PoisonIvy") then
				if self.Prefab:FindFirstChild(name) then
					self.Prefab[name]:Destroy();
				end
				
			end
		end)
		
		self.LevelVisuals();

		self.BodyPosition = self.RootPart:WaitForChild("BodyPosition");
		self.BodyGyro = self.RootPart:WaitForChild("BodyGyro");
		self.Garbage:Tag(self.BodyPosition);
		self.Garbage:Tag(self.BodyGyro);

		local initT = math.floor(tick());
		local seed = 0.12345;
		local offset = Vector3.new();
		
		self.HoverPosition = Vector3.new(0, 32, 0);

		self.Garbage:Tag(RunService.Stepped:Connect(function(delta)
			for _, v in next, self.Prefab:GetDescendants() do
				if v:IsA("BasePart") then
					v.CanCollide = false;
				end
			end
			-------
			
			local dir = (self.HoverPosition-self.BodyPosition.Position).Unit;
			local rotY = 0;
			
			local targetHumanoid = self.Enemy and self.Enemy.Humanoid or nil;
			local targetRootPart = self.Enemy and self.Enemy.RootPart;
			if targetRootPart ~= nil then
				local tagetDir = (targetRootPart.Position-self.BodyPosition.Position).Unit;
				rotY = math.atan2(tagetDir.Z, -tagetDir.X)+math.pi/2;
			else
				rotY = 0;
			end
			
			local midAng, maxAng = math.rad(-90), math.rad(90);
			local rotZ = -math.clamp(math.atan(dir.Z)/2, midAng, maxAng);
			local rotX = math.clamp(math.atan(dir.X)/2, midAng, maxAng);
			self.BodyGyro.CFrame = CFrame.Angles(rotZ, 0, rotX) * CFrame.Angles(0, rotY, 0);
			--pitch, yaw, roll
			
			local t = tick()-initT;
			offset = Vector3.new(
				math.noise(seed, t, 1)*moveFreq, 
				(math.noise(seed, t, 2)+0.5)*moveFreq, 
				math.noise(seed, t, 3)*moveFreq
			);
			self.BodyPosition.Position = self.HoverPosition + offset;
			self.BodyPosition.P = self.EntityStatus:GetOrDefault("FrostMod") and 4000 or 11000;
		end))
		
		self.State = "Follow";
		
		self.PoisonCooldown = tick();
		
		if self.HardMode then
			
		else
			for _, obj in pairs(self.Prefab:GetChildren()) do
				if obj:IsA("BasePart") and obj.Material == Enum.Material.Foil then
					obj.Material = Enum.Material.Sand;
					obj.Color = Color3.fromRGB(90, 76, 66);
				end
			end
		end
		
		repeat until not self.Update();
		
		wait(5);
	end
	
	--== Components;
	self:AddComponent("AntiSit");
	self:AddComponent("CustomHealthbar");
	self:AddComponent("Logic");
	self:AddComponent("CrateReward");
	self:AddComponent(ZombieModule.OnDeath);
	self:AddComponent(ZombieModule.OnHealthChanged);
	self:AddComponent(ZombieModule.OnDamaged);
	self:AddComponent(ZombieModule.OnTarget);
	self:AddComponent(ZombieModule.LevelVisuals);
	
	
	--== NPC Logic;
	self.IvyLaunched = 0;
	function self.Update()
		if self.IsDead or self.Humanoid.RootPart == nil then return false; end;

		local frostStatus = self.EntityStatus:GetOrDefault("FrostMod");
		
		if self.State == "Follow" then
			if #self.Enemies > 1 then
				local pos = Vector3.new();
				local enemiesCount = 0;
				for a=1, #self.Enemies do
					local rootPart = self.Enemies[a] and self.Enemies[a].Humanoid and self.Enemies[a].Humanoid.Health > 0 and self.Enemies[a].Humanoid.RootPart;
					if rootPart then
						pos = pos + rootPart.Position;
						enemiesCount = enemiesCount +1;
					end
				end
				local surroundPos = (pos/enemiesCount) + Vector3.new(0, frostStatus and 10 or 26, 0);
				self.HoverPosition = Vector3.new(
					math.clamp(surroundPos.X, spawnPoint.p.X-256, spawnPoint.p.X+256),
					math.clamp(surroundPos.Y, 50, 256),
					math.clamp(surroundPos.Z, spawnPoint.p.Z-256, spawnPoint.p.Z+256)
				);
			else
				local targetHumanoid = self.Enemy and self.Enemy.Humanoid or nil;
				local targetRootPart = self.Enemy and self.Enemy.RootPart;
				if targetRootPart ~= nil then
					local surroundPos = targetRootPart.Position + Vector3.new(0, frostStatus and 10 or 26, 0);
					self.HoverPosition = Vector3.new(
						math.clamp(surroundPos.X, spawnPoint.p.X-256, spawnPoint.p.X+256),
						math.clamp(surroundPos.Y, 50, 256),
						math.clamp(surroundPos.Z, spawnPoint.p.Z-256, spawnPoint.p.Z+256)
					);
				end
			end
			if tick()-self.PoisonCooldown > (frostStatus and 8 or 5) then
				self.State = "Poison";
			end
			
		elseif self.State == "Poison" then
			local launchOrigin = self.Prefab:FindFirstChild("PoisonLaunchOrigin", true);
			
			if launchOrigin then
				
				for a=1, 6 do
					if self.Enemies then
						local randomEnemy = self.Enemies[random:NextInteger(1, #self.Enemies)];
						local rootPart = randomEnemy and randomEnemy.Humanoid and randomEnemy.Humanoid.Health > 0 and randomEnemy.Humanoid.RootPart;
						if rootPart then
							local origin = launchOrigin.WorldPosition;
							local targetPoint = rootPart.Position;
							
							local projectileObject = modProjectile.Fire("PoisonIvy", CFrame.new(origin));
							local velocity = projectileObject.ArcTracer:GetVelocityByTime(origin, targetPoint, 0.5);
							modProjectile.ServerSimulate(projectileObject, origin, velocity, {workspace.Environment});
							projectileObject.Prefab.Parent = self.Prefab;
							
							self.IvyLaunched = self.IvyLaunched +1;
							local projectileName = "PoisonIvy"..self.IvyLaunched;
							projectileObject.Prefab.Name = projectileName;
							self.CustomHealthbar:Create(projectileName, 300, projectileObject.Prefab);
						end
					end
					wait(0.5);
				end
				
			end
			
			self.PoisonCooldown = tick();
			self.State = "Follow";
		end

		self.NextTarget();
		self.Logic:Wait(1);
		return true;
	end
	
	--== Connections;
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	self.Humanoid.Died:Connect(self.OnDeath);
	
return self end
