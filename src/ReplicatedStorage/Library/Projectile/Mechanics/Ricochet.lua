local CollectionService = game:GetService("CollectionService");

local Ricochet = {};

function Ricochet.OnStepped(projectile, arcPoint, radius)
	if arcPoint.Hit == nil or arcPoint.Hit.CanCollide == false or arcPoint.Material == Enum.Material.Water then return end;

	local overlapParams = OverlapParams.new();
	overlapParams.FilterType = Enum.RaycastFilterType.Whitelist;
	overlapParams.MaxParts = 8;
	overlapParams.FilterDescendantsInstances = CollectionService:GetTagged("Enemies");
	
	local cache = projectile.Cache;
	
	if cache.CacheRootParts == nil then
		cache.CacheRootParts = {};
	end

	local impactPoint = arcPoint.Point;

	local rootParts = workspace:GetPartBoundsInRadius(impactPoint, radius or 32, overlapParams);

	if #rootParts > 0 then
		local closestRootPart = nil;
		local closestDist = math.huge;
		for a=1, #rootParts do
			if cache.CacheRootParts[rootParts[a]] and tick()-cache.CacheRootParts[rootParts[a]] <= 1 then continue end;

			local dist = (rootParts[a].Position - impactPoint).Magnitude;

			if dist < closestDist then
				closestDist = dist;
				closestRootPart = rootParts[a];

				cache.CacheRootParts[closestRootPart] = tick();
			end
		end

		if closestRootPart then
			arcPoint.ReflectToPoint = closestRootPart.Position;

		end
	end
end

return Ricochet;