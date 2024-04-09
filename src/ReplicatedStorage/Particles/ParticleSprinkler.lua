local Debris = game:GetService("Debris");

local random = Random.new();

local module = {}
module.particleType = {
	MetalSparks = 0;
	FleshParts = 1;
}

local fleshColors = {
	Color3.fromRGB(95, 50, 43);
	Color3.fromRGB(95, 58, 21);
	Color3.fromRGB(95, 27, 22);
	Color3.fromRGB(95, 63, 63);
	Color3.fromRGB(95, 29, 45);
	Color3.fromRGB(95, 34, 34);
	Color3.fromRGB(152, 120, 94);
}

local cooldownTick = tick();
function module:Emit(packet)
	local particleType = packet.Type;
	
	if particleType == 0 then
		if tick()-cooldownTick <= 0.1 then
			return;
		end
		cooldownTick = tick();
		
		for i = packet.Rate, 0, -1 do
			local part = Instance.new("Part")
			local trail: Trail = Instance.new("Trail")
			local trace0 = Instance.new("Attachment")
			local trace1 = Instance.new("Attachment")
			part.Anchored = false
			part.CanCollide = packet.CanCollide;
			part.CastShadow = false
			part.Locked = true
			part.Massless = true
			part.Transparency = 1
			part.Size = Vector3.new(0.1, 0.1, 0.1)
			part.CFrame = packet.Origin + Vector3.new(math.random(0, 1) * packet.Size, part.Size.Y / 2, math.random(0, 1) * packet.Size)
			part.Parent = workspace.Debris;
			trace0.Parent = part
			trace1.Parent = part
			trace0.Position = trace0.Position - (Vector3.new(1, 1, 1) * packet.Size)
			trace1.Position = trace1.Position + (Vector3.new(1, 1, 1) * packet.Size)
			trail.Color = ColorSequence.new(Color3.fromRGB(255, 238, 148), Color3.fromRGB(255, 157, 0))
			trail.Transparency = NumberSequence.new(0)
			trail.WidthScale = NumberSequence.new(packet.Size)
			trail.FaceCamera = true
			trail.Lifetime = math.random(7,10)/100;--tonumber(packet.Lifetime) or 1; --NumberSequence.new(tonumber(packet.Lifetime) or 1);
			trail.LightEmission = 1
			trail.LightInfluence = 0
			trail.Attachment0 = trace0
			trail.Attachment1 = trace1
			trail.Parent = part
			part.Velocity = packet.Velocity + Vector3.new(math.random(-1, 1), 0.5, math.random(-1, 1)) * packet.Speed;
			Debris:AddItem(part, packet.Lifetime);
		end
		
	elseif particleType == 1 then
		if tick()-cooldownTick <= 0.1 then
			return;
		end
		cooldownTick = tick();
		
		if module[particleType] == nil then
			module[particleType] = {};
			
			for _, obj in pairs(script:WaitForChild("FleshParts"):GetChildren()) do
				table.insert(module[particleType], obj);
			end
		end
		
		local prefabs = module[particleType];
		
		for a=1, math.random(packet.MinSpawnCount or 2, packet.MaxSpawnCount or 3) do
			local part = prefabs[math.random(1, #prefabs)]:Clone();
			part.Anchored = false
			part.CastShadow = false
			part.Color = packet.Color or fleshColors[math.random(1, #fleshColors)];
			
			part.Locked = true
			part.Massless = true
			part.Transparency = 0

			local spreadVec = Vector3.new();
			if packet.SpreadRange then
				spreadVec = Vector3.new(
					random:NextNumber(packet.SpreadRange.Min, packet.SpreadRange.Max),
					random:NextNumber(packet.SpreadRange.Min, packet.SpreadRange.Max),
					random:NextNumber(packet.SpreadRange.Min, packet.SpreadRange.Max)
				);
			end
			
			local newSize = math.random(30, 45)/100;
			if packet.SizeRange then
				newSize = random:NextNumber(packet.SizeRange.Min, packet.SizeRange.Max);
			end
			if packet.Material then
				part.Material = packet.Material;
			end
			part.Size = Vector3.new(newSize,newSize,newSize);
			part.CFrame = packet.Origin + spreadVec;
			local speed = packet.Speed or 40;
			part.Velocity = packet.Velocity + Vector3.new(math.random(-1, 1), 1, math.random(-1, 1)) * speed;
			Debris:AddItem(part, packet.DespawnTime or (math.random(60, 120)/100));
			part.Parent = workspace.Debris;

		end
		
	elseif particleType == 2 then
		
		local prefab = script:WaitForChild("chain");
		
		for a=1, (packet.Count or math.random(2, 3)) do
			local part = prefab:Clone();
			part.Anchored = false
			part.CastShadow = false
			part.Color = packet.Color or part.Color;
			part.Material = packet.Material or part.Material;
			
			part.Locked = true
			part.Massless = true
			part.Transparency = 0
			
			part.CFrame = packet.Origin;
			part.Size = packet.Size or part.Size;
			part.Parent = workspace.Debris;
			
			local speed = packet.Speed or 10;
			part.Velocity = (packet.Velocity or Vector3.new()) + Vector3.new(math.random(-1, 1), 1, math.random(-1, 1)) * speed;
			Debris:AddItem(part, packet.DespawnTime or (math.random(60, 120)/10));
		end
	end
end

return module