local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local Pool = {};
Pool.__index = Pool;
--== Variables;
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modInfoBubbles = require(game.ReplicatedStorage.Library.InfoBubbles);
local modTouchHandler = require(game.ReplicatedStorage.Library.TouchHandler);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);
local Projectile = require(script.Parent.Projectile);

local projectilePrefab = script.slowGoo;
local random = Random.new();

local remotes = game.ReplicatedStorage.Remotes;
local bindIsInDuel = remotes.IsInDuel;

local floorGoop = {script:WaitForChild("goop1"); script:WaitForChild("goop2");};
local explosionEffectPrefab = script:WaitForChild("ExplosionEffect");

local touchHandler = modTouchHandler.new("SlowGoo", 0.5);
function touchHandler:OnPlayerTouch(player, basePart, part)
	modStatusEffects.Slowness(player, 14, 1);
end

local raycastParams = RaycastParams.new();
raycastParams.FilterType = Enum.RaycastFilterType.Include;
raycastParams.IgnoreWater = true;
raycastParams.FilterDescendantsInstances = {workspace.Environment};
raycastParams.CollisionGroup = "Raycast";

--== Script;

function Pool.new(owner)
	local projectile = setmetatable({}, Projectile);
	projectile.Owner = nil;
	projectile.Prefab = projectilePrefab:Clone();

	projectile.ArcTracerConfig = {
		LifeTime=10;
		Velocity=50;
		Bounce=0;
		Acceleration=Vector3.new(0, -workspace.Gravity/8, 0);
	};
	projectile.Configurations = {
		ProjectileLifeTime=10;
		ProjectileVelocity=50;
		ProjectileBounce=0;
		ProjectileAcceleration=Vector3.new(0, -workspace.Gravity/8, 0);
	};
	
	function projectile:Activate()
		-- On Launch;
	end	
	
	function projectile:OnContact(arcPoint)
		if arcPoint.Hit then -- and arcPoint.LastPoint
			if self.Popped then return end;
			self.Popped = true;

			self.Prefab.Transparency = 1;
			self.Prefab:Destroy();

			if RunService:IsClient() then return end;
			
			local hitPart, hitPoint = arcPoint.Hit, arcPoint.Point;
			
			local raycastResult = workspace:Raycast(hitPoint + Vector3.new(0, 4, 0), Vector3.new(0, -20, 0), raycastParams);
			if raycastResult then
				local rayPoint = raycastResult.Position;

				local newEffect = explosionEffectPrefab:Clone();
				newEffect.CFrame = CFrame.new(rayPoint) * CFrame.Angles(0, random:NextNumber(-math.pi, math.pi), 0);
				local effectMesh = newEffect:WaitForChild("Mesh");
				newEffect.Parent = workspace.Entities;

				local size = 40
				local speed = 0.5;
				TweenService:Create(effectMesh, TweenInfo.new(speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{Scale = Vector3.new(size, size, size)}):Play();
				TweenService:Create(newEffect, TweenInfo.new(speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1}):Play();
				Debugger.Expire(newEffect, speed+0.1);
				
				local newGoop = floorGoop[math.random(1, #floorGoop)]:Clone();
				modAudio.Play("TicksZombieExplode", newGoop).PlaybackSpeed = random:NextNumber(0.8, 1);


				local sizeX = random:NextNumber(20, 25);
				newGoop.Size = Vector3.new(12, 1.6, 12);

				TweenService:Create(newGoop, TweenInfo.new(10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{Size = Vector3.new(sizeX, 1.6, sizeX)}):Play();

				newGoop.Position = rayPoint;
				newGoop.Parent = workspace.Entities;

				touchHandler:AddObject(newGoop);

				Debugger.Expire(newGoop, random:NextNumber(60, 120));
			end
			
		end
	end
	
	return projectile;
end

return Pool;