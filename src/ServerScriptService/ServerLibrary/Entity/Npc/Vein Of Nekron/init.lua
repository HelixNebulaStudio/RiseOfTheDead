local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();

local ZombieModule = script.Parent.Zombie;
--== Modules Warn: Don't require(Npc)

local modNpcComponent = require(game.ServerScriptService.ServerLibrary.Entity.NpcComponent);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);

local modNekronSpore = require(script:WaitForChild("NekronSpore"));

local veinPrefab = script:WaitForChild("Vein");
local moldTexture = script:WaitForChild("Mold");

local overlapParams = OverlapParams.new();
overlapParams.MaxParts = 64;
overlapParams.FilterType = Enum.RaycastFilterType.Include;
overlapParams.FilterDescendantsInstances = {workspace.Environment:FindFirstChild("Scene")};


local rayParam = RaycastParams.new();
rayParam.FilterType = Enum.RaycastFilterType.Include;
rayParam.IgnoreWater = true;
rayParam.CollisionGroup = "Raycast";
rayParam.FilterDescendantsInstances = {workspace.Environment:FindFirstChild("Scene");};

return function(npc, spawnPoint)
	local self = modNpcComponent{
		Name = npc.Name;
		Prefab = npc;
		SpawnPoint = spawnPoint;
		Humanoid = npc:FindFirstChildWhichIsA("Humanoid");
		RootPart = npc.PrimaryPart;
		
		Properties = {
			WalkSpeed = {Min=5; Max=5};
		};
		
		Configuration = {
			Level=1;
			MoneyReward={Min=3000; Max=4500};
			ExperiencePool=1000;
		};
		
		FullHealOnSpawn = false;
		DespawnPrefab = 30;
	};
	
	
	--== Initialize;
	function self.Initialize()
		
		self.TaggedObjects = {};
		self.SporeObjects = {};
		self.PlaqueObjects = {};

		self.SporeCount = 0;
		self.VeinLaunched = 0;
		self.AttackTimer = (self.IsHard and 3 or 4);
		
		self.LastVeinSpawn = tick();
		self.LastHeal = tick();


		self.BaseHealth = self.Humanoid.Health;
		self.BaseMaxHealth = self.Humanoid.MaxHealth;

		self.Humanoid.MaxHealth = self.BaseHealth;
		self.RootPart.CanCollide = false;

		function self.CustomHealthbar.OnDamaged(healthObj, amount, fromPlayer, storageItem, bodyPart)
			if bodyPart == nil then return end;
			
			local bodyPartName = bodyPart.Name;
			if bodyPart.Name:match("Nekros Vein") then
				bodyPartName = "Nekros Vein";
				
			elseif bodyPart.Name:match("Nekros Spore") then
				bodyPartName = "Nekros Spore";

			elseif bodyPart.Name:match("Nekros Plaque") then
				bodyPartName = "Nekros Plaque";

			end
			
			if self.StatusLogicIsOnFire() then
				amount = amount *2;
			end
			
			if bodyPartName == "Nekros Plaque" then
				healthObj:TakeDamage(bodyPart.Name, amount);
				
			elseif bodyPartName == "Nekros Spore" then
				healthObj:TakeDamage(bodyPart.Name, amount);
				
			elseif bodyPartName == "Nekros Vein" then
				healthObj:TakeDamage(bodyPart.Name, amount);
				
			end
		end
		
		
		self.CustomHealthbar.OnDeath:Connect(function(name, healthInfo)
			local part = healthInfo.BasePart;
			
			if healthInfo.BasePart == nil then return end;
			
			if name:match("Nekros Vein") then
				local projectile = healthInfo.ProjectileObject;
				if projectile then
					game.Debris:AddItem(projectile.Prefab, 0);
					projectile:Destroy();
				end
				
				if healthInfo.SporeObject then
					self.CustomHealthbar:TakeDamage(healthInfo.SporeObject.Name, self.BaseHealth*0.1);
				end
				
			elseif name:match("Nekros Spore") then
				local amount = self.BaseHealth * 0.15;
				if self.StatusLogicIsOnFire() then
					amount = amount *2;
				end

				self.Status:TakeDamagePackage(modDamagable.NewDamageSource{
					Damage=amount;
					TargetPart=self.RootPart;
				});
				
			elseif name:match("Nekros Plaque") then --Nekros Plaque
				game.Debris:AddItem(healthInfo.BasePart, 2);
				healthInfo.BasePart.Color = Color3.fromRGB(48, 30, 30);
				modAudio.Play("NekronHurt", healthInfo.BasePart).PlaybackSpeed = random:NextNumber(0.5, 0.6);
				
				local amount = self.BaseHealth *0.35;
				if self.StatusLogicIsOnFire() then
					amount = amount *2;
				end
				
				self.Status:TakeDamagePackage(modDamagable.NewDamageSource{
					Damage=amount;
					TargetPart=self.RootPart;
				});
				
			end
		end)
		
		repeat until not self.Update();
		
		-- IS DEAD
		
		for a=#self.TaggedObjects, 1, -1 do
			local part = self.TaggedObjects[a];
			pcall(function()
				if part and part:GetAttribute("VeinOfNekronInfected") then
					for _, obj in pairs(part:GetChildren()) do
						if obj.Name == "VeinOfNekronSpread" then
							obj:Destroy();
							
						end
					end
					
					part:SetAttribute("VeinOfNekronInfected", nil);
					part:SetAttribute("RootVeinOfNekron", nil);
				end
			end)
			self.TaggedObjects[a] = nil;
			
			if math.fmod(a, 10) == 0 then
				task.wait();
			end
		end
		table.clear(self.TaggedObjects);
		
		for a=1, #self.SporeObjects do
			if self.SporeObjects[a] then
				self.SporeObjects[a].Cancelled = true;
			end
		end
		table.clear(self.SporeObjects);
		table.clear(self.PlaqueObjects);
	end
	
	--== Components;
	self:AddComponent("CustomHealthbar");
	self:AddComponent("CrateReward");
	self:AddComponent(ZombieModule.OnDeath);
	self:AddComponent(ZombieModule.OnHealthChanged);
	self:AddComponent(ZombieModule.OnDamaged);
	self:AddComponent(ZombieModule.OnTarget);
	
	local function spread(part)
		if self.IsDead then return; end;
		if part.Anchored == false then return end;
		if part:GetAttribute("VeinOfNekronInfected") then return end
		if part.Size.Magnitude >= 200 then return end;
		
		part:SetAttribute("VeinOfNekronInfected", tick());
		table.insert(self.TaggedObjects, part);
		
		if #self.TaggedObjects >= 16 then
			local part = table.remove(self.TaggedObjects, 1)
			if part and part:GetAttribute("VeinOfNekronInfected") then
				for _, obj in pairs(part:GetChildren()) do
					if obj.Name == "VeinOfNekronSpread" then
						obj:Destroy();
						
					end
				end
				
				part:SetAttribute("VeinOfNekronInfected", nil);
				part:SetAttribute("RootVeinOfNekron", nil);
			end
		end
		
		local size = part.Size.Magnitude;
		
		for _, side in pairs(Enum.NormalId:GetEnumItems()) do
			local newTexture = moldTexture:Clone();
			newTexture.Name = "VeinOfNekronSpread";
			
			newTexture.Face = side;
			newTexture.Parent = part;
			
			task.spawn(function()
				for t=1, 0.35, -((1-0.35)/10) do
					newTexture.Transparency = t;
					task.wait(size/100);
					if self.IsDead then break end;
				end
			end)
			
			game.Debris:AddItem(newTexture, 300);
		end
		
		local timelapsed = (tick()-self.SpawnTime);
		if timelapsed <= 10 then return end;
		if part.ClassName == "Part" and part.Shape == Enum.PartType.Block and size >= 5 then
			local axis = {Vector3.xAxis; Vector3.zAxis; -Vector3.xAxis; -Vector3.zAxis; Vector3.yAxis;}; ---Vector3.yAxis;
			
			for p=1, #axis do
				local randomAxis = axis[p];
				
				local surfaceSize;
				
				if randomAxis.X ~= 0 then
					surfaceSize = Vector3.new(part.Size.Z, part.Size.Y, 0);
					
				elseif randomAxis.Y ~= 0 then
					surfaceSize = Vector3.new(part.Size.Z, part.Size.X, 0);
					
				elseif randomAxis.Z ~= 0 then
					surfaceSize = Vector3.new(part.Size.X, part.Size.Y, 0);
					
				end
				
				local ratio = math.max(surfaceSize.X/surfaceSize.Y, surfaceSize.Y/surfaceSize.X);
				
				if ratio <= 4 and size >= 7 and surfaceSize.X >= 4 and surfaceSize.Y >= 4 then
					-- pick this randomAxis;

					local visibleRayParam = RaycastParams.new();
					visibleRayParam.FilterType = Enum.RaycastFilterType.Include;
					visibleRayParam.FilterDescendantsInstances = {workspace.Environment;};
					
					local rngCFrame = part.CFrame * CFrame.new(part.Size/2 * randomAxis);
					local surfaceCenterCFrame = CFrame.lookAt(rngCFrame.p, 
						(rngCFrame * CFrame.new(randomAxis*100)).Position, rngCFrame.UpVector);
					
					local lookVec = surfaceCenterCFrame.LookVector;
					local raycastResult = workspace:Raycast(surfaceCenterCFrame.p, lookVec*4, visibleRayParam);
					
					if raycastResult then
					else
						local zSize = math.clamp((surfaceSize.X+surfaceSize.Y)/20, 1, 10);
						
						self.VeinLaunched = self.VeinLaunched +1;
						
						local projectileName = "Nekros Plaque"..self.VeinLaunched;
						local newVein = veinPrefab:Clone();
						newVein.Name = projectileName;
						newVein.Parent = self.Prefab;
						newVein.CFrame = surfaceCenterCFrame * CFrame.new(lookVec);
						newVein.Size = surfaceSize;
						table.insert(self.PlaqueObjects, newVein);

						self.CustomHealthbar:Create(projectileName, self.BaseHealth*0.1, newVein);
						
						task.spawn(function()
							local step = 0.1;
							local t = size/10 * step;
							
							local oCf = newVein.CFrame;
							local eSize = surfaceSize + Vector3.new(0, 0, zSize);
							for a=0, 1, step do
								newVein.CFrame = oCf:Lerp(surfaceCenterCFrame, a);
								newVein.Size = surfaceSize:Lerp(eSize, a);
								if self.IsDead then return end;
								task.wait(t)
							end
						end)
						
					end
					
					break;
				end
			end
		end
		
	end
	
	
	function self.Strike(targetPart)
		if self.IsDead then return; end;
		local targetPoint = targetPart.Position;
		local raycastResult;
		
		local attackDirection = (tick()-self.LastVeinSpawn) < 5 and -1 or 1;
		
		for a=1, 16 do
			local aimPoint = CFrame.new(targetPoint) 
				* CFrame.Angles(0, math.rad(math.random(1, 360)), 0)
				* CFrame.Angles(math.rad(attackDirection * math.random(30, 50)), 0, 0) 
				* CFrame.new(0, 0, 4096);
			
			local aimDir = (aimPoint.p-targetPoint).Unit;
			raycastResult = workspace:Raycast(targetPoint, aimDir*256, rayParam);
			
			task.wait();
			if raycastResult then
				break;
			end
		end
		
		local incubateTime = math.clamp(5 - (tick()-self.SpawnTime)/60, self.IsHard and 2 or 3, 5);
		
		if raycastResult then
			local hitPart = raycastResult.Instance;
			local attackOrigin = raycastResult.Position;
			
			self.LastVeinSpawn = tick();
			spread(hitPart);
			self.SporeCount = self.SporeCount +1;

			local timelapsed = (tick()-self.SpawnTime);
			
			local nekronSporeObject = modNekronSpore.Spawn(attackOrigin, targetPart, self.Prefab, {
				IncubationTime=incubateTime;
				NekronSpreadFunc=spread;
				HostNpcModule=self;
			})
			
			table.insert(self.SporeObjects, nekronSporeObject);
			
			local newSpore = nekronSporeObject.Prefab;
			local newHealthObj = self.CustomHealthbar:Create(newSpore.Name, self.BaseHealth*0.1, newSpore);
			
			if newHealthObj then
				newHealthObj.OnDeath:Connect(function()
					game.Debris:AddItem(newHealthObj.BasePart, 2);
					
					nekronSporeObject.Cancelled = true;
					
					if newHealthObj.BasePart == nil then return end;
					newHealthObj.BasePart.Color = Color3.fromRGB(48, 30, 30);
					modAudio.Play("TicksZombieExplode", newHealthObj.BasePart).PlaybackSpeed = random:NextNumber(0.5, 0.6);
				end)
			end
		end
	end
	
	--== NPC Logic;
	local attackCooldown = tick()-6;
	function self.Update()
		if self.IsDead then return false; end;
		
		if #self.Enemies >= 1 then
			self.Enemy = self.Enemies[math.random(1, #self.Enemies)];
			
			local targetHumanoid = self.Enemy and self.Enemy.Humanoid or nil;
			local targetRootPart = self.Enemy and self.Enemy.RootPart;
			
			
			if targetRootPart and targetHumanoid and targetHumanoid.Health > 0 then
				self.AttackTimer = math.clamp(self.AttackTimer - (1/600), 2, 4);
				if tick()-attackCooldown >= self.AttackTimer then
					attackCooldown = tick();
					
					self.Strike(targetRootPart);
				end
			end
		end
		
		local timelapsed = (tick()-self.SpawnTime);
		local effectiveness = 0;
		
		if timelapsed <= 5 then
			effectiveness = timelapsed/5;
		elseif timelapsed <= 10 then
			effectiveness = 1 + timelapsed/10;
		elseif timelapsed <= 25 then
			effectiveness = 1 + (40-(timelapsed-25))/15;
		else
			effectiveness = math.clamp(effectiveness-(1/600), 0, 2);
		end
		
		local toxicStatus = self.EntityStatus:GetOrDefault("ToxicMod");
		
		local randomPlaquePart = nil;
		if #self.PlaqueObjects > 0 then
			randomPlaquePart = self.PlaqueObjects[math.random(1, #self.PlaqueObjects)];
		end
		if randomPlaquePart == nil then
			randomPlaquePart = self.RootPart;
		end

		if effectiveness > 0 then
			local addNewHealth = math.ceil(self.BaseHealth *0.02 * effectiveness);
			self.Humanoid.MaxHealth = math.clamp(self.Humanoid.MaxHealth + addNewHealth , self.BaseHealth, self.BaseMaxHealth);
			
			if toxicStatus then
				addNewHealth = addNewHealth * 0.5;
			end

			local newHealSrc = modDamagable.NewDamageSource{
				Damage=-addNewHealth;
				TargetPart=randomPlaquePart;
			};
			self.Status:TakeDamagePackage(newHealSrc);
			
		end
		
		if #self.TaggedObjects > 0 then
			if tick()-self.LastHeal >= 0.5 then
				self.LastHeal = tick();
				
				local healAmt = -math.ceil(#self.TaggedObjects * 500);
				
				if toxicStatus then
					local ratio = math.clamp(1 - (toxicStatus or 0) , 0, 1);
					healAmt = healAmt * ratio;
				end
				
				local newHealSrc = modDamagable.NewDamageSource{
					Damage=healAmt;
					TargetPart=randomPlaquePart;
				}
				self.Status:TakeDamagePackage(newHealSrc);
				
			end
		end
		
		task.wait(0.1);
		return true;
	end
	
	--== Connections;
	self.Humanoid.HealthChanged:Connect(self.OnHealthChanged);
	self.Humanoid.Died:Connect(self.OnDeath);
	
return self end
