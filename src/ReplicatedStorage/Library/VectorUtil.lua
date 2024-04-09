local VectorUtil = {}

function VectorUtil.SquaredLength(v)
	return v.X^2 + v.Y^2 + v.Z^2;
end

function VectorUtil.PointBetweenAB(a, b, p)
	local u = b-a; -- line between a to b;
	local pq = p-a; -- line between p to a;
	local w = pq - (u * pq:Dot(u)/VectorUtil.SquaredLength(u)); -- orthogonal proj, point

	return p-w;
end

return VectorUtil;
