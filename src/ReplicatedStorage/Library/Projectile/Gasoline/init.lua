local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Pool = {};
Pool.__index = Pool;
--== Variables;
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");
local TweenService = game:GetService("TweenService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modInfoBubbles = require(game.ReplicatedStorage.Library.InfoBubbles);
local modDamagable = require(game.ReplicatedStorage.Library.Damagable);
local Projectile = require(script.Parent.Projectile);

local projectilePrefab = script.flammable;
local templateDestructible = script.Destructible;
local random = Random.new();

local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
--== Script;

function Pool.new(owner)
	local projectile = setmetatable({}, Projectile);
	projectile.Owner = nil;
	
	projectile.Prefab = projectilePrefab:Clone();

	projectile.ArcTracerConfig = {
		Velocity=50;
		LifeTime=120;
		Bounce=0;
		Acceleration=Vector3.new(0, -workspace.Gravity, 0);
		KeepAcceleration = true;
		IgnoreEntities = true;
	};
	
	projectile.Configurations = {
		ProjectileVelocity=50;
		ProjectileLifeTime=120;
		ProjectileBounce=0;
		ProjectileAcceleration=Vector3.new(0, -workspace.Gravity, 0);
		ProjectileKeepAcceleration = true;
		IgnoreEntities = true;
	};
	
	function projectile:Activate()
		-- On Launch;
		CollectionService:AddTag(self.Prefab, "Flammable");
	end	
	
	function projectile:OnContact(arcPoint)
		if arcPoint.Hit then -- and arcPoint.LastPoint
			local hitPart, hitPoint = arcPoint.Hit, arcPoint.Point;

			if self.Owner then
				self.Prefab:SetAttribute("Owner", self.Owner.Name);
			end
			
			if hitPart.Name == "flammable" or CollectionService:HasTag(hitPart, "Flammable") then
				
				local despawnTime = self.Prefab:GetAttribute("DespawnTime");
				if despawnTime then
					self.Prefab:SetAttribute("DespawnTime", tick()+60);
				end
				
				self.Prefab:Destroy();
				return;
			end
			
			self.Prefab.Anchored = true;
			
			if self.Prefab.Parent == nil then return end;
			
			self.Prefab.CFrame = CFrame.new(hitPoint, hitPoint + arcPoint.Normal) * CFrame.Angles(math.rad(-90), 0, 0);
			
			if self.Prefab.Parent and self.Prefab.Parent.Name ~= "flammable" then
				local newModel = Instance.new("Model");
				newModel.Name = "flammable";
				newModel.Parent = workspace.Environment;

				local newDestructible = templateDestructible:Clone();
				newDestructible.Parent = newModel;

				self.Prefab.Parent = newModel;
				newModel.PrimaryPart = self.Prefab;
			end
			
			local hitWorldSize = hitPart.CFrame:vectorToWorldSpace(hitPart.Size);
			local minSize = math.clamp(math.min( math.abs(hitWorldSize.X), math.abs(hitWorldSize.Z), 10), 0.6, 10);
			TweenService:Create(self.Prefab, tweenInfo, {
				Size = Vector3.new(minSize, 0.6, minSize);
			}):Play();
			
			
		end
	end
	
	return projectile;
end

return Pool;
