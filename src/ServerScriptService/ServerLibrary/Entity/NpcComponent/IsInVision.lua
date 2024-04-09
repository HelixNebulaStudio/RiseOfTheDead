local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
local random = Random.new();



--== Script;
local Component = {};

function Component.new(Npc)
	return function(object, visionAngleDeg)
		if Npc.Head == nil then Debugger:Warn(Npc.Name.." can't see without a head."); return end;
		if object == nil then Debugger:Warn("Missing object", debug.traceback()); return end;
		local hitCount = 0;
		local maxCount = 0;
		
		local function scan(part)
			local direction = (part.Position-Npc.Head.Position).Unit;
			local relativeCframe = Npc.RootPart.CFrame:toObjectSpace(part.CFrame);
			
			if visionAngleDeg then
				local dirAngle = math.deg(math.atan2(relativeCframe.X, -relativeCframe.Z));
				if math.abs(dirAngle) > visionAngleDeg then
					return;
				end
			end
			
			local ray = Ray.new(Npc.Head.Position, direction*(Npc.VisionDistance or 64));
			local hit, point = workspace:FindPartOnRayWithWhitelist(ray, {workspace.Environment; workspace.Terrain; part}, true);
			if hit and hit == part then
				hitCount = hitCount +1;
				if maxCount < hitCount then
					maxCount = hitCount;
				end
			end
		end
		
		if object:IsA("Model") then
			local parts = object:GetChildren();
			for a=1, #parts do
				if parts[a]:IsA("BasePart") then
					maxCount = maxCount +1;
					scan(parts[a]);
				end
			end
		else
			scan(object);
		end
		
		return (hitCount > 0), math.clamp(hitCount/maxCount, 0, 1);
	end;
end

return Component;