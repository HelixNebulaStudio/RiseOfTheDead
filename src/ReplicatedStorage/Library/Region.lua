local Region = {};
Region.__index = Region;

local CollectionService = game:GetService("CollectionService");

local overlapParams = OverlapParams.new();
overlapParams.FilterType = Enum.RaycastFilterType.Include;

--== Script;

function Region:GetPlayersWithin(modelOrPart)
	local players = {};
	
	overlapParams.FilterDescendantsInstances = CollectionService:GetTagged("PlayerRootParts");
	
	local function captureObj(obj)
		if obj:IsA("BasePart") then
			local hitParts = workspace:GetPartsInPart(obj, overlapParams);

			for a=1, #hitParts do
				local player = game.Players:GetPlayerFromCharacter(hitParts[a].Parent);
				if player then
					table.insert(players, player);
				end
			end
		end
	end
	
	if modelOrPart:IsA("Model") then
		for _, obj in pairs(modelOrPart:GetChildren()) do
			captureObj(obj);
		end
		
	elseif modelOrPart:IsA("BasePart") then
		captureObj(modelOrPart);
		
	end
	
	return players;
end

function Region:InRegion(position, region, radius)
	radius = radius or 10;
	
	local regionSize = Vector3.new(radius, radius, radius);
	local regionMin = region - regionSize;
	local regionMax = region + regionSize;
	
	if position.X <= regionMin.X or position.Y <= regionMin.Y or position.Z <= regionMin.Z
		or position.X >= regionMax.X or position.Y >= regionMax.Y or position.Z >= regionMax.Z then
		return false
	end
	return true;
end

function Region:ClampVectorToCuboid(vector, part)
	local rayParam = RaycastParams.new();
	rayParam.FilterType = Enum.RaycastFilterType.Include;
	rayParam.IgnoreWater = true;
	rayParam.FilterDescendantsInstances = {part;};
	
	local diff = vector - part.Position
	local dir = diff.Unit * -diff.Magnitude*2
	
	local rayResult = workspace:Raycast(vector, dir, rayParam);
	
	return rayResult and rayResult.Position or (vector + dir);
end

return Region;