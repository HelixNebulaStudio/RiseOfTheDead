local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local TweenService = game:GetService("TweenService");
local RunService = game:GetService("RunService");

local ZombieModule = script.Parent.Zombie;
--== Modules
local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modProjectile = require(game.ReplicatedStorage.Library.Projectile);
local modInfoBubbles = require(game.ReplicatedStorage.Library.InfoBubbles);
local modArcTracing = require(game.ReplicatedStorage.Library.ArcTracing);

local goopTweenInfo = TweenInfo.new(1.66);
local goop = script:WaitForChild("Goop");

local growTweenInfo = TweenInfo.new(5);

local largeRootJoint = script:WaitForChild("LargeRootJoint");
local largePath = script:WaitForChild("LargePath");

return function(npc, spawnPoint)
	local self = modNpcComponent{
		Prefab = npc;
		Name = npc.Name;
		Head = npc:WaitForChild("Head");
		Humanoid = npc:WaitForChild("Zombie");
		RootPart = npc.PrimaryPart;
		SpawnPoint = spawnPoint; -- CFrame;
		
		Properties = {
			WalkSpeed = {Min=16; Max=18};
			AttackSpeed = 4;
			AttackDamage = 50;
			AttackRange = 14;
			
			TargetableDistance = 4096;
		};
		
		Configuration = {
			Level=1;
			MoneyReward={Min=1500; Max=1700};
			ExperiencePool=200;
			ResourceDrop=modRewardsLibrary:Find("pathoroth");
		};

		TrapTimer = tick();
		TrapCooldown = 5;
		
		MorphTimer = tick();
		MorphCooldown = 20;

		MorphTarget = nil;
		MorphAccessories = {};
	};
	
	--== Initialize;
	function self.Initialize()
		self.Prefab:SetAttribute("EntityHudHealth", true);
		if self.HardMode then
			self.TrapCooldown = 5;
		end
		self.HorrorParticle = self.RootPart:WaitForChild("HorrorParticle");
		
		self.Zombies = {};
		
		local throwGooSmallTrack = self.GetAnimation("ThrowGooSmall");
		local throwGooTrack = self.GetAnimation("ThrowGoo");
		
		local function throwGoo()
			local rightHand;
			for _, part in pairs(self.Prefab:GetChildren()) do
				if part.Name == "RightHand" then
					rightHand = part;
				end
				if part.Name == "RightHandL" then
					rightHand = part;
				end
			end

			if rightHand then
				local origin = rightHand.Position;
				local throwTarget = self.ThrowTarget;
				local targetPoint = throwTarget.Position;
				
				local travelTime = (origin-targetPoint).Magnitude/40;
				local projectileObject = modProjectile.Fire("SlowGoo", CFrame.new(origin));
				
				local velocity = projectileObject.ArcTracer:GetVelocityByTime(origin, targetPoint, travelTime);
				modProjectile.ServerSimulate(projectileObject, origin, velocity);
				
				function projectileObject.OnComplete()
					wait(1);
					local rSpawns = random:NextInteger(2, 3);
					if #self.Zombies < 16 then
						for a=1, rSpawns do

							local r = math.random(2, 4);
							self.NpcService.Spawn(self.IsLargePathoroth and "Heavy Zombie" or "Zombie", 
								CFrame.new(targetPoint), --Vector3.new(math.random(-r, r), 0, math.random(-r, r)) 
								function(npc, npcModule)
									npcModule.ForgetEnemies = false;
									npcModule.AutoSearch = true;
									npcModule.OnTarget(game.Players:GetPlayers());
									table.insert(self.Zombies, npc);

									if self.IsLargePathoroth then
										npcModule.Properties.WalkSpeed={Min=16; Max=18};
									end

									npcModule.Humanoid.Died:Connect(function()
										if self == nil then return end;
										for b=#self.Zombies, 1, -1 do
											if self.Zombies[b] == npc then
												table.remove(self.Zombies, b);
											end
										end
									end)
								end);
						end
					end
				end
				
			else
				Debugger:Log("No right hand;");
			end
		end
		
		throwGooTrack:GetMarkerReachedSignal("GooThrow"):Connect(throwGoo)
		throwGooSmallTrack:GetMarkerReachedSignal("GooThrow"):Connect(throwGoo)
		
		repeat until not self.Update();
		
		self.HorrorParticle.Enabled = false;
		
		wait(5);
	end
	
	--== Components;
	self:AddComponent("AntiSit");
	self:AddComponent("Movement");
	self:AddComponent("Logic");
	self:AddComponent("Follow");
	self:AddComponent("DropReward");
	self:AddComponent(ZombieModule.OnDeath);
	self:AddComponent(ZombieModule.BlobTrap);
	self:AddComponent(ZombieModule.HeavyAttack1);
	self:AddComponent(ZombieModule.OnHealthChanged);
	self:AddComponent(ZombieModule.OnTarget);
	
	--== NPC Logic;
	self.Logic:AddAction("ThrowSlowGoo", function()
		if tick()-self.TrapTimer > self.TrapCooldown then
			self.TrapTimer = tick();
			
			local targetHumanoid = self.Target and self.Target:FindFirstChildWhichIsA("Humanoid") or nil;
			local targetRootPart = self.Target and self.Target.PrimaryPart;

			if self.Target ~= nil and targetRootPart ~= nil and targetHumanoid.Health > 0 then
				local targetPosition = targetRootPart.Position;
				self.Humanoid.WalkSpeed = 0;
				wait(0.7);
				self.Movement:Face(targetPosition);
				wait(0.3);
				
				self.ThrowTarget = targetRootPart;
				
				if self.IsLargePathoroth then
					self.PlayAnimation("ThrowGoo");
				else
					self.PlayAnimation("ThrowGooSmall");
				end
				wait(1);
				self.Humanoid.WalkSpeed = 16;
			end
			
		end
	end);

	self.Logic:AddAction("Morph", function()
		if #self.Enemies > 0 and (self.MorphTarget == nil or tick()-self.MorphTimer > self.MorphCooldown) then
			self.Enemy = self.Enemies[math.random(1, #self.Enemies)];
			if self.Enemy and self.Enemy.Humanoid and self.Enemy.Humanoid.RootPart and self.Enemy.Humanoid.Health > 0 and self.Enemy.Character
				and self.MorphTarget ~= self.Enemy.Character then
				self.Morphing = true;
				self.MorphTarget = self.Enemy.Character;
				self.MorphTimer = tick();
				
				self.HorrorParticle.Enabled = true;
				
				self.Movement:EndMovement();
				self.Humanoid.WalkSpeed = 0;
				wait(0.2);
				local pos = self.RootPart.Position + Vector3.new(0, -2.2, 0);
				local new = goop:Clone();
				new:SetPrimaryPartCFrame(CFrame.new(pos));

				local goop1 = new:WaitForChild("goop1");
				local goop2 = new:WaitForChild("goop2");
				local goop3 = new:WaitForChild("goop3");
				local rootPos1 = goop1.Position;
				local rootPos2 = goop2.Position;
				local rootPos3 = goop3.Position;

				goop1.Position = goop1.Position + Vector3.new(0, -10, 0);
				goop2.Position = goop2.Position + Vector3.new(0, -10, 0);
				goop3.Position = goop3.Position + Vector3.new(0, -10, 0);

				new.Parent = self.Prefab;

				TweenService:Create(goop1, goopTweenInfo, {Position = rootPos1}):Play();
				wait(1.66);
				self.Humanoid.WalkSpeed = 0;
				TweenService:Create(goop2, goopTweenInfo, {Position = rootPos2}):Play();
				wait(1.66);
				self.Humanoid.WalkSpeed = 0;
				TweenService:Create(goop3, goopTweenInfo, {Position = rootPos3}):Play();
				wait(1.66);
				self.Humanoid.WalkSpeed = 0;

				for _, obj in pairs(self.Prefab:GetChildren()) do
					if obj:IsA("BasePart") then
						obj.Color = Color3.fromRGB(211, 190, 150);
					end
				end
				
				for a=1, #self.MorphAccessories do
					game.Debris:AddItem(self.MorphAccessories[a], 0);
				end
				self.MorphAccessories = {};
				wait(0.1);

				for _, obj in pairs(self.MorphTarget:GetChildren()) do
					if obj:IsA("Accessory") or obj:IsA("Shirt") or obj:IsA("Pants") then
						
						local clone = obj:Clone();
						for _, obj in pairs(clone:GetDescendants()) do
							if obj:IsA("JointInstance") then
								obj:Destroy();
							end
						end
						table.insert(self.MorphAccessories, clone);
						
					elseif obj:IsA("BasePart") then
						local part = self.Prefab:FindFirstChild(obj.Name);
						if part then
							part.Color =  obj.Color;
						end
						
					end
				end
				local face = self.MorphTarget:FindFirstChild("face", true);
				if face then table.insert(self.MorphAccessories , face:Clone()) end;

				for a=1, #self.MorphAccessories do
					if self.MorphAccessories[a].Name == "face" then
						game.Debris:AddItem(self.Prefab:FindFirstChild("face"), 0);
						self.MorphAccessories[a].Parent = self.Head;
						
					else
						game.Debris:AddItem(self.Prefab:FindFirstChild(self.MorphAccessories[a].Name), 0);
						self.MorphAccessories[a].Parent = self.Prefab;
						
					end
				end
				
				wait(1);
				
				self.Humanoid.WalkSpeed = 16;
				goop1.Anchored = false;
				goop2.Anchored = false;
				self.HorrorParticle.Enabled = false;
				
				goop3.Anchored = false;
				game.Debris:AddItem(new, 0.3);
				self.Morphing = false;
			end
		end
	end);
	
	self.Logic:AddAction("Attack", function(enemiod, position)
		if self.Properties.AttackCooldown == nil then self.Properties.AttackCooldown = tick(); end;
		if tick()-self.Properties.AttackCooldown > self.Properties.AttackSpeed then
			if position then self.Movement:Face(position) end;
			self.Properties.AttackCooldown = tick();
			self.HeavyAttack1(enemiod);
		end
	end);

	function self.OnDamaged(amount, character, weaponItem, bodyPart, damageType)
		if character == nil then return end;
		if self.Weapons == nil then self.Weapons = {} end;
		
		amount = amount and math.ceil(amount) or 0;
		if amount < 0 then return end
		
		if character and character.Name and character == game.Players:FindFirstChild(character.Name) then
			if self.Weapons[character.Name] == nil then self.Weapons[character.Name] = {} end;
			if weaponItem then
				if self.Weapons[character.Name][weaponItem.ID] == nil then self.Weapons[character.Name][weaponItem.ID] = {Damaged=0; Weapon=weaponItem} end;
				self.Weapons[character.Name][weaponItem.ID].Damaged = self.Weapons[character.Name][weaponItem.ID].Damaged + amount;
			end
		end
		
		if self.Enemies then
			for a=#self.Enemies, 1, -1 do
				if self.Enemies[a] and self.Enemies[a].Character and self.Enemies[a].Character.Name == character.Name then
					self.Enemies[a].DamageDealt = self.Enemies[a].DamageDealt + amount;
					break;
				end
			end
		end
		
		if self.OnTarget then self.OnTarget(character); end
		
		local player = game.Players:FindFirstChild(character.Name);
		
		if player and damageType ~= "Thorn" then
			local damagable = modDamagable.NewDamagable(character);
			if damagable and damagable.HealthObj and damagable.HealthObj.Health > 5 then
				
				local newDmgSrc = modDamagable.NewDamageSource{
					Damage=3;
					Dealer=self.Prefab;
					DamageType="Thorn";
				}
				damagable:TakeDamagePackage(newDmgSrc); -- damage player;
				
				if damagable.Object and damagable.Object.RootPart then
					modInfoBubbles.Create{
						Players={player};
						Position=damagable.Object.RootPart.Position;
						Type="Status";
						ValueString="Thorn!";
					};
				end
			end
		end
		----if self.MorphTarget and self.MorphTarget.Name == character.Name then
		----end
		--if amount > 0 then
		--else
		--	Debugger:Warn("Player (",character.Name,") dealt 0 damage with a (",weaponItem.ItemId,")");
		--end
	end
	
	function self.Update()
		if self == nil or self.IsDead or self.Humanoid.RootPart == nil then 
			
			if self and self.Zombies then
				for a=1, #self.Zombies do
					game.Debris:AddItem(self.Zombies[a], 0);
				end
			end
			if self and self.BlobTraps then
				for a=1, #self.BlobTraps do
					game.Debris:AddItem(self.BlobTraps[a], 0);
				end
			end
			if self then self.Morphing = false; end;
			
			return false
		end;
		
		self.Immunity = self.Morphing and 1 or math.clamp(#self.Zombies/20, 0, 1);
		
		self.Logic:Action("ThrowSlowGoo");

		local targetHumanoid = self.Target and self.Target:FindFirstChildWhichIsA("Humanoid") or nil;
		local targetRootPart = self.Target and self.Target.PrimaryPart;

		if not self.IsLargePathoroth then
			

			if self.Target ~= nil and targetRootPart ~= nil and targetHumanoid.Health > 0 then
				self.Follow(targetRootPart, 16);
				if self.Enemy.Distance <= self.Properties.AttackRange then
					self.Logic:Action("Attack", targetHumanoid, targetRootPart.CFrame.p);
				end
				
			else
				if self.LastFollowSet == nil or tick()-self.LastFollowSet >= 5 then
					self.LastFollowSet = tick();

					local npcModules = self.NpcService.NpcModules;
					self.Follow(npcModules[math.random(1, #npcModules)].Module.RootPart, 8);
				end
				
			end
			
			
			self.Logic:Action("Morph");
			task.wait(0.5);
		else
			if self.Target ~= nil and targetRootPart ~= nil and targetHumanoid.Health > 0 then
				self.Humanoid.WalkSpeed = 10;
				self.Follow(targetRootPart, 2);
				if self.Enemy.Distance <= self.Properties.AttackRange then
					self.Logic:Action("Attack", targetHumanoid, targetRootPart.CFrame.p);
				end
			end
			
			--self.Humanoid.Health = math.clamp(self.Humanoid.Health + 5, 0, self.Humanoid.MaxHealth);
		end

		task.wait(1);
		if self.Humanoid.Health < self.Humanoid.MaxHealth*0.5 and self.IsLargePathoroth ~= true then
			self.IsLargePathoroth = true;

			self.Immortal = 1;
			repeat
				wait(0.2);
			until not self.Morphing;
			if self == nil or self.IsDead or self.Humanoid.RootPart == nil then return end;
			
			for a=1, #self.MorphAccessories do
				game.Debris:AddItem(self.MorphAccessories[a], 0);
			end

			self.AnimationController:Stop("Running")
			self.AnimationController:Play("Transform", {Speed=0.25;});
			
			self.HorrorParticle.Enabled = true;
			self.HorrorParticle.Size = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 10),
				NumberSequenceKeypoint.new(1, 10)
			};
			
			local scaling1 = Instance.new("NumberValue");
			scaling1.Name = "BodyDepthScale";
			scaling1.Value = 1;
			scaling1.Parent = self.Humanoid;
			local scaling2 = Instance.new("NumberValue");
			scaling2.Name = "BodyHeightScale";
			scaling2.Value = 1;
			scaling2.Parent = self.Humanoid;
			local scaling3 = Instance.new("NumberValue");
			scaling3.Name = "BodyWidthScale";
			scaling3.Value = 1;
			scaling3.Parent = self.Humanoid;
			
			self.Movement:EndMovement();

			self.Movement:SetWalkSpeed("transform", 0, 5);
			
			self.Humanoid.WalkSpeed = 0;
			self.Humanoid.AutomaticScalingEnabled = true;
			
			local sBodyParts = {};
			for _, obj in pairs(self.Prefab:GetChildren()) do
				if obj:IsA("BasePart") then
					table.insert(sBodyParts, obj);
				end
			end
			TweenService:Create(scaling1, growTweenInfo, {Value = 2}):Play();
			TweenService:Create(scaling2, growTweenInfo, {Value = 2}):Play();
			TweenService:Create(scaling3, growTweenInfo, {Value = 2}):Play();
			wait(4);
			self.Immortal = nil;
			self.AnimationController:Stop("Transform")
			
			local new = largePath:Clone();
			local ltLarge = nil;
			local motor = {};
			local parts = {};
			
			for _, obj in pairs(new:GetDescendants()) do
				if obj:IsA("Motor") then
					table.insert(motor, obj);
					obj.Enabled = false;
					
				elseif obj:IsA("BasePart") then
					table.insert(parts, obj);
					
					if obj.Name == "LowerTorsoLargeL" then
						ltLarge = obj;
					end
				end
			end
			
			scaling1.Value = 1;
			scaling2.Value = 1;
			scaling3.Value = 1;
			self.Humanoid.HipHeight = 1.35;
			self.Humanoid.AutomaticScalingEnabled = false;
			
			for _, obj in pairs(parts) do
				obj.Parent = self.Prefab;
			end
			
			local newJoint = largeRootJoint:Clone();
			newJoint.Parent = self.RootPart;
			newJoint.Part0 = self.RootPart;
			newJoint.Part1 = ltLarge;
			
			for _, obj in pairs(parts) do
				obj.Parent = self.Prefab;
			end
			for _, obj in pairs(motor) do
				obj.Enabled = true;
			end
			for _, obj in pairs(sBodyParts) do
				obj.Transparency = 1;
				
				if obj.Name == "Head" then
					if obj:FindFirstChild("face") then
						obj.face.Transparency = 1;
					end
				end
			end

			self.SetAnimation("Core", {script:WaitForChild("Core")});
			self.SetAnimation("Running", {script:WaitForChild("Running")});
			self.PlayAnimation("Core");
			
			self.HorrorParticle.Transparency = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 0.75),
				NumberSequenceKeypoint.new(1, 1)
			};
			self.Humanoid.WalkSpeed = 10;
			self.Movement:SetWalkSpeed("transform", nil);
			self.Movement:SetWalkSpeed("default", 10);
		end

		return true;
	end
	
	--== Connections;
	self.Garbage:Tag(self.Humanoid.HealthChanged:Connect(self.OnHealthChanged));
	self.Humanoid.Died:Connect(self.OnDeath);
	
return self end
