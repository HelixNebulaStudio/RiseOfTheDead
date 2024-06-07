local CollectionService = game:GetService("CollectionService");

local Ricochet = {};

function Ricochet.OnStepped(projectile, arcPoint, radius)
	if arcPoint.Hit == nil or arcPoint.Hit.CanCollide == false or arcPoint.Material == Enum.Material.Water then return end;

	local overlapParams = OverlapParams.new();
	overlapParams.FilterType = Enum.RaycastFilterType.Include;
	overlapParams.MaxParts = 4;
	overlapParams.FilterDescendantsInstances = CollectionService:GetTagged("Enemies");
	
	local cache = projectile.Cache;
	
	if cache.CacheRootParts == nil then
		cache.CacheRootParts = {};
	end

	local impactPoint = arcPoint.Point;
	local impactNormal = arcPoint.Normal;

	local rootParts = workspace:GetPartBoundsInRadius(impactPoint, radius or 32, overlapParams);

	if #rootParts > 0 then
		local closestRootPart = nil;
		local closestDist = math.huge;
		for a=1, #rootParts do
			local rootPos = rootParts[a].Position + Vector3.new(0, 1.5, 0);
			local rootDir = (rootPos - impactPoint).Unit;
			local reflectAngle = impactNormal:Dot(rootDir);
			if reflectAngle <= 0.1 then continue end;
			if cache.CacheRootParts[rootParts[a]] and tick()-cache.CacheRootParts[rootParts[a]] <= 0.5 then continue end;

			local dist = (rootParts[a].Position - impactPoint).Magnitude;

			if dist < closestDist then
				closestDist = dist;
				closestRootPart = rootParts[a];

				cache.CacheRootParts[closestRootPart] = tick();
			end
		end

		if closestRootPart then
			arcPoint.ReflectToPoint = closestRootPart.Position + Vector3.new(0, 1, 0);

		end
	end
end

return Ricochet;