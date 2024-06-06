--!native
local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local ArcTracing = {};
ArcTracing.__index = ArcTracing;
ArcTracing.Bounce=0.8;
ArcTracing.MaxBounce=0;
ArcTracing.LifeTime=5;
ArcTracing.Acceleration = Vector3.new(0, -workspace.Gravity, 0);
ArcTracing.KeepAcceleration = false;
ArcTracing.IsWeaponRay = true;
ArcTracing.Delta = 1/15;
ArcTracing.RayRadius = 0;

local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

function ArcTracing.new()
	local self = {
		MaxRayDistance = 1024;
		RayWhitelist = {workspace.Terrain; workspace.Environment};
	};
	
	setmetatable(self, ArcTracing);
	return self;
end

function ArcTracing:GeneratePath(origin, velocity, arcFunc)
	local distance = self.MaxRayDistance;
	local points = {};
	
	local delta = self.Delta;
	local totalDelta = 0;
	local sleepSpeed = 5^2;
	local lifetime = math.max(self.LifeTime, 0.1);
	
	local raycastParams = RaycastParams.new();
	raycastParams.FilterType = Enum.RaycastFilterType.Include;
	raycastParams.IgnoreWater = true;
	raycastParams.CollisionGroup = "Raycast";
	
	if self.IgnoreWater == false then
		raycastParams.IgnoreWater = false;
	end
	
	local arcPointMeta = {};
	arcPointMeta.__index = arcPointMeta;
	
	function arcPointMeta.Recast(arcPoint)
		raycastParams.FilterDescendantsInstances = self.RayWhitelist;
		
		local rayVelocity = arcPoint.Direction * (arcPoint.Displacement + 0.5);
		local raycastResult = workspace:Raycast(arcPoint.Origin, rayVelocity, raycastParams);
		
		local rayHit = raycastResult and raycastResult.Instance or nil;
		
		if rayHit and rayHit:GetAttribute("IgnoreWeaponRay") == true and self.IsWeaponRay == true then
			rayHit = nil;
		end
		
		arcPoint.Hit = rayHit;
		arcPoint.Point = raycastResult and raycastResult.Position or arcPoint.Origin + rayVelocity;
		arcPoint.Normal = raycastResult and raycastResult.Normal or nil;
		arcPoint.Material = raycastResult and raycastResult.Material or nil;
	end


	local debugBreaks = self.DebugArc or false;
	local hitDebounce = {};
	
	self.BounceCount = self.MaxBounce;
	
	repeat
		raycastParams.FilterDescendantsInstances = self.RayWhitelist;
		
		totalDelta = totalDelta + delta;
		velocity = velocity + self.Acceleration * delta

		
		local rayCastDir = velocity * delta;
		local raycastResult;

		local rayHit, rayPoint;
		
		if self.RayRadius <= 0 then
			raycastResult = workspace:Raycast(origin, rayCastDir, raycastParams);

			rayHit = raycastResult and raycastResult.Instance or nil;
			rayPoint = raycastResult and raycastResult.Position or origin + (velocity * delta);
			
		else
			raycastResult = workspace:Spherecast(origin, self.RayRadius, rayCastDir, raycastParams);

			rayHit = raycastResult and raycastResult.Instance or nil;
			rayPoint = raycastResult and origin + (rayCastDir.Unit * raycastResult.Distance) or origin + (velocity * delta);
			
		end

		if debugBreaks then
			if raycastResult then
				local pointPart = Debugger:PointPart(raycastResult.Position);
				pointPart.Name = "Point";
				
				local pointPart2 = Debugger:PointPart(origin + (rayCastDir.Unit * raycastResult.Distance));
				pointPart2.Name = "Distance";
				
			end

			local dist = (origin-rayPoint).Magnitude
			local directionPart = Debugger:PointPart(origin);
			directionPart.Shape = Enum.PartType.Block;
			local cf = CFrame.lookAt(origin, origin+rayCastDir);
			directionPart.CFrame = cf * CFrame.new(0, 0, -(dist/2));
			directionPart.Size = Vector3.new(0.05, 0.05, dist);
		end
		
		if rayHit then
			if hitDebounce[rayHit] and tick()-hitDebounce[rayHit] <= 0.25 then
				rayHit = nil;
				rayPoint = rayPoint + (velocity.Unit * 0.001);
				
			elseif rayHit:GetAttribute("IgnoreWeaponRay") == true and self.IsWeaponRay == true then
				rayHit = nil;
				rayPoint = rayPoint + (velocity.Unit * 0.001);
				
				--rayPoint = raycastResult.Position + (velocity.Unit * delta);
			end
			
			if rayHit and rayHit.Parent:FindFirstChildWhichIsA("Humanoid") then
				hitDebounce[rayHit] = tick();

			end
		end
		
		local rayNormal = raycastResult and raycastResult.Normal or nil;
		local rayMaterial = raycastResult and raycastResult.Material or nil;

		local passThrough = rayHit and self.KeepAcceleration == true and (rayHit.Anchored == false or rayHit.CanCollide == false or rayMaterial == Enum.Material.Water);
		--if passThrough then
		--	rayPoint = origin + (velocity * delta);
		--end
		
		local displacement = raycastResult and raycastResult.Distance or (origin - rayPoint).Magnitude;
		distance = distance - displacement;
		
		local arcPoint = {
			Hit=rayHit;
			Origin=origin;
			Velocity=velocity;
			Direction=velocity.Unit;
			Point=rayPoint;
			Displacement=displacement;
			Normal=rayNormal;
			Material=rayMaterial;
			TotalDelta=totalDelta;
		};
		setmetatable(arcPoint, arcPointMeta);
		
		table.insert(points, arcPoint);
		origin = rayPoint;
		
		
		local breakRequest = false;
		if arcFunc then
			breakRequest = arcFunc(arcPoint);
		end
		
		if rayHit then
			local unitVel = velocity.Unit;

			origin = origin + rayNormal * 0.001;
			
			if passThrough then
				origin = rayPoint;
				
			elseif arcPoint.ReflectToPoint and self.BounceCount > 0 then
				local newDir = (arcPoint.ReflectToPoint - rayPoint).Unit;

				velocity = newDir * velocity.Magnitude;

			else
				if self.Bounce and self.BounceCount > 0 then
					velocity = (unitVel - 2 * unitVel:Dot(rayNormal) * rayNormal) * velocity.Magnitude * math.clamp(self.Bounce, 0, 1);
					
					local bounceDot = (velocity + self.Acceleration * delta).Unit:Dot(rayNormal);
					if bounceDot <= 0.1 then
						breakRequest = true;
					end
					
				end
				
			end

			self.BounceCount = self.BounceCount -1;
			if debugBreaks then
				Debugger:Warn("self.BounceCount", self.BounceCount, "self.MaxBounce", self.MaxBounce);
			end
		end
		
		local arcSpeed = velocity:Dot(velocity);
		
		if arcSpeed < sleepSpeed and rayHit then
			if passThrough then
			else
				if debugBreaks then
					Debugger:Warn("Break on sleep", arcSpeed, self.Bounce, self.MaxBounce);
				end
				break;
			end
		end;
		
		if displacement <= 0.002 and rayHit then -- no motion
			if passThrough then
				if displacement <= 0 then
					if debugBreaks then
						Debugger:Warn("Break on no motion", displacement);
					end
					break;
				end
				
			else
				if arcPoint.Debug == true then
					Debugger:Warn("Break on low motion", displacement);
				end
				break;
			end
		end
		
		if breakRequest == true then
			if debugBreaks then
				Debugger:Warn("Break on break request");
			end
			break
		end;
		
	until distance <= 0 or #points > 256 or (totalDelta > lifetime);
	
	return points;
end

function ArcTracing:FollowPath(points, base, tween, arcFunc, onComplete)
	task.spawn(function()
		local tweenInfo = TweenInfo.new(self.Delta+0.01);
		
		base.Anchored = true;
		
		local spinCf = CFrame.new();
		
		for a=1, #points do
			local arcPoint = points[a];
			base.CFrame = CFrame.new(arcPoint.Origin, arcPoint.Origin + arcPoint.Direction) * spinCf;
			
			if self.AirSpin then
				spinCf = spinCf * CFrame.Angles(self.AirSpin, 0, 0);
			end;
			
			if tween then
				TweenService:Create(base, tweenInfo, {Position=arcPoint.Point}):Play();
			else
				base.CFrame = CFrame.new(arcPoint.Point) * base.CFrame.Rotation;
			end
			
			if arcFunc then
				if a == #points then
					arcPoint.LastPoint = true;
				end 
				local breakLoop = arcFunc(arcPoint);
				if breakLoop == true then
					break;
				end
			end
			task.wait(self.Delta);
		end
		
		if onComplete then
			onComplete();
		end
	end)
end

function ArcTracing:GetSteppedVelocityByTime(origin, targetPoint, travelTime)

	local v = (targetPoint-origin)/travelTime;
	v = v - (self.Acceleration/2 * travelTime^2) / travelTime
	return v
	
	--[[ this works
		--
	local accDelta = self.Acceleration * self.Delta^2;
	local acc = accDelta + (accDelta * 2);
	return (targetPoint - origin - acc) / (self.Delta*2);
		--
	local acc = 3 * self.Acceleration * self.Delta^2;
	return (targetPoint - origin - acc) / (self.Delta*2);
		--
	]]
end

function ArcTracing:GetVelocityByTime(origin, targetPoint, travelTime)
	-- velocity = displacement / time
	-- displacement = init_velocity*time  +  1/2*acceleration  *  time^2
	
	return (targetPoint - origin - self.Acceleration/2 * travelTime^2) / travelTime;
end

return ArcTracing;