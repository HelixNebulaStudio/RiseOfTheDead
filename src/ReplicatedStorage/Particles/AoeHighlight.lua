local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local AoeHighlight = {};

local templateCylinderHighlight = script:WaitForChild("cylinder");

local raycastPreset = RaycastParams.new();
raycastPreset.FilterType = Enum.RaycastFilterType.Include;
raycastPreset.CollisionGroup = "Raycast";
raycastPreset.FilterDescendantsInstances = {workspace.Environment; workspace.Terrain};
--raycastPreset.IgnoreWater = true;

function AoeHighlight.newCylinder(lifetime)
	local new = templateCylinderHighlight:Clone();
	
	Debugger.Expire(new, lifetime or 10);
	
	return new;
end

function AoeHighlight:Ray(origin, direction)
	local raycastResult = workspace:Raycast(origin, direction, raycastPreset);
	
	if raycastResult then
		local rayPos, rayNorm = raycastResult.Position, raycastResult.Normal;
		return CFrame.lookAt(raycastResult.Position, rayPos + rayNorm);
	end
end

return AoeHighlight;