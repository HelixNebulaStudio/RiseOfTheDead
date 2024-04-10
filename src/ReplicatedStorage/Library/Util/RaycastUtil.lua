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

-- !outline RaycastUtil.RingCast(orign, dir, points, radius, rayParam)
function RaycastUtil.RingCast(orign, dir, points, radius, rayParam)
	local r = {};

	local hitResult = workspace:Raycast(orign, dir, rayParam);

	if hitResult then
		table.insert(r, hitResult);
	end

	points = points or 6;

	for a = 0, points do
		local ph = a/6 * math.pi *2
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

-- !outline RaycastUtil.IsHittable(origin: Vector3, range: number, targetObject)
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


return RaycastUtil;