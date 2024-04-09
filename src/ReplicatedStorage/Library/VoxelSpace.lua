local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

--== Space
local PathingAxisList = {};
for x=-1, 1 do
	for y=-1, 1 do
		for z=-1, 1 do
			local dir = Vector3.new(x, y, z);
			local stepsize = math.abs(x) + math.abs(y) + math.abs(z);
			
			if dir ~= Vector3.zero then
				table.insert(PathingAxisList, {
					AxisVec=dir;
					StepSize=stepsize;
				});
			end
		end
	end
end
table.sort(PathingAxisList, function(a, b) return a.StepSize < b.StepSize; end);

local VoxelSpace = {};
VoxelSpace.ClassName = "VoxelSpace";
VoxelSpace.__index = VoxelSpace;

function VoxelSpace.new()
	local self = {
		AxisOrientation = {"Y"; "Z"; "X"};
		Space = {};
		Voxels = {};
		
		StepSize=3;
	};
	self.__index = self;
	
	setmetatable(self, VoxelSpace);
	return self;
end

function VoxelSpace:NewVoxelPoint(position)
	local voxelPoint = {
		Position = position;
		Value = nil;
		
		Traversable = {};
	}

	setmetatable(voxelPoint, self);
	return voxelPoint;
end

function VoxelSpace:GetOrDefault(cord, new)
	local currentSpace = self.Space;
	
	local lastAxisPoint;
	for a=1, #self.AxisOrientation do
		local axisKey = self.AxisOrientation[a];
		local axisPoint = cord[axisKey];

		if a ~= #self.AxisOrientation then
			if currentSpace[axisPoint] == nil then
				currentSpace[axisPoint] = {};
			end
			
			currentSpace = currentSpace[axisPoint];
			
		else
			lastAxisPoint = axisPoint;
			
		end
	end
	
	local voxelPoint = currentSpace[lastAxisPoint];
	if new ~= nil then
		if voxelPoint == nil then
			voxelPoint = self:NewVoxelPoint(cord);
			table.insert(self.Voxels, voxelPoint);
			
			currentSpace[lastAxisPoint] = voxelPoint;
		end
		
		if voxelPoint.Value == nil then
			voxelPoint.Value = new;
		end
	end

	return voxelPoint;
end

function VoxelSpace:SetTraversable(axis, value)
	local voxelPoint = self;
	
	voxelPoint.Traversable[axis] = value;
end

function VoxelSpace:GetVoxelPosition(vec, gridSize)
	gridSize = gridSize or 1;
	return Vector3.new(math.round(vec.X/gridSize), math.round(vec.Y/gridSize), math.round(vec.Z/gridSize));
end

function VoxelSpace:GetCost(pointA, pointB)
	local displacement = pointA.Position - pointB.Position;
	displacement = Vector3.new(math.abs(displacement.X), math.abs(displacement.Y), math.abs(displacement.Z));
	
	local minDist = math.min(displacement.X, displacement.Y, displacement.Z);
	local maxDist = math.max(displacement.X, displacement.Y, displacement.Z);
	
	local tripleAxis = minDist;
	local doubleAxis = math.max(displacement.X + displacement.Y + displacement.Z - maxDist - 2*minDist, 0);
	local singleAxis = maxDist - doubleAxis - tripleAxis;
	
	return 10 * singleAxis + 14 * doubleAxis + 17 * tripleAxis;
end

function VoxelSpace:SolvePath(pointA, pointB)
	
	local Node = {};
	Node.List = {};
	
	function Node.GetOrDefault(pos)
		if Node.List[pos] then
			return Node.List[pos];
		end
		
		local node = {
			Position = pos;
			
			GCost = 0;
			HCost = 0;
		};
		
		Node.List[pos] = node;
		
		setmetatable(node, {
			__index=function(node, k)
				if k == "FCost" then
					return node.GCost + node.HCost;
				end
			end;
		})
		
		return node;
	end
	
	--
	
	local startNode = Node.GetOrDefault(pointA.Position);
	local targetNode = Node.GetOrDefault(pointB.Position);
	
	local function retracePath()
		local waypointVoxels = {};
		local reverseVoxels = {};
		
		local currentNode = targetNode;
		
		while currentNode ~= startNode do
			local voxelPoint = self:GetOrDefault(currentNode.Position);
			table.insert(reverseVoxels, voxelPoint);
			
			currentNode = currentNode.Parent;
		end
		
		for a=#reverseVoxels, 1, -1 do
			table.insert(waypointVoxels, reverseVoxels[a]);
		end
		
		return waypointVoxels;
	end
	
	local availableNodes = {startNode;};
	local closedNodes = {};
	
	while #availableNodes > 0 do
		local currentNode = availableNodes[1];
		
		for a=1, #availableNodes do
			local node = availableNodes[a];
			
			if node.FCost < currentNode.FCost or node.FCost == currentNode.FCost then
				if node.HCost < currentNode.HCost then
					currentNode = node;
				end
			end
		end
		

		table.remove(availableNodes, table.find(availableNodes, currentNode));
		table.insert(closedNodes, currentNode);
		
		if currentNode == targetNode then
			return retracePath();
		end
		
		local currentVoxelPoint = self:GetOrDefault(currentNode.Position);
		for a=1, #PathingAxisList do
			local axisItem = PathingAxisList[a];
			if self.StepSize < axisItem.StepSize then continue end;

			local adjVec = axisItem.AxisVec;
			if currentVoxelPoint.Traversable[adjVec] == false then continue end;
			
			local changeVec = currentNode.Position + adjVec;
			local adjNode = Node.GetOrDefault(changeVec);
			
			if table.find(closedNodes, adjNode) then continue; end
			
			local voxelPoint = self:GetOrDefault(changeVec);
			if voxelPoint == nil then continue end;
			
			if voxelPoint.Traversable[Vector3.zero] == false then continue end;

			local costToAdj = currentNode.GCost + self:GetCost(currentNode, adjNode);
			if costToAdj < adjNode.GCost or table.find(availableNodes, adjNode) == nil then
				adjNode.GCost = costToAdj;
				adjNode.HCost = self:GetCost(adjNode, targetNode);
				adjNode.Parent = currentNode;
				
				if table.find(availableNodes, adjNode) == nil then
					table.insert(availableNodes, adjNode);
				end
				
			end
		end
		
	end
	
end


function VoxelSpace:GetVoxelPointsInRadius(tarPos, radius, useSquareBounds, orDefaultFunc)
	local voxelPointList = {};
	for axisA=-radius, radius do
		for axisB=-radius, radius do
			for axisC=-radius, radius do
				local rawVec = {
					[self.AxisOrientation[1]] = axisA;
					[self.AxisOrientation[2]] = axisB;
					[self.AxisOrientation[3]] = axisC;
				};
				local newVec = Vector3.new(rawVec.X+tarPos.X, rawVec.Y+tarPos.Y, rawVec.Z+tarPos.Z);
				
				local add = false;
				if useSquareBounds == true then
					add = true;
				else
					local isInRadius = ( (newVec.X-tarPos.X)^2 + (newVec.Y-tarPos.Y)^2 + (newVec.Z-tarPos.Z)^2 ) < radius^2;
					add = isInRadius == true;
				end

				local voxelPoint = self:GetOrDefault(newVec, orDefaultFunc and orDefaultFunc(newVec) or nil);
				if add and voxelPoint then
					table.insert(voxelPointList, voxelPoint);
				end
			end
		end
	end
	
	return voxelPointList;
end

return VoxelSpace;