local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local TweenService = game:GetService("TweenService");

local HumanModule = script.Parent.Human;
local ZombieModule = script.Parent.Zombie;
--== Modules Warn: Don't require(Npc)
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);
local modAoeHighlight = require(game.ReplicatedStorage.Particles.AoeHighlight);
local modProjectile = require(game.ReplicatedStorage.Library.Projectile);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);

local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.In, -1, true, 0);
local tweenInfo2 = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false);

return function(npc, spawnPoint)
	local self = modNpcComponent{
		Name = npc.Name;
		Prefab = npc;
		SpawnPoint = spawnPoint;
		Humanoid = npc:FindFirstChildWhichIsA("Humanoid");
		RootPart = npc.PrimaryPart;
		
		Properties = {
			WalkSpeed = {Min=10; Max=10};
			AttackSpeed = 1.5;
			AttackDamage = 45;
			AttackRange = 7;
			AttackCooldown = tick();
		};
		
		Configuration = {
			Level=1;
			MoneyReward={Min=4; Max=8};
			ExperiencePool=60;
		};
	};
	--== Initialize;
	function self.Initialize()
		self.Humanoid.WalkSpeed = 10;
		self.Humanoid.JumpPower = 50;

		self.GroundPunchRange = 50;
		
		self.GroundPunchCooldown = tick();
		self.RocketBarrageCooldown = tick();
		self.RocketBarrageDamage = 10;
		
		self.RocketField = {};
		
		self.RocketLaunchObjs = {};
		for _, obj in pairs(self.Prefab.Launchers:GetChildren()) do
			if obj.Name == "LaunchPoint" then
				table.insert(self.RocketLaunchObjs, obj);
			end
		end

		self.CustomHealthbar:Create("ImmunitySource", 50000, self.Prefab:WaitForChild("PowerSource"));
		
		self.Immunity = 1.7;
		self.WeakenImmunity = 1.35;
		self.DisabledImmunity = nil;
		
		function self.CustomHealthbar:OnDamaged(amount, fromPlayer, storageItem, bodyPart)
			if bodyPart == nil then return end;
			if bodyPart.Name == "PowerSource" then
				self:TakeDamage("ImmunitySource", amount);
				return true;
			end
		end

		self.CustomHealthbar.OnDeath:Connect(function(name, healthInfo)
			if name == "ImmunitySource" then
				self.Prefab.PowerSource.Color = Color3.fromRGB(50, 50, 50);
				self.Immunity = self.DisabledImmunity;
				self.RocketBarrageDamage = 25;
				self.StunTimer = 4;
				
			end
		end)
		
		self.StunTimer = 2;
		self.AutoSearch = true;
		self.SetAnimation("Stun", {game.ReplicatedStorage.Library.StatusEffects.Stun});
		
		repeat until not self.Update();
		
		wait(5);
	end
	
	--== Components;
	self:AddComponent("Follow");
	self:AddComponent("Movement");
	self:AddComponent("Wield");
	self:AddComponent("Logic");
	self:AddComponent("CrateReward");
	self:AddComponent("CustomHealthbar");
	self:AddComponent(ZombieModule.OnDeath);
	self:AddComponent(ZombieModule.OnDamaged);
	self:AddComponent(ZombieModule.OnHealthChanged);
	self:AddComponent(ZombieModule.BasicAttack1);
	self:AddComponent(ZombieModule.OnTarget);
	self:AddComponent(ZombieModule.Throw);
	
	--== NPC Logic;
	function self.Update()
		if self.IsDead then return false; end;
		--self.CustomHealthbar.Healths.ImmunitySource.IsDead
		
		if self.EntityStatus:GetOrDefault("ElectricMod") ~= nil then
			if self.Immunity and self.Immunity > self.WeakenImmunity then
				self.Immunity = self.WeakenImmunity;
			end
		end
		
		pcall(function()
			self.Prefab.PowerSource.StunEffect.Enabled = self.Stunned;
			self.Prefab.PowerSource.StunEffect2.Enabled = self.Stunned;
		end)
		
		if self.Stunned then
			wait(1);
			self.PlayAnimation("Stun");
			if self.LastStunnedTick == nil then
				self.LastStunnedTick = tick();
				
			elseif tick()-self.LastStunnedTick >= self.StunTimer then
				pcall(function()
					self.Prefab.PowerSource.StunEffect.Enabled = false;
					self.Prefab.PowerSource.StunEffect2.Enabled = false;
				end)
				self.Humanoid.WalkSpeed = 16;
				self.Stunned = false;
				self.LastStunnedTick = nil;
				
			end
			return true;
		end;
		self.StopAnimation("Stun");
		
		local rocketBarrageInterval = 10.5;
		local groundPunchInterval = 15;
		
		local rocketBarrageReady = tick()-self.RocketBarrageCooldown > rocketBarrageInterval;
		local groundPunch = tick()-self.GroundPunchCooldown > groundPunchInterval;
		
		
		if rocketBarrageReady and groundPunch then
			self.GroundPunchCooldown = tick();
			
			self.Humanoid.WalkSpeed = 0;
			self.Follow();
			self.CanBlink = false;
			wait(0.5);

			local groundCframe = modAoeHighlight:Ray(self.RootPart.Position, Vector3.new(0, -8, 0));
			
			if groundCframe then
				self.PlayAnimation("GroundPunch");
				
				local new = modAoeHighlight.newCylinder(2.3);
				new.CFrame = groundCframe
				new.Size = Vector3.new(2, 2, 1);
				new.Parent = workspace.Entities;

				TweenService:Create(new, tweenInfo2, {Size = Vector3.new(self.GroundPunchRange*2, self.GroundPunchRange*2, 1)}):Play();
				
				wait(2);
				if self.Enemies then
					for a=1, #self.Enemies do
						local enemyTable = self.Enemies[a];
						local humanoid = enemyTable.Humanoid;
						local rootpart = humanoid.RootPart;
						if rootpart and (rootpart.Position-self.RootPart.Position).Magnitude <= self.GroundPunchRange-1 and rootpart.Position.Y <= self.RootPart.Position.Y+2 then

							self.Throw(humanoid.Parent, 75, 50);
							local enemyPlayer = game.Players:FindFirstChild(humanoid.Parent.Name);
							if enemyPlayer then
								modStatusEffects.Stun(enemyPlayer, 3);
							end
							
						end
					end
					
					self.GroundPunchRange = self.GroundPunchRange + (#self.Enemies * 4);
				end
			end
			self.CanBlink = nil;
			wait(1);
		end
		
		if self.Stunned then return true; end;
		self.Humanoid.WalkSpeed = 10;
		if rocketBarrageReady then
			self.RocketBarrageCooldown = tick();
			
			self.Humanoid.WalkSpeed = 0;
			self.Follow();
			
			self.PlayAnimation("RocketBarrage");
			if self.Enemies then
				self.CanBlink = false;

				local rocketCount = 8;
				if self.Immunity and self.Immunity > 1 then
					rocketCount = 12;
				end

				for t=1, rocketCount do -- Learn rocket count
					if self.IsDead or self.Stunned then break; end;
					
					for a=1, #self.Enemies do
						if self.IsDead or self.Stunned then break; end;
						
						local enemyTable = self.Enemies[a];
						local humanoid = enemyTable.Humanoid;
						local rootpart = humanoid.RootPart;

						if rootpart then
							local positionRoundOff = Vector3.new(math.floor(rootpart.Position.X/5)*5, rootpart.Position.Y, math.floor(rootpart.Position.Z/5)*5);
							local posKey = positionRoundOff.X..","..positionRoundOff.Z;
							if self.RocketField[posKey] == nil or tick()-self.RocketField[posKey] >= 1 then

								local groundCframe = modAoeHighlight:Ray(positionRoundOff, Vector3.new(0, -8, 0));
								if groundCframe then
									local travelTime = 1;
									
									local new = modAoeHighlight.newCylinder(travelTime);
									new.CFrame = groundCframe
									new.Size = Vector3.new(2, 2, 1);
									new.Parent = workspace.Entities;

									TweenService:Create(new, tweenInfo, {Size = Vector3.new(32, 32, 1)}):Play();
									
									local rngRocket = self.RocketLaunchObjs[math.random(1,#self.RocketLaunchObjs)].WorldPosition;
									local origin = rngRocket;
									local targetPoint = groundCframe.p;

									local projectileObject = modProjectile.Fire("zomborgRocket", CFrame.new(origin));
									projectileObject.Owner = self.Prefab;
									projectileObject.Damage = self.RocketBarrageDamage;

									local velocity = projectileObject.ArcTracer:GetVelocityByTime(origin, targetPoint, travelTime);
									modProjectile.ServerSimulate(projectileObject, origin, velocity);
								end
							end
						end
					end
					wait(0.5);
				end
			end
			self.StopAnimation("RocketBarrage");
			self.CanBlink = nil;
		end
		
		
		if self.Stunned then return true; end;
		self.Humanoid.WalkSpeed = 10;

		local targetHumanoid = self.Enemy and self.Enemy.Humanoid or nil;
		local targetRootPart = self.Enemy and self.Enemy.RootPart;
		if self.Enemy ~= nil and targetRootPart ~= nil and targetHumanoid.Health > 0 then
			self.Follow(targetRootPart, 1);

			local targetPlayer = game.Players:GetPlayerFromCharacter(self.Enemy.Character);
			if targetPlayer then
				self.Enemy.Distance = targetPlayer:DistanceFromCharacter(self.RootPart.Position);
				if self.Enemy.Distance < self.Properties.AttackRange then
					if tick()-self.Properties.AttackCooldown > self.Properties.AttackSpeed then
						self.Properties.AttackCooldown = tick();
						self.BasicAttack1(targetHumanoid);
					end
				end
			end
			
		else
			self.Follow();
		end
		
		
		wait(0.1);
		return true;
	end
	
	--== Connections;
	self.Humanoid.HealthChanged:Connect(self.OnHealthChanged);
	
return self end
