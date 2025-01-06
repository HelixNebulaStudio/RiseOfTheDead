local Octree = {};
Octree.__index = Octree;

local OctreeNode = {};
Octree.OctreeNode = OctreeNode;

local OctreeRegionUtils = {};
Octree.OctreeRegionUtils = OctreeRegionUtils;

--== MARK: OctreeNode
OctreeNode.__index = OctreeNode;
--[=[
	Creates a new for the given Octree with the object.

	:::warning
	Use Octree:CreateNode() for more consistent results. To use this object directly
	you need to set the position before it's registered which may be unclean.
	:::

	@private
	@param octree Octree
	@param object T
	@return OctreeNode<T>
]=]
function OctreeNode.new(octree, object)
	local self = setmetatable({}, OctreeNode)

	self._octree = octree or error("No octree")
	self._object = object or error("No object")

	self._currentLowestRegion = nil
	self._position = nil

	return self
end

--[=[
	Finds the nearest neighbors to this node within the radius

	```lua
	local octree = Octree.new()
	local node = octree:CreateNode(Vector3.zero, "A")
	octree:CreateNode(Vector3.new(0, 0, 5), "B")
	print(octree:KNearestNeighborsSearch(10, 100)) --> { "A", "B" } { 0, 25 }
	```

	@param k number -- The number to retrieve
	@param radius number -- The radius to search in
	@return { T } -- Objects found, including self
	@return { number } -- Distances squared
]=]
function OctreeNode:KNearestNeighborsSearch(k, radius)
	return self._octree:KNearestNeighborsSearch(self._position, k, radius)
end

--[=[
	Returns the object stored in the octree

	```lua
	local octree = Octree.new()
	local node = octree:CreateNode(Vector3.zero, "A")
	print(octree:GetObject()) --> "A"
	```

	@return T
]=]
function OctreeNode:GetObject()
	return self._object
end

--[=[
	Finds the nearest neighbors to the octree node

	@param radius number -- The radius to search in
	@return { any } -- Objects found
	@return { number } -- Distances squared
]=]
function OctreeNode:RadiusSearch(radius)
	return self._octree:RadiusSearch(self._position, radius)
end

--[=[
	Retrieves the position

	@return Vector3
]=]
function OctreeNode:GetPosition()
	return self._position
end

--[=[
	Retrieves the as px, py, pz

	@return number -- px
	@return number -- py
	@return number -- pz
]=]
function OctreeNode:GetRawPosition()
	return self._px, self._py, self._pz
end

--[=[
	Sets the position of the octree nodes and updates the octree accordingly

	```lua
	local octree = Octree.new()
	local node = octree:CreateNode(Vector3.zero, "A")
	print(octree:RadiusSearch(Vector3.zero, 100)) --> { "A" }

	node:SetPosition(Vector3.new(1000, 0, 0))
	print(octree:RadiusSearch(Vector3.zero, 100)) --> {}
	```

	@param position Vector3
]=]
function OctreeNode:SetPosition(position)
	if self._position == position then
		return
	end

	local px, py, pz = position.x, position.y, position.z

	self._px = px
	self._py = py
	self._pz = pz
	self._position = position

	if self._currentLowestRegion then
		if OctreeRegionUtils.inRegionBounds(self._currentLowestRegion, px, py, pz) then
			return
		end
	end

	local newLowestRegion = self._octree:GetOrCreateLowestSubRegion(px, py, pz)

	-- Sanity check for debugging
	-- if not OctreeRegionUtils.inRegionBounds(newLowestRegion, px, py, pz) then
	-- 	error("[OctreeNode.SetPosition] newLowestRegion is not in region bounds!")
	-- end

	if self._currentLowestRegion then
		OctreeRegionUtils.moveNode(self._currentLowestRegion, newLowestRegion, self)
	else
		OctreeRegionUtils.addNode(newLowestRegion, self)
	end

	self._currentLowestRegion = newLowestRegion
end

--[=[
	Removes the OctreeNode from the octree
]=]
function OctreeNode:Destroy()
	if self._currentLowestRegion then
		OctreeRegionUtils.removeNode(self._currentLowestRegion, self)
	end
end


--== MARK: OctreeRegionUtils
local EPSILON = 1e-6;
local SQRT_3_OVER_2 = math.sqrt(3)/2;
local SUB_REGION_POSITION_OFFSET = {
	{ 0.25, 0.25, -0.25 };
	{ -0.25, 0.25, -0.25 };
	{ 0.25, 0.25, 0.25 };
	{ -0.25, 0.25, 0.25 };
	{ 0.25, -0.25, -0.25 };
	{ -0.25, -0.25, -0.25 };
	{ 0.25, -0.25, 0.25 };
	{ -0.25, -0.25, 0.25 };
};

--[=[
	Creates a new OctreeRegion<T>

	@param px number
	@param py number
	@param pz number
	@param sx number
	@param sy number
	@param sz number
	@param parent OctreeRegion<T>?
	@param parentIndex number?
	@return OctreeRegion<T>
]=]
function OctreeRegionUtils.create(px, py, pz, sx, sy, sz, parent, parentIndex)
	local hsx, hsy, hsz = sx/2, sy/2, sz/2

	local region = {
		subRegions = {
			--topNorthEast
			--topNorthWest
			--topSouthEast
			--topSouthWest
			--bottomNorthEast
			--bottomNorthWest
			--bottomSouthEast
			--bottomSouthWest
		};
		lowerBounds = { px - hsx, py - hsy, pz - hsz };
		upperBounds = { px + hsx, py + hsy, pz + hsz };
		position = { px, py, pz };
		size = { sx, sy, sz }; -- { sx, sy, sz }
		parent = parent;
		depth = parent and (parent.depth + 1) or 1;
		parentIndex = parentIndex;
		nodes = {}; -- [node] = true (contains subchild nodes too)
		node_count = 0;
	}

	-- if region.depth >= 5 then
	-- 	OctreeRegionUtils.visualize(region)
	-- end

	return region
end

--[=[
	Adds a node to the lowest subregion
	@param lowestSubregion OctreeRegion<T>
	@param node OctreeNode
]=]
function OctreeRegionUtils.addNode(lowestSubregion, node)
	assert(node, "Bad node")

	local current = lowestSubregion
	while current do
		if not current.nodes[node] then
			current.nodes[node] = node
			current.node_count = current.node_count + 1
		end
		current = current.parent
	end
end

--[=[
	Moves a node from one region to another

	@param fromLowest OctreeRegion<T>
	@param toLowest OctreeRegion<T>
	@param node OctreeNode
]=]
function OctreeRegionUtils.moveNode(fromLowest, toLowest, node)
	assert(fromLowest.depth == toLowest.depth, "fromLowest.depth ~= toLowest.depth")
	assert(fromLowest ~= toLowest, "fromLowest == toLowest")

	local currentFrom = fromLowest
	local currentTo = toLowest
	while currentFrom ~= currentTo do
		-- remove from current
		do
			assert(currentFrom.nodes[node], "Not in currentFrom")
			assert(currentFrom.node_count > 0, "No nodes in currentFrom")

			currentFrom.nodes[node] = nil
			currentFrom.node_count = currentFrom.node_count - 1

			-- remove subregion!
			if currentFrom.node_count <= 0 and currentFrom.parentIndex then
				assert(currentFrom.parent, "Bad currentFrom.parent")
				assert(currentFrom.parent.subRegions[currentFrom.parentIndex] == currentFrom, "Not in subregion")
				currentFrom.parent.subRegions[currentFrom.parentIndex] = nil
			end
		end

		-- add to new
		do
			assert(not currentTo.nodes[node], "Failed to add")
			currentTo.nodes[node] = node
			currentTo.node_count = currentTo.node_count + 1
		end

		currentFrom = currentFrom.parent
		currentTo = currentTo.parent
	end
end

--[=[
	Removes a node from the given region

	@param lowestSubregion OctreeRegion<T>
	@param node OctreeNode
]=]
function OctreeRegionUtils.removeNode(lowestSubregion, node)
	assert(node, "Bad node")

	local current = lowestSubregion
	while current do
		assert(current.nodes[node], "Not in current")
		assert(current.node_count > 0, "Current has bad node count")

		current.nodes[node] = nil
		current.node_count = current.node_count - 1

		-- remove subregion!
		if current.node_count <= 0 and current.parentIndex then
			assert(current.parent, "No parent")
			assert(current.parent.subRegions[current.parentIndex] == current, "Not in subregion")
			current.parent.subRegions[current.parentIndex] = nil
		end

		current = current.parent
	end
end


--[=[
	Retrieves the search radius for a given radius given the region
	diameter

	@param radius number
	@param diameter number
	@param epsilon number
	@return number
]=]
function OctreeRegionUtils.getSearchRadiusSquared(radius, diameter, epsilon)
	local diagonal = SQRT_3_OVER_2*diameter
	local searchRadius = radius + diagonal
	return searchRadius*searchRadius + epsilon
end

-- luacheck: push ignore
--[=[
	Adds all octree nod values to objectsFound

	See basic algorithm:
	https://github.com/PointCloudLibrary/pcl/blob/29f192af57a3e7bdde6ff490669b211d8148378f/octree/include/pcl/octree/impl/octree_search.hpp#L309

	@param region OctreeRegion<T>
	@param radius number
	@param px number
	@param py number
	@param pz number
	@param objectsFound { T }
	@param nodeDistances2 { number }
	@param maxDepth number
]=]
function OctreeRegionUtils.getNeighborsWithinRadius(region, radius, px, py, pz, objectsFound, nodeDistances2, maxDepth)
-- luacheck: pop
	assert(maxDepth, "Bad maxDepth")

	local childDiameter = region.size[1]/2
	local searchRadiusSquared = OctreeRegionUtils.getSearchRadiusSquared(radius, childDiameter, EPSILON)

	local radiusSquared = radius*radius

	-- for each child
	for _, childRegion in pairs(region.subRegions) do
		local cposition = childRegion.position
		local cpx, cpy, cpz = cposition[1], cposition[2], cposition[3]

		local ox, oy, oz = px - cpx, py - cpy, pz - cpz
		local dist2 = ox*ox + oy*oy + oz*oz

		-- within search radius
		if dist2 <= searchRadiusSquared then
			if childRegion.depth == maxDepth then
				for node, _ in pairs(childRegion.nodes) do
					local npx, npy, npz = node:GetRawPosition()
					local nox, noy, noz = px - npx, py - npy, pz - npz
					local ndist2 = nox*nox + noy*noy + noz*noz
					if ndist2 <= radiusSquared then
						objectsFound[#objectsFound + 1] = node:GetObject()
						nodeDistances2[#nodeDistances2 + 1] = ndist2
					end
				end
			else
				OctreeRegionUtils.getNeighborsWithinRadius(
					childRegion, radius, px, py, pz, objectsFound, nodeDistances2, maxDepth)
			end
		end
	end
end

--[=[
	Recursively ensures that a subregion exists at a given depth, and returns
	that region for usage.

	@param region OctreeRegion<T> -- Top level region
	@param px number
	@param py number
	@param pz number
	@param maxDepth number
	@return OctreeRegion<T>
]=]
function OctreeRegionUtils.getOrCreateSubRegionAtDepth(region, px, py, pz, maxDepth)
	local current = region
	for _ = region.depth, maxDepth do
		local index = OctreeRegionUtils.getSubRegionIndex(current, px, py, pz)
		local _next = current.subRegions[index]

		-- construct
		if not _next then
			_next = OctreeRegionUtils.createSubRegion(current, index)
			current.subRegions[index] = _next
		end

		-- iterate
		current = _next
	end
	return current
end

--[=[
	Creates a subregion for an octree.
	@param parentRegion OctreeRegion<T>
	@param parentIndex number
	@return OctreeRegion<T>
]=]
function OctreeRegionUtils.createSubRegion(parentRegion, parentIndex)
	local size = parentRegion.size
	local position = parentRegion.position
	local multiplier = SUB_REGION_POSITION_OFFSET[parentIndex]

	local px = position[1] + multiplier[1]*size[1]
	local py = position[2] + multiplier[2]*size[2]
	local pz = position[3] + multiplier[3]*size[3]
	local sx, sy, sz = size[1]/2, size[2]/2, size[3]/2

	return OctreeRegionUtils.create(px, py, pz, sx, sy, sz, parentRegion, parentIndex)
end

--[=[
	Computes whether a region is in bounds.

	Consider regions to be range [px, y).

	@param region OctreeRegion<T>
	@param px number
	@param py number
	@param pz number
	@return boolean
]=]
function OctreeRegionUtils.inRegionBounds(region, px, py, pz)
	local lowerBounds = region.lowerBounds
	local upperBounds = region.upperBounds
	return (
		px >= lowerBounds[1] and px <= upperBounds[1] and
		py >= lowerBounds[2] and py <= upperBounds[2] and
		pz >= lowerBounds[3] and pz <= upperBounds[3]
	)
end

--[=[
	Gets a subregion's internal index.

	@param region OctreeRegion<T>
	@param px number
	@param py number
	@param pz number
	@return number
]=]
function OctreeRegionUtils.getSubRegionIndex(region, px, py, pz)
	local index = px > region.position[1] and 1 or 2
	if py <= region.position[2] then
		index = index + 4
	end

	if pz >= region.position[3] then
		index = index + 2
	end
	return index
end

--[=[
	This definitely collides fairly consistently

	See: https://stackoverflow.com/questions/5928725/hashing-2d-3d-and-nd-vectors

	@param cx number
	@param cy number
	@param cz number
	@return number
]=]
function OctreeRegionUtils.getTopLevelRegionHash(cx, cy, cz)
	-- Normally you would modulus this to hash table size, but we want as flat of a structure as possible
	return cx * 73856093 + cy*19351301 + cz*83492791
end

--[=[
	Computes the index for a top level cell given a position

	@param maxRegionSize OctreeVector3
	@param px number
	@param py number
	@param pz number
	@return number -- rpx
	@return number -- rpy
	@return number -- rpz
]=]
function OctreeRegionUtils.getTopLevelRegionCellIndex(maxRegionSize, px, py, pz)
	return math.floor(px / maxRegionSize[1] + 0.5),
		math.floor(py / maxRegionSize[2] + 0.5),
		math.floor(pz / maxRegionSize[3] + 0.5)
end

--[=[
	Computes a top-level region's position

	@param maxRegionSize OctreeVector3
	@param cx number
	@param cy number
	@param cz number
	@return number
	@return number
	@return number
]=]
function OctreeRegionUtils.getTopLevelRegionPosition(maxRegionSize, cx, cy, cz)
	return maxRegionSize[1] * cx,
		maxRegionSize[2] * cy,
		maxRegionSize[3] * cz
end

--[=[
	Given a top-level region, returns if the region position are equal
	to this region

	@param region OctreeRegion<T>
	@param rpx number
	@param rpy number
	@param rpz number
	@return boolean
]=]
function OctreeRegionUtils.areEqualTopRegions(region, rpx, rpy, rpz)
	local position = region.position
	return position[1] == rpx
		and position[2] == rpy
		and position[3] == rpz
end

--[=[
	Given a world space position, finds the current region in the hashmap

	@param regionHashMap { [number]: { OctreeRegion<T> } }
	@param maxRegionSize OctreeVector3
	@param px number
	@param py number
	@param pz number
	@return OctreeRegion3?
]=]
function OctreeRegionUtils.findRegion(regionHashMap, maxRegionSize, px, py, pz)
	local cx, cy, cz = OctreeRegionUtils.getTopLevelRegionCellIndex(maxRegionSize, px, py, pz)
	local hash = OctreeRegionUtils.getTopLevelRegionHash(cx, cy, cz)

	local regionList = regionHashMap[hash]
	if not regionList then
		return nil
	end

	local rpx, rpy, rpz = OctreeRegionUtils.getTopLevelRegionPosition(maxRegionSize, cx, cy, cz)
	for _, region in pairs(regionList) do
		if OctreeRegionUtils.areEqualTopRegions(region, rpx, rpy, rpz) then
			return region
		end
	end

	return nil
end

--[=[
	Gets the current region for a position, or creates a new one.

	@param regionHashMap { [number]: { OctreeRegion<T> } }
	@param maxRegionSize OctreeVector3
	@param px number
	@param py number
	@param pz number
	@return OctreeRegion<T>
]=]
function OctreeRegionUtils.getOrCreateRegion(regionHashMap, maxRegionSize, px, py, pz)
	local cx, cy, cz = OctreeRegionUtils.getTopLevelRegionCellIndex(maxRegionSize, px, py, pz)
	local hash = OctreeRegionUtils.getTopLevelRegionHash(cx, cy, cz)

	local regionList = regionHashMap[hash]
	if not regionList then
		regionList = {}
		regionHashMap[hash] = regionList
	end

	local rpx, rpy, rpz = OctreeRegionUtils.getTopLevelRegionPosition(maxRegionSize, cx, cy, cz)
	for _, region in pairs(regionList) do
		if OctreeRegionUtils.areEqualTopRegions(region, rpx, rpy, rpz) then
			return region
		end
	end

	local region = OctreeRegionUtils.create(
		rpx, rpy, rpz,
		maxRegionSize[1], maxRegionSize[2], maxRegionSize[3])
	table.insert(regionList, region)

	return region
end



--== MARK: Octree
--[=[
	Constructs a new Octree.

	@return Octree<T>
]=]
function Octree.new()
	local self = setmetatable({}, Octree)

	self._maxRegionSize = { 512, 512, 512 } -- these should all be the same number
	self._maxDepth = 4
	self._regionHashMap = {} -- [hash] = region

	return self
end

--[=[
	Returns all octree nodes stored in the octree!

	```lua
	local octree = Octree.new()
	octree:CreateNode(Vector3.zero, "Hi")
	octree:CreateNode(Vector3.zero, "Bob")
	print(octree:GetAllNodes()) --> { "Hi", "Bob" }
	```

	Order is not guaranteed.

	:::warning
	If you have 100,000 nodes in your octree, this is going to be very slow.
	:::

	@return { OctreeNode<T> }
]=]
function Octree:GetAllNodes()
	local options = {}

	for _, regionList in pairs(self._regionHashMap) do
		for _, region in pairs(regionList) do
			for node, _ in pairs(region.nodes) do
				options[#options+1] = node
			end
		end
	end

	return options
end

--[=[
	Creates a new OctreeNode at the given position which can be retrieved

	:::tip
	Be sure to call :Destroy() on a node if the data becomes stale. Note that
	this is not necessary if the whole octree is removed from memory.
	:::

	```lua
	local octree = Octree.new()
	octree:CreateNode(Vector3.zero, "A")
	octree:CreateNode(Vector3.zero, "B")
	```

	@param position Vector3
	@param object T
	@return OctreeNode<T>
]=]
function Octree:CreateNode(position, object)
	assert(typeof(position) == "Vector3", "Bad position value")
	assert(object, "Bad object value")

	local node = OctreeNode.new(self, object)

	node:SetPosition(position)

	return node
end

--[=[
	Searches at the position and radius for any objects that may be within
	this radius.

	```lua
	local octree = Octree.new()
	octree:CreateNode(Vector3.zero, "A")
	octree:CreateNode(Vector3.zero, "B")
	octree:CreateNode(Vector3.new(0, 0, 1000), "C")
	print(octree:RadiusSearch(Vector3.zero, 100)) --> { "A", "B" }
	```

	@param position Vector3
	@param radius number
	@return { T } -- Objects found
	@return { number } -- Distances squared
]=]
function Octree:RadiusSearch(position, radius)
	assert(typeof(position) == "Vector3", "Bad position")
	assert(type(radius) == "number", "Bad radius")

	local px, py, pz = position.X, position.Y, position.Z
	return self:_radiusSearch(px, py, pz, radius)
end

--[=[
	Searches at the position and radius for any objects that may be within
	this radius. Returns the knearest entries.

	The closest entities will be first in the list.

	@param position Vector3
	@param k number -- Number of objects to find
	@param radius number
	@return { any } -- Objects found
	@return { number } -- Distances squared
]=]
function Octree:KNearestNeighborsSearch(position, k, radius)
	assert(typeof(position) == "Vector3", "Bad position")
	assert(type(radius) == "number", "Bad radius")

	local px, py, pz = position.Z, position.Y, position.Z
	local objects, nodeDistances2 = self:_radiusSearch(px, py, pz, radius)

	local sortable = {}
	for index, dist2 in pairs(nodeDistances2) do
		table.insert(sortable, {
			dist2 = dist2;
			index = index;
		})
	end

	table.sort(sortable, function(a, b)
		return a.dist2 < b.dist2
	end)

	local knearest = {}
	local knearestDist2 = {}
	for i = 1, math.min(#sortable, k) do
		local sorted = sortable[i]
		knearestDist2[#knearestDist2 + 1] = sorted.dist2
		knearest[#knearest + 1] = objects[sorted.index]
	end

	return knearest, knearestDist2
end

--[=[
	Internal API to create lowest subregion

	@private
	@param px number
	@param py number
	@param pz number
	@return OctreeSubregion
]=]
function Octree:GetOrCreateLowestSubRegion(px, py, pz)
	local region = self:_getOrCreateRegion(px, py, pz)
	return OctreeRegionUtils.getOrCreateSubRegionAtDepth(region, px, py, pz, self._maxDepth)
end

local OCTEPSILON = 1e-9;
function Octree:_radiusSearch(px, py, pz, radius)
	local objectsFound = {}
	local nodeDistances2 = {}

	local diameter = self._maxRegionSize[1]
	local searchRadiusSquared = OctreeRegionUtils.getSearchRadiusSquared(radius, diameter, OCTEPSILON)

	for _, regionList in pairs(self._regionHashMap) do
		for _, region in pairs(regionList) do
			local rpos = region.position
			local rpx, rpy, rpz = rpos[1], rpos[2], rpos[3]
			local ox, oy, oz = px - rpx, py - rpy, pz - rpz
			local dist2 = ox*ox + oy*oy + oz*oz

			if dist2 <= searchRadiusSquared then
				OctreeRegionUtils.getNeighborsWithinRadius(
					region, radius, px, py, pz, objectsFound, nodeDistances2, self._maxDepth)
			end
		end
	end

	return objectsFound, nodeDistances2
end

function Octree:_getRegion(px, py, pz)
	return OctreeRegionUtils.findRegion(self._regionHashMap, self._maxRegionSize, px, py, pz)
end

function Octree:_getOrCreateRegion(px, py, pz)
	return OctreeRegionUtils.getOrCreateRegion(self._regionHashMap, self._maxRegionSize, px, py, pz)
end

return Octree;