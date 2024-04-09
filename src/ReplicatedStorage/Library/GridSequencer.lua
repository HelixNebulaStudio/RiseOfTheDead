local GridSequencer = {};
GridSequencer.__index = GridSequencer;

GridSequencer.UlamSpiralSequence = {};
--local cubicSequence = require(script.CubicSequence);
--==
function GridSequencer.getSpiralGridCount(layers)
	return (2*layers-1)^2;
end

function GridSequencer.genNextUlamSpiral(x, y, z)
	if x == 0 and z == 0 then return Vector3.new(1, y, 0) end
	local a = math.atan2(z, x) / math.pi;
	if (a >= -0.75 and a <= -0.25) then return Vector3.new(x+1, y, z) end;
	if (a >= 0.25 and a < 0.75) then return Vector3.new(x-1, y, z) end;
	if (a > -0.25 and a < 0.25) then return Vector3.new(x, y, z+1) end;
	return Vector3.new(x, y, z-1);
end

function GridSequencer.getNextSpiralCorner(x, y, z)
	if (x <= 0 and z <= 0) or (x > 0 and z > 0) then
		x = -x;
		if x >= 0 then
			x = x +1;
		end
	else
		z = x;
	end
	return Vector3.new(x, y, z);
end

function GridSequencer.loopSpiralGrid(point, layers, func)
	local yLayers = 0;
	local lastGridCount = 1;
	
	local breakLoop;
	
	for layer=1, layers do
		local gridCount = GridSequencer.getSpiralGridCount(layer);
		for a=lastGridCount, gridCount do
			func(point + GridSequencer.UlamSpiralSequence[a] + Vector3.new(0, 0, 0), yLayers);
		end
		lastGridCount = gridCount;
		
		for y=1, yLayers do
			local yCount = GridSequencer.getSpiralGridCount(yLayers-y);
			local yLastCount = GridSequencer.getSpiralGridCount(yLayers-y+1);
			
			for a=yCount, yLastCount do
				func(point + GridSequencer.UlamSpiralSequence[a] + Vector3.new(0, -y, 0), yLayers);
			end
		
			for a=yCount, yLastCount do
				func(point + GridSequencer.UlamSpiralSequence[a] + Vector3.new(0, y, 0), yLayers);
			end
		end
		
		breakLoop = func();
		if breakLoop == true then return end;
		
		yLayers = yLayers + 1;
	end
end

--function GridSequencer.loopChunkGrid(point, layers, func)
--	local yLayers = 1;
--	local lastGridCount = 1;
--	
--	local count = 0;
--	local breakLoop;
--	
--	for layer=1, layers do
--		local gridCount = GridSequencer.getSpiralGridCount(layer);
--		for a=lastGridCount, gridCount do
--			func(point + GridSequencer.UlamSpiralSequence[a] + Vector3.new(0, 0, 0), layer);
--			
--			if yLayers < 3 then
--				func(point + GridSequencer.UlamSpiralSequence[a] + Vector3.new(0, -yLayers, 0), layer);
--				func(point + GridSequencer.UlamSpiralSequence[a] + Vector3.new(0, yLayers, 0), layer);
--			end
--			breakLoop = func();
--		end
--		lastGridCount = gridCount;
--		
--		breakLoop = func();
--		if breakLoop == true then return end;
--	end
--end

local directionVectors = {
	Vector3.new(0, 0, 1);
	Vector3.new(0, 0, -1);
	Vector3.new(1, 0, 0);
	Vector3.new(-1, 0, 0);
}

function GridSequencer.loopChunkGrid(point, layers, func)
	local breakLoop;
	
	local layer = 1;
	
	local cache = table.create(4);
	
	func(point + Vector3.new(), 0);
	
	for layer=1, layers do
		for a=1, #directionVectors do
			local dir = directionVectors[a];
			local cId = tostring(dir);
			
			if cache[cId] == nil then cache[cId] = Vector3.new() end;
			local vec = cache[cId];
			vec = vec + dir;
			cache[cId] = vec;
			breakLoop = func(point + vec, layer);
			
			local sideDir = Vector3.new(vec.X == 0 and 1 or 0, 0, vec.Z == 0 and 1 or 0);
			for side=1, layer-(vec.X == 0 and 1 or 0) do
				breakLoop = func(point + vec + sideDir*side, layer);
				breakLoop = func(point + vec + sideDir*-side, layer);
				if breakLoop == true then return end;
			end
			if breakLoop == true then return end;
		end
		if breakLoop == true then return end;
	end
--	for layer=1, layers do
--		local gridCount = GridSequencer.getSpiralGridCount(layer);
--		for a=lastGridCount, gridCount do
--			func(point + GridSequencer.UlamSpiralSequence[a] + Vector3.new(0, 0, 0), layer);
--			
--			if yLayers < 3 then
--				func(point + GridSequencer.UlamSpiralSequence[a] + Vector3.new(0, -yLayers, 0), layer);
--				func(point + GridSequencer.UlamSpiralSequence[a] + Vector3.new(0, yLayers, 0), layer);
--			end
--			breakLoop = func();
--		end
--		lastGridCount = gridCount;
--		
--		breakLoop = func();
--		if breakLoop == true then return end;
--	end
end

function GridSequencer.init()
	local vec = Vector3.new(0, 0, 0);
	local count = GridSequencer.getSpiralGridCount(30);
	
	for a=1, count do
		table.insert(GridSequencer.UlamSpiralSequence, vec);
		vec = GridSequencer.genNextUlamSpiral(vec.X, 0, vec.Z);
	end
end

return GridSequencer;