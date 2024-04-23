local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Pool = {};
Pool.__index = Pool;
--== Variables;
local RunService = game:GetService("RunService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modInfoBubbles = require(game.ReplicatedStorage.Library.InfoBubbles);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local modRope = require(game.ReplicatedStorage.Library.Rope);

local Projectile = require(script.Parent.Projectile);

local projectilePrefab = script.Projectile;
local veinLink = script.VeinLink;

local random = Random.new();


--== Script;
function Pool.new(owner)
	local projectile = setmetatable({}, Projectile);
	projectile.Owner = nil;
	projectile.Prefab = projectilePrefab:Clone();

	projectile.ArcTracerConfig = {
		Velocity=100;
		LifeTime=30;
		Bounce=0;
		Acceleration=Vector3.new(0, 0, 0);
		IgnoreEntities=true;
		RayRadius=0.5;
		Delta=1/2;
	};
	
	function projectile:Load()
	end
	
	local linkObjects = {};
	function projectile:Destroy()
		Debugger.Expire(self.Prefab, 0);
		self.Host = nil;
		
		if not RunService:IsServer() then return end;
		if self.Destroyed then return end;
		self.Destroyed = true;
		
		self.Rope:Destroy();
		
		task.spawn(function()
			for a=1, #linkObjects do
				game.Debris:AddItem(linkObjects[a], 5);
				linkObjects[a].Color = Color3.fromRGB(48, 30, 30);
				linkObjects[a].Anchored = false;
				if linkObjects[a]:FindFirstChild("CollisionShape") then
					linkObjects[a].CollisionShape.CanCollide = true;
				end
				linkObjects[a] = nil;
			end
			linkObjects = {};
		end)
		
		self.OnContact = nil;
		self.OnStepped = nil;
		self.OnNewVein = nil;
		self.Rope = nil;
	end
	
	local originPoint, projectilePoint, prevStick, origin;
	function projectile:Activate()
		if not RunService:IsServer() then return end;
		if self.Destroyed then return end;
		
		-- On Launch;
		local prefab = projectile.Prefab;
		origin = prefab.Position;
		
		self.Rope = modRope.new();
		self.Rope.Cycles = 2;
		self.Rope.GravitationalForce = Vector3.new(0, -workspace.Gravity/5, 0) * 1/900;
		self.Rope:Run();
		
		originPoint = self.Rope:NewPoint(origin, true);
		
		projectilePoint = self.Rope:NewPoint(prefab.Position, true);
		projectilePoint.Object = prefab;
		
		prevStick = self.Rope:NewStick(projectilePoint, originPoint, 9);
		local newLink = veinLink:Clone();
			
		function prevStick:Update()
			local center = (self.PointA.Position+self.PointB.Position)/2;
			newLink.CFrame = CFrame.lookAt(center, self.PointB.Position) * CFrame.Angles(math.rad(90), 0, 0);
		end
		prevStick:Update();
		newLink.Parent = prefab.Parent;
		table.insert(linkObjects, newLink);
		
		if self.OnNewVein then
			self:OnNewVein(newLink);
		end
	end	
	
	local distlapsed = 0;
	local size = 10;
	local arcContacted = false;
	
	function projectile:OnStepped(arcPoint)
		if prevStick == nil then return end;
		if self.Destroyed then return end;
		if arcContacted then return end
		if #linkObjects > 16 then
			self:Destroy();
			return 
		end;
		
		distlapsed = distlapsed + arcPoint.Displacement;
		
		local segments = math.ceil(distlapsed/size);
		if segments < 1 then return; end
		
		distlapsed = distlapsed - segments*size;
		
		-- new segments needed;
		for a=1, segments do
			local newStick = self.Rope:NewStick(self.Rope:NewPoint(origin), originPoint, 9);
			if newStick == nil then return end;
			
			prevStick.Length = 9;
			prevStick.PointB = newStick.PointA;
			
			local newLink = veinLink:Clone();
			function newStick:Update()
				local center = (self.PointA.Position+self.PointB.Position)/2;
				newLink.CFrame = CFrame.lookAt(center, self.PointB.Position) * CFrame.Angles(math.rad(90), 0, 0);
			end
			newStick:Update();
			newLink.Parent = projectile.Prefab.Parent;
			table.insert(linkObjects, newLink);
			
			if self.OnNewVein then
				self:OnNewVein(newLink);
			end
			
			prevStick = newStick;
		end
		
	end
	
	projectile.TargetableEntities = {
		Humanoid = 1;
	}
	
	local hitOnce = {};
	local activated = false;
	function projectile:OnContact(arcPoint)
		if arcPoint.Hit == nil then return end;
		if self.Destroyed then return end;
		
		if not RunService:IsServer() then return end;
		
		arcContacted = true;
		game.Debris:AddItem(self.Prefab, 0);
		
		task.delay(30, function()
			self:Destroy();
		end)
		
		self.Prefab.CFrame = CFrame.new(arcPoint.Point, arcPoint.Point+arcPoint.Direction-arcPoint.Normal);
		
		if projectilePoint then
			projectilePoint.Object = nil;
			projectilePoint.Position = arcPoint.Point;
		end
		
		if self.Prefab:CanSetNetworkOwnership() then self.Prefab:SetNetworkOwner(nil) end;
		if activated then return end;
		
		local hitObj = arcPoint.Hit;

		local damagable = modDamagable.NewDamagable(hitObj.Parent);
		if damagable then
			local model = damagable.Model;
			local damagableObj = damagable.Object;
			
			local damage = math.clamp((self.Damage or 100), 1, math.huge);
			
			if damagableObj.ClassName == "NpcStatus" then
				local dmgMulti = self.TargetableEntities[damagableObj.Name];
				if dmgMulti then
					damage = damage * dmgMulti;
				else
					damage = 0;
				end
				
			end
			
			if damage ~= 0 then
				activated = true;
				
				local healthObj = damagable:GetHealthInfo();
				
				local player = game.Players:GetPlayerFromCharacter(model);
				if player and self.OnPlayerStrike then -- healthObj.Armor <= 0 and
					local trapPlayer = self.OnPlayerStrike(player, model);
					if trapPlayer then
						self.Rope.Locked = false;
						projectilePoint.Object = model.HumanoidRootPart;
						for a=1, #linkObjects do
							if linkObjects[a]:FindFirstChild("CollisionShape") then
								linkObjects[a].CollisionShape.CanCollide = false;
							end
						end
					end
					
				else
					self:Destroy();
					if self.Host then
						self.Host:DamageTarget(model, damage);
						
					else
						local newDmgSrc = modDamagable.NewDamageSource{
							Damage=damage;
							Dealer=self.Owner;
							ToolStorageItem=self.StorageItem;
							TargetPart=hitObj;
						};
						damagable:TakeDamagePackage(newDmgSrc);
						
					end
				end
				
			end
			modAudio.Play(random:NextInteger(1,2)==1 and "BulletBodyImpact" or "BulletBodyImpact2", self.Prefab);
			
		else
			if hitObj.Anchored then
				task.delay(1.5, function()
					if self.Rope == nil then return end;
					self.Rope.Locked = true;
					for a=1, #linkObjects do
						if linkObjects[a]:IsA("BasePart") then
							linkObjects[a].Color = Color3.fromRGB(64, 40, 40);
						end
					end
				end)
				
			else
				self:Destroy();
				
			end
			
		end
		
		if self.NekronVeinSpread then
			task.spawn(function()
				self.NekronVeinSpread(hitObj);
			end)
			
		end
		
		return true;
	end
	
	return projectile;
end

return Pool;