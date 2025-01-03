local Vector = {};

Vector.Vec3Min = Vector3.new(-math.huge, -math.huge, -math.huge);
Vector.Vec3Max = Vector3.new(math.huge, math.huge, math.huge);

function Vector.ClampVector3(vec: Vector3, min, max)
	min = min or Vector.Vec3Min;
	max = max or Vector.Vec3Max;
	
	return Vector3.new(
		math.clamp(vec.X, min.X or Vector.Vec3Min.X, max.X or Vector.Vec3Max.X),
		math.clamp(vec.Y, min.Y or Vector.Vec3Min.Y, max.Y or Vector.Vec3Max.Y),
		math.clamp(vec.Z, min.Z or Vector.Vec3Min.Z, max.Z or Vector.Vec3Max.Z)
	)
end

function Vector.DistanceSqrdXZ(vecA: Vector3, vecB: Vector3)
	return (vecA.X-vecB.X)^2 + (vecA.Z-vecB.Z)^2;
end

function Vector.DistanceSqrd(vecA: Vector3, vecB: Vector3)
	return (vecA.X-vecB.X)^2 + (vecA.Y-vecB.Y)^2 + (vecA.Z-vecB.Z)^2;
end

function Vector:InCenter(position: Vector3, center: Vector3, radius: number)
	radius = radius or 10;

	local regionSize = Vector3.new(radius, radius, radius);
	local regionMin = center - regionSize;
	local regionMax = center + regionSize;

	if position.X <= regionMin.X or position.Y <= regionMin.Y or position.Z <= regionMin.Z
		or position.X >= regionMax.X or position.Y >= regionMax.Y or position.Z >= regionMax.Z then
		return false
	end
	return true;
end

function Vector.ClampMagnitude(vector, min, max)
	return vector.Unit * math.clamp(vector.Magnitude, min, max);
end

function Vector.MagnitudeSqrd(v)
	return (v.X)^2 + (v.Y)^2 + (v.Z)^2;
end

function Vector.PointBetweenAB(a, b, p)
	local u = b-a; -- line between a to b;
	local pq = p-a; -- line between p to a;
	local w = pq - (u * pq:Dot(u)/Vector.MagnitudeSqrd(u)); -- orthogonal proj, point

	return p-w;
end

function Vector.WithinRegion2(point: Vector2, minVec2: Vector2, maxVec2: Vector2, b: number)
	if point.X+b >= minVec2.X and point.X-b <= maxVec2.X
	and point.Y+b >= minVec2.Y and point.Y-b <= maxVec2.Y then
		return true;
	end
	return false;
end

return Vector;