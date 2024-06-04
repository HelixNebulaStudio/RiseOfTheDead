local RaycastUtil = {}
--==

-- !outline RaycastUtil.ConeCast(packet)
function RaycastUtil.ConeCast(packet)
	local origin, dir, points, radius, rayParam = packet.Origin, packet.Dir, packet.Points, packet.Radius, packet.RayParam;
	points = points or 6;
	
	local r = {};
	
	local hitResult = workspace:Raycast(origin, dir, rayParam);
	local dist;
	
	if hitResult == nil then return r end;
	
	dist = (hitResult.Position-origin).Magnitude;
	table.insert(r, hitResult);
	
	local rad = math.atan(radius/dist);
	local hypotenuse = (radius/math.sin(rad))+0.1;
	
	local stepSize = (math.pi*2)/points;

	for a = 0, points do
		local dirCf = CFrame.lookAt(Vector3.zero, dir);
		dirCf = dirCf*CFrame.Angles(0, 0, stepSize*a); -- roll cframe
		dirCf = dirCf*CFrame.Angles(rad, 0, 0); --pitch cframe;
		
		local rayDir = dirCf.LookVector*hypotenuse;
		
		local hR = workspace:Raycast(origin, rayDir, rayParam);
		if hR then
			table.insert(r, hR);
		end
		
		if packet.OnEachRay then
			local breakRequest = packet.OnEachRay(origin, rayDir, hR);
			if breakRequest == true then
				break;
			end
		end
	end

	return r;
end

--[[
	@param origin Vector3
	@param dir Vector3
	@param points number
	@param radius number
]]
function RaycastUtil.RingCast(orign, dir, points, radius, rayParam): {RaycastResult}
	local r = {};

	local hitResult = workspace:Raycast(orign, dir, rayParam);

	if hitResult then
		table.insert(r, hitResult);
	end

	points = points or 6;

	for a = 0, (points-1) do
		local ph = a/points * math.pi *2
		local x = math.cos(ph)
		local z = math.sin(ph)

		local pos = orign+Vector3.new(x, 0, z)*(radius or 1);

		local hR = workspace:Raycast(pos, dir, rayParam);
		if hR then
			table.insert(r, hR);
		end
	end

	return r;
end

-- !outline RaycastUtil.EdgeCast
function RaycastUtil.EdgeCast(basePart, dir, rayParam)
	local cframe = basePart.CFrame;
	local orign = basePart.Position;
	local _size = basePart.Size;
	local halfSize = basePart.Size/2;

	local r = {};

	local hitResult = workspace:Raycast(orign, dir, rayParam);

	if hitResult then
		table.insert(r, hitResult);
	end

	local points = {
		cframe * CFrame.new(halfSize.X, 0, halfSize.Z);
		cframe * CFrame.new(-halfSize.X, 0, halfSize.Z);
		cframe * CFrame.new(halfSize.X, 0, -halfSize.Z);
		cframe * CFrame.new(-halfSize.X, 0, -halfSize.Z);
	}

	for a=1, #points do
		local pos = points[a].Position;

		local hR = workspace:Raycast(pos, dir, rayParam);
		if hR then
			table.insert(r, hR)
		end
	end

	return r;
end

function RaycastUtil.GetHittable(origin: Vector3, range: number, targetObject, minPartSize: number?)
	local hitParts = {};
	local maxParts = 0;

	local function scan(part)
		local direction = (part.Position-origin).Unit;
		
		local ray = Ray.new(origin, direction*(range or 64));
		local hit, _point = workspace:FindPartOnRayWithWhitelist(ray, {workspace.Environment; workspace.Terrain; part}, true);
		if hit and hit == part then
			table.insert(hitParts, hit);
			if maxParts < #hitParts then
				maxParts = #hitParts;
			end
		end
	end

	if targetObject:IsA("Model") then
		local parts = targetObject:GetChildren();
		for a=1, #parts do
			if parts[a]:IsA("BasePart") and ((parts[a].Size.X + parts[a].Size.Y + parts[a].Size.Z)/2.5) > (minPartSize or 0.5) then
				maxParts = maxParts +1;
				scan(parts[a]);
			end
		end
		
	elseif targetObject:IsA("BasePart") then
		scan(targetObject);
		
	end

	return hitParts, maxParts;
end

local groundRayParams: RaycastParams;
function RaycastUtil.GetGround(origin: Vector3, range: number?) : RaycastResult?
	if groundRayParams == nil then
		groundRayParams = RaycastParams.new();
		groundRayParams.FilterType = Enum.RaycastFilterType.Include;
		groundRayParams.FilterDescendantsInstances = {workspace.Environment; workspace.Terrain;};
	end

	local r = range or 64;
	local rayResult = workspace:Raycast(origin, -Vector3.yAxis * r, groundRayParams);
	if rayResult then
		return rayResult;
	end
	return nil;
end


local ceilingRayParams: RaycastParams;
function RaycastUtil.GetCeiling(origin: Vector3, range: number?) : RaycastResult?
	if ceilingRayParams == nil then
		ceilingRayParams = RaycastParams.new();
		ceilingRayParams.FilterType = Enum.RaycastFilterType.Include;
		ceilingRayParams.FilterDescendantsInstances = {workspace.Environment; workspace.Terrain;};
	end

	local r = range or 256;
	
	local rayResults = RaycastUtil.RingCast(origin, Vector3.yAxis * r, 2, 3, ceilingRayParams);
	if #rayResults > 2 then
		return rayResults;
	end
	return nil;
end

--local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
function RaycastUtil.SplashCast(origin: Vector3, packet: {
	Radius: number?; 
	SpreadDepth: number?;  
	RayParam: RaycastParams?;

	MaxPitch: number?;

	LoopFunc: (()->boolean)?;
}) : {RaycastResult}


	local yawPoints = 4;
	local pitchPoints = 2;

	packet = packet or {};
	local rayParam = packet.RayParam or groundRayParams;
	local radius = packet.Radius or 4; assert(radius);
	local spreadDepth = packet.SpreadDepth or 2; assert(spreadDepth);

	local maxPitch = packet.MaxPitch or (math.pi/2)

	local endPoints = {};
	
	local function cast(lookCf, oVec, oDir, depth)
		if depth <= 0 then return end;

		--Debugger:Ray(Ray.new(oVec, oDir * radius)).BrickColor = BrickColor.random();

		for a=0, (yawPoints-1) do
			local r = a/yawPoints * math.pi*2;

			for b=1, pitchPoints do
				local ph = (b/pitchPoints)^(1/2) * maxPitch;
				
				local cf = lookCf;
	
				local spreadRollStart = r;
				local deflection = ph;
				
				cf = cf * CFrame.Angles(0, 0, spreadRollStart); -- roll
				cf = cf * CFrame.Angles(deflection, 0, 0); -- pitch
		
				local dir = cf.LookVector;
				local rayResult = workspace:Raycast(origin, dir*radius, rayParam);

				-- local debugRay = Debugger:Ray(Ray.new(origin, dir * radius));
				-- debugRay.Color = rayResult and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0);
				-- game.Debris:AddItem(debugRay, 0.5);

				if rayResult then
					cast(CFrame.lookAt(Vector3.zero, dir, rayResult.Normal), rayResult.Position +rayResult.Normal, dir, depth-1);
					table.insert(endPoints, rayResult);
				end
			end
		end
	end
	cast(CFrame.lookAt(Vector3.zero, -Vector3.yAxis), origin, -Vector3.yAxis, spreadDepth);

	local results = {};
	for a=1, #endPoints do
		local rayResult: RaycastResult = endPoints[a];

		local exist = false;
		for b=1, #results do
			if (results[b].Position == rayResult.Position) then
				exist = true;
				break;
			end
		end
		if not exist then
			table.insert(results, rayResult);
		end

	end
	
	return endPoints;
end

return RaycastUtil;