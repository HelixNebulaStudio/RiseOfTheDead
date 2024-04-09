local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modVoxelSpace = require(game.ReplicatedStorage.Library.VoxelSpace);
--==
local WaveCollapseSystem = {};
WaveCollapseSystem.ClassName = "WaveCollapseSystem";
WaveCollapseSystem.__index = WaveCollapseSystem;

WaveCollapseSystem.DebugParts = false;
WaveCollapseSystem.DebugSups = false;

local edgePiecePrefab = script:WaitForChild("Edgepiece");
local sectionLettersFolder = script:WaitForChild("SectionLetters");
local sectionLetterPrefabs = {};

--==
local adjAxis = {
	["xAxis"]=Vector3.xAxis; 
	["nxAxis"]=-Vector3.xAxis; 
	["zAxis"]=Vector3.zAxis; 
	["nzAxis"]=-Vector3.zAxis;
	["yAxis"]=Vector3.yAxis;
	["nyAxis"]=-Vector3.yAxis;
};

-- system order y, z, x;
function WaveCollapseSystem.new(collapseMapTemplate, seed)
	local self = {
		Seed = seed;
		Rng = Random.new(seed or 1);
		
		Queue = {};
		CollapseBuffer = {};
		
		VoxelSpace = modVoxelSpace.new();
		GridSize = collapseMapTemplate:GetAttribute("GridSize");
		
		Prototypes = {};
		TileGroupTypes = {};
		TileGroupPrefabs = {};
		Variants = {};
		
		TotalTileCount = 0;
		TotalGroupCount = 0;
		
		DisabledEntropies = {};
		
		GroupCounts = {};
		SuperpositionGroups = {};
		
		DebugPartsCache = {};
	};
	setmetatable(self, WaveCollapseSystem);
	
	self.VoxelSpace.StepSize = 1;
	self.Superpositions = self.VoxelSpace.Voxels;
	
	local descendants = collapseMapTemplate:GetDescendants();
	local allTileBasesList = {};
	
	local index = 0;
	for _, obj in pairs(descendants) do
		if obj.Name ~= ".TileBase" then continue end;
		
		local pos = obj.Position;
		local key = pos.X..","..pos.Z..","..pos.Y;
				
		if allTileBasesList[key] then
			Debugger:Warn("key", key, "already exist");
		end
		allTileBasesList[key] = obj;
	end
	
	
	local children = collapseMapTemplate:GetChildren();
	for a=1, #children do
		local tileModel = children[a];
		local tileModelId = tileModel.Name;
		
		if tileModel:GetAttribute("StartTile") then
			self.StartTileModel = tileModel;
		end
		
		if tileModel:GetAttribute("VariantBase") == true then
			if self.Variants[tileModel.Name] == nil then
				self.Variants[tileModel.Name] = {};
			end
		end
		
		local tileBases = {};
		
		for _, obj in pairs(tileModel:GetChildren()) do
			if obj.Name == ".TileBase" then
				table.insert(tileBases, obj);
			end
		end
		
		table.sort(tileBases, function(a, b)
			--return a.Position.X + a.Position.Z^2 + a.Position.Y^3 < b.Position.X + b.Position.Z^2 + b.Position.Y^3;
			return tostring(a.Position.X.. a.Position.Y.. a.Position.Z) < tostring(a.Position.X.. a.Position.Y.. a.Position.Z);
		end)
		
		if self.TileGroupPrefabs[tileModelId] == nil then
			self.TileGroupPrefabs[tileModelId] = tileModel;
		end
		
		if self.TileGroupTypes[tileModelId] == nil then
			self.TileGroupTypes[tileModelId] = {};
			
		end
		local tileGroupType = self.TileGroupTypes[tileModelId];
		
		local groupOrigin;
		for b=1, #tileBases do
			tileModel:SetAttribute("TilesCount", #tileBases);
			
			local tileBasePos = tileBases[b].Position;
			if groupOrigin == nil then
				groupOrigin = tileBasePos;
			end

			local relativePos = (tileBasePos - groupOrigin) / self.GridSize;
			
			local tileBaseId = tileModelId..":"..b;
			
			local prototypeInfo = self.Prototypes[tileBaseId] or {
				Id = tileBaseId;
				TileModel = tileModel;
				Index = b;
				LastIndex = #tileBases;
				
				Bases = {};
				RelativePos = nil;
				
				AdjacentTiles = {};
			};
			if self.Prototypes[tileBaseId] == nil then
				table.insert(tileGroupType, prototypeInfo);
				self.Prototypes[tileBaseId] = prototypeInfo;
			end
			
			if prototypeInfo.Offset == nil then -- b == 1 and
				local groupBasePos = prototypeInfo.TileModel.PrimaryPart.Position;
				local offset = groupBasePos - tileBasePos;
				
				prototypeInfo.Offset = offset;
			end
			
			if prototypeInfo.RelativePos ~= nil and prototypeInfo.RelativePos ~= relativePos then
				Debugger:Warn("RelativePos collision", prototypeInfo.Id, prototypeInfo.RelativePos, relativePos);
			end
			prototypeInfo.RelativePos = relativePos
			
			table.insert(prototypeInfo.Bases, tileBases[b]);
			
			tileBases[b].Name = tileBaseId;
			tileBases[b]:SetAttribute("Index", b);
			tileBases[b]:SetAttribute("RelativePos", relativePos);
		end
	end
	
	for variantName, _ in pairs(self.Variants) do
		local variantsList = self.Variants[variantName];
		
		for groupId, prototypesList in pairs(self.TileGroupTypes) do
			if groupId ~= variantName and groupId:sub(1, #variantName) == variantName then
				table.insert(variantsList, groupId);
			end
		end
	end
	
	for tileKey, tileBase in pairs(allTileBasesList) do
		local tileBasePos = tileBase.Position;
		local tileBaseId = tileBase.Name;
		
		local prototypeInfo = self.Prototypes[tileBaseId];
		
		for _, axisVec in pairs(adjAxis) do
			local addPos = axisVec * self.GridSize;
			local tarPos = tileBasePos + addPos;

			local key = tarPos.X..","..tarPos.Z..","..tarPos.Y;

			local adjTileBase = allTileBasesList[key];
			if adjTileBase then
				if prototypeInfo.AdjacentTiles[axisVec] == nil then
					prototypeInfo.AdjacentTiles[axisVec] = {};
				end
				local adjTilesList = prototypeInfo.AdjacentTiles[axisVec];
				local adjPrototypeInfo = self.Prototypes[adjTileBase.Name];
				
				if prototypeInfo.TileModel:GetAttribute("VariantBase") == true then
					local variantsList = self.Variants[prototypeInfo.TileModel.Name];

					for a=1, #variantsList do
						local tileGroupType = self.TileGroupTypes[variantsList[a]];
						local variantPrototype;

						for b=1, #tileGroupType do
							if tileGroupType[b].RelativePos == prototypeInfo.RelativePos then
								variantPrototype = tileGroupType[b];
								break;
							end
						end
						
						if variantPrototype then
							local varientTilesList = variantPrototype.AdjacentTiles[axisVec];
							if varientTilesList == nil then
								variantPrototype.AdjacentTiles[axisVec] = {};
								varientTilesList = variantPrototype.AdjacentTiles[axisVec];
							end
							
							if adjPrototypeInfo.TileModel:GetAttribute("VariantBase") == true then
								local adjVariantsList = self.Variants[adjPrototypeInfo.TileModel.Name];

								for c=1, #adjVariantsList do
									local adjTileGroupType = self.TileGroupTypes[adjVariantsList[c]];
									local adjVariantPrototype;
									
									for d=1, #adjTileGroupType do
										if adjTileGroupType[d].RelativePos == adjPrototypeInfo.RelativePos then
											adjVariantPrototype = adjTileGroupType[d];
											break;
										end
									end
									
									if adjVariantPrototype then
										if table.find(varientTilesList, adjVariantPrototype.Id) == nil then
											table.insert(varientTilesList, adjVariantPrototype.Id);
										end
									end
									
								end

							else
								if table.find(varientTilesList, adjPrototypeInfo.Id) == nil then
									table.insert(varientTilesList, adjPrototypeInfo.Id);
								end

							end

						end
					end

				else
					if adjPrototypeInfo.TileModel:GetAttribute("VariantBase") == true then
						local variantsList = self.Variants[adjPrototypeInfo.TileModel.Name];

						for a=1, #variantsList do
							local tileGroupType = self.TileGroupTypes[variantsList[a]];
							for b=1, #tileGroupType do
								local variantPrototype = tileGroupType[b];
								
								if variantPrototype.RelativePos == adjPrototypeInfo.RelativePos 
									and table.find(adjTilesList, variantPrototype.Id) == nil then -- variantPrototype.TileModel:GetAttribute("VariantBase") ~= true and
									table.insert(adjTilesList, variantPrototype.Id);
									
								end
							end
						end

					else
						if table.find(adjTilesList, adjTileBase.Name) == nil then
							table.insert(adjTilesList, adjTileBase.Name);
						end

					end
					
				end

				
			end
		end
		
		tileBase.Archivable = false;
	end
	
	--Debugger:Log("prototypeTable", self.Prototypes);
	collapseMapTemplate.Parent = script;
	
	Debugger:Log("WCS initialized", self);
	
	return self;
end

local constraintBase = {
	CountLimit = 3;
	Count = 0;
	Weight = 1;
}
constraintBase.__index = constraintBase;

function WaveCollapseSystem:PrototypeConstraints(list)
	self.PrototypeConstraints = {};
	
	for _, tilePrefab in pairs(self.TileGroupPrefabs) do
		local tileModelId = tilePrefab.Name;
		
		local tileInfo = setmetatable(list[tileModelId] or {}, constraintBase);
		self.PrototypeConstraints[tileModelId] = tileInfo;

		if tilePrefab:GetAttribute("Deadend") == true then
			tileInfo.TotalCountRequirement = 8;
			tileInfo.Weight = 0.5;
			tileInfo.CountLimit = tileInfo.CountLimit + 2;
		end
	end
end



--==
local Superposition = {};
Superposition.ClassName = "Superposition";
Superposition.__index = Superposition;

function Superposition.new(system, gridPoint)
	local meta = {
		System = system;
	};
	meta.__index = meta;
	
	local self = {
		Parents = {};
		
		Position = gridPoint;
		Entropy = {};
	};
	
	for typeId, prototype in pairs(system.Prototypes) do
		table.insert(self.Entropy, typeId);
	end
	
	setmetatable(meta, Superposition);
	setmetatable(self, meta);
	
	return self;
end

function Superposition:RemoveEntropy(id)
	local index = table.find(self.Entropy, id);
	if index then
		table.remove(self.Entropy, index);
	end
end

function Superposition:DebugPart(color, transparency)
	local part = Instance.new("Part");
	part.CanCollide = false;
	part.CastShadow = false;
	part.Anchored = true;
	part.Size = Vector3.new(33, 33,33);
	part.Transparency = transparency or 0.3;
	part.Color = color or Color3.fromRGB(255, 162, 164);
	part.Position = self.Position * self.System.GridSize;
	part.Parent = workspace.CurrentCamera;
	
	return part;
end


function Superposition:Collapse(protoId)
	if self.Value ~= nil then return end;

	if protoId == nil then
		
		while #self.Entropy > 0 do
			local entIndex = nil;
			
			if #self.Entropy > 1 then
				local pickTable = {};

				local sortedWeight = {};
				for a=1, #self.Entropy do
					local protoId = self.Entropy[a];
					local prototypeInfo = self.System.Prototypes[protoId];
					local prototypeConstraints = self.System.PrototypeConstraints[prototypeInfo.TileModel.Name];

					table.insert(sortedWeight, {Index=a; Weight=prototypeConstraints.Weight;});
				end
				table.sort(sortedWeight, function(a, b) return a.Weight > b.Weight; end)

				local totalChance = 0;
				for a=1, #sortedWeight do
					totalChance = totalChance + sortedWeight[a].Weight;
					table.insert(pickTable, {Total=totalChance; Index=sortedWeight[a].Index});
				end

				local roll = self.System.Rng:NextNumber(0, totalChance);
				for a=1, #pickTable do
					if roll <= pickTable[a].Total then
						entIndex = pickTable[a].Index;
						break;
					end
				end
				
			else
				entIndex = 1;
				
			end
			protoId = self.Entropy[entIndex];
				
			local prototypeInfo = self.System.Prototypes[protoId];
			
			if self.System:CanFitPrototype(self, protoId) == false then
				if self.System.DebugParts == true then
					task.wait(5);
					Debugger:Warn(protoId, "does not fit");
				end
				table.remove(self.Entropy, entIndex);
				protoId = nil;
				
				continue;
			end
			
			local prototypeConstraints;
			
			if prototypeInfo then
				prototypeConstraints = self.System.PrototypeConstraints[prototypeInfo.TileModel.Name];
				
				if prototypeConstraints.CanSpawnFunc and prototypeConstraints.CanSpawnFunc() ~= true then
					Debugger:Warn("Fail CanSpawnFunc ", protoId);
					table.remove(self.Entropy, entIndex);
					protoId = nil;
					
				end
				
				if prototypeConstraints.TotalCountRequirement and self.System.TotalGroupCount < prototypeConstraints.TotalCountRequirement then
					Debugger:Warn("Insufficient TotalCountRequirement for ", protoId, "TotalGroupCount", self.System.TotalGroupCount);
					table.remove(self.Entropy, entIndex);
					protoId = nil;

				end

				if prototypeConstraints.Count >= prototypeConstraints.CountLimit then
					table.remove(self.Entropy, entIndex);
					protoId = nil;

				end
			end

			if protoId ~= nil then
				if prototypeConstraints then
					prototypeConstraints.Count = prototypeConstraints.Count + 1;
				end
				
				break;
			end
		end
	end

	self.Value = protoId or "nil";
	table.clear(self.Entropy);
	
	if self.System.DebugParts == true then
		self:DebugPart(Color3.fromRGB(190, 255, 178), 0.9).Name = self.Value;
	end
	if self.System.DebugSups == true then
		if self.Value == "nil" then
			self:DebugPart( Color3.fromRGB(255, 253, 183), 0.9).Name = self.Value;
		else
			self:DebugPart( Color3.fromRGB(255, 255, 153), 0.8).Name = self.Value;
		end
	end
	
	if protoId ~= nil then
		table.insert(self.System.CollapseBuffer, self);
		
		local prototypeInfo = self.System.Prototypes[self.Value];
		
		local tileGroupType = self.System.TileGroupTypes[prototypeInfo.TileModel.Name];
		local offsetOrigin = prototypeInfo.RelativePos;

		for a=1, #tileGroupType do
			local tilePrototype = tileGroupType[a];

			local tilePos = self.Position + tilePrototype.RelativePos - offsetOrigin;
			
			local tileVoxelPoint = self.System.VoxelSpace:GetOrDefault(tilePos, Superposition.new(self.System, tilePos));
			
			local tileSuperPosition = tileVoxelPoint.Value;
			if tileSuperPosition == self then continue end;
			
			if tileSuperPosition.Value ~= nil then
				if self.System.DebugParts == true then
					Debugger:Warn("Err collision detected",tilePos, tileSuperPosition.Value);
					
					tileSuperPosition:DebugPart();
					task.wait(10);
				end
				
			else
				tileSuperPosition.Value = tilePrototype.Id;
				table.clear(tileSuperPosition.Entropy);
				table.insert(self.System.CollapseBuffer, tileSuperPosition);

				if self.System.DebugParts == true then
					tileSuperPosition:DebugPart(Color3.fromRGB(190, 255, 178), 0.9).Name = tileSuperPosition.Value;
				end
				if self.System.DebugSups == true then
					if self.Value == "nil" then
						tileSuperPosition:DebugPart( Color3.fromRGB(255, 253, 183), 0.9).Name = self.Value;
					else
						tileSuperPosition:DebugPart( Color3.fromRGB(255, 255, 153), 0.8).Name = self.Value;
					end
				end
				
			end
			
		end
	end

end

function Superposition:SpawnEdge(axisKey)
	local newEdgePiece = edgePiecePrefab:Clone();

	local cf = CFrame.new(self.Position * self.System.GridSize);

	if axisKey == "xAxis" then
		cf = cf * CFrame.Angles(0, math.rad(180), 0);

	elseif axisKey == "nxAxis" then
		cf = cf * CFrame.Angles(0, math.rad(0), 0);

	elseif axisKey == "zAxis" then
		cf = cf * CFrame.Angles(0, math.rad(90), 0);

	elseif axisKey == "nzAxis" then
		cf = cf * CFrame.Angles(0, math.rad(-90), 0);

	end

	newEdgePiece:PivotTo(cf);
	newEdgePiece.Parent = self.System.ParentFolder;
	
	game.Debris:AddItem(newEdgePiece:FindFirstChild(".Base"), 0);
end

function Superposition:DebugEdge(axisKey)
	local pos;

	if axisKey == "xAxis" then
		pos = self.Position + Vector3.xAxis/2;

	elseif axisKey == "nxAxis" then
		pos = self.Position - Vector3.xAxis/2;

	elseif axisKey == "zAxis" then
		pos = self.Position + Vector3.zAxis/2;

	elseif axisKey == "nzAxis" then
		pos = self.Position - Vector3.zAxis/2;

	end
	
	if pos then
		local part = Instance.new("Part");
		part.CanCollide = false;
		part.CastShadow = false;
		part.Anchored = true;
		
		local xSize = (axisKey == "xAxis" or axisKey == "nxAxis") and 2 or self.System.GridSize;
		local zSize = (axisKey == "zAxis" or axisKey == "nzAxis") and 2 or self.System.GridSize;
		
		part.Size = Vector3.new(xSize, self.System.GridSize*1.1, zSize);
		
		part.Transparency = 0.3;
		part.Color = Color3.fromRGB(255, 162, 164);
		part.Position = pos * self.System.GridSize;
		part.Parent = workspace.CurrentCamera;
	end
end

function Superposition:Propagate()
	local prototypeInfo = self.System.Prototypes[self.Value];
	if prototypeInfo == nil then return end;

	if self.System.DebugParts == true then
		Debugger:Warn("[Pink] Propagate", self.Position, self.Value);
	end
	
	local selfDebugPart;
	if self.System.DebugParts == true then
		selfDebugPart = self:DebugPart(Color3.fromRGB(255, 55, 245));
		selfDebugPart.Name = self.Value;
		selfDebugPart.Size = selfDebugPart.Size*1.1;
	end
	
	for axisKey, axisVec in pairs(adjAxis) do
		local adjGridPoint = self.Position + axisVec;
		
		local adjSuperPosition = self.System.VoxelSpace:GetOrDefault(adjGridPoint, Superposition.new(self.System, adjGridPoint)).Value;

		local validAdjTiles = prototypeInfo.AdjacentTiles[axisVec];
		if validAdjTiles == nil then
			continue;
		end;
		
		local propaDebugPart;
		if self.System.DebugParts == true then
			propaDebugPart = adjSuperPosition:DebugPart(Color3.fromRGB(246, 255, 149));
			propaDebugPart.Size = propaDebugPart.Size*1.1;
		end
		
		
		if adjSuperPosition.Value == nil then
			if self.System.DebugParts == true then
				Debugger:Warn("[Yellow] Adj propagating", adjSuperPosition.Position, #adjSuperPosition.Entropy, validAdjTiles);
			end
			
			if table.find(adjSuperPosition.Parents, self) == nil then
				table.insert(adjSuperPosition.Parents, self);
			end
			
			for a=#adjSuperPosition.Entropy, 1, -1 do
				if table.find(validAdjTiles, adjSuperPosition.Entropy[a]) == nil then
					table.remove(adjSuperPosition.Entropy, a);
				end
			end
			
			for a=#adjSuperPosition.Entropy, 1, -1 do -- loop through available entropies;
				local entropyId = adjSuperPosition.Entropy[a];

				local prototypeFit = self.System:CanFitPrototype(adjSuperPosition, entropyId);
				if not prototypeFit then
					table.remove(adjSuperPosition.Entropy, a);
				end
				
				table.insert(self.System.Queue, adjSuperPosition);

				if self.System.DebugParts == true then
					task.wait(0.1);
					for a=1, #self.System.DebugPartsCache do
						game.Debris:AddItem(self.System.DebugPartsCache[a], 0);
					end
					table.clear(self.System.DebugPartsCache);
					task.wait(0.1);
				end
			end
			
			game.Debris:AddItem(propaDebugPart, 0);
			
		else			
			if self.System.DebugParts == true then
				Debugger:Warn("Adj already collapsed", adjSuperPosition.Position, adjSuperPosition.Value);
			end
			
		end
		
		game.Debris:AddItem(propaDebugPart, 0.1);
	end
	
	game.Debris:AddItem(selfDebugPart, 0);
end

--==

function WaveCollapseSystem:CanFitPrototype(superPosition, prototypeId)
	local prototypeInfo = self.Prototypes[prototypeId];

	--Debugger:Log("Fitting ", prototypeId);

	if prototypeInfo == nil then
		Debugger:Warn("entropyId does not exist:", prototypeId);
		return false;
	end

	local prototypeGroupId = prototypeInfo.TileModel.Name;

	local tileGroupType = self.TileGroupTypes[prototypeGroupId]; -- List of prototype segments;
	local offsetOrigin = prototypeInfo.RelativePos;

	local prototypeFit = true;
	for b=1, #tileGroupType do --Loop through segments of a group;
		local tilePrototype = tileGroupType[b];

		local tilePos = superPosition.Position + tilePrototype.RelativePos - offsetOrigin;

		local propagateSuperPosition = self.VoxelSpace:GetOrDefault(tilePos, Superposition.new(self, tilePos)).Value; 

		if self.DebugParts == true then
			table.insert(self.DebugPartsCache, propagateSuperPosition:DebugPart(Color3.fromRGB(65, 100, 255)));
		end

		if propagateSuperPosition.Value ~= nil and propagateSuperPosition.Value ~= tilePrototype.Id then
			--Debugger:Warn("Mismatch/collision ", propagateSuperPosition.Value, tilePrototype.Id);

			if self.DebugParts == true then
				script:SetAttribute("PauseGen", true);
				repeat
					task.wait();
				until script:GetAttribute("PauseGen") ~= true;
			end
			prototypeFit = false;
			break;
		end
	end
	
	return prototypeFit;
end


function WaveCollapseSystem:Solve(parent)
	Debugger:Warn("Solve using seed ", self.Seed);
	
	self.ParentFolder = parent;
	
	--generate voxel
	local originVoxel = self.VoxelSpace:GetOrDefault(Vector3.zero, Superposition.new(self, Vector3.zero));
	
	local prevSuperPosition = nil;
	table.insert(self.Queue, originVoxel.Value);
	
	while #self.Queue > 0 do
		if self.TotalTileCount % 25 == 0 then
			task.wait();
		end
		
		-- sort queue;
		table.sort(self.Queue, function(a, b) return #a.Entropy < #b.Entropy; end);
		
		-- process queue;
		local firstSuperPosition = self.Queue[1];
		table.remove(self.Queue, 1);
		
		if firstSuperPosition.Value ~= nil then 
			--Debugger:Log(firstSuperPosition.Position,"already processed."); 
			continue 
		end;
		
		-- Process first superposition;
		table.clear(self.CollapseBuffer);
		
		firstSuperPosition.Index = self.TotalTileCount;
		Debugger:Warn("Process superposition", self.TotalTileCount, "/", #self.Queue);

		--Collapse all adjacent to fit the active superposition and them to collapsebuffer.
		if self.TotalTileCount == 0 then
			firstSuperPosition:Collapse(self.TileGroupTypes[self.StartTileModel.Name][1].Id);
		else
			firstSuperPosition:Collapse();
		end

		self.TotalTileCount = self.TotalTileCount +1;
		
		if firstSuperPosition.Value and self.Prototypes[firstSuperPosition.Value] then
			-- spawn tile prefab;
			local prototypeInfo = self.Prototypes[firstSuperPosition.Value];

			local offset = prototypeInfo.Offset or Vector3.zero;

			local newModel = prototypeInfo.TileModel:Clone();
			newModel:PivotTo(CFrame.new(firstSuperPosition.Position * self.GridSize + offset));
			newModel.Parent = self.ParentFolder;
			newModel:SetAttribute("Index", self.TotalGroupCount);
			
			local layerLevel = firstSuperPosition.Position.Y;
			firstSuperPosition.LayerLevel = layerLevel;
			firstSuperPosition.Prefab = newModel;
			
			local spGroup = {};
			
			for a=1, #self.CollapseBuffer do
				local relativeSuperPosition = self.CollapseBuffer[a];
				
				relativeSuperPosition.LayerLevel = layerLevel;
				relativeSuperPosition.Prefab = newModel;
				
				table.insert(spGroup, relativeSuperPosition);
			end
			self.SuperpositionGroups[newModel] = spGroup;
			
			if #sectionLetterPrefabs <= 0 then
				for _, obj in pairs(sectionLettersFolder:GetChildren()) do
					local index = tonumber(obj.Name);
					sectionLetterPrefabs[index] = obj;
				end
			end
			
			local sectionIndex = math.ceil(self.TotalGroupCount/10);
			
			local layoutFolder = newModel:WaitForChild("Layout");
			for _, obj in pairs(layoutFolder:GetChildren()) do
				if obj.Name == "SectionLetter" then
					local new = sectionLetterPrefabs[sectionIndex];
					if new then
						new = new:Clone();
						
						new.Material = obj.Material;
						new.MaterialVariant = obj.MaterialVariant;
						new.Color = obj.Color;
						new.CFrame = obj.CFrame;

						new.Size = new.Size * obj.Size/new.Size;

						new.Parent = layoutFolder;
					end
					
					game.Debris:AddItem(obj, 0);
				end
			end
			
			game.Debris:AddItem(newModel:FindFirstChild(".GroupBase"), 0);
			
			self.TotalGroupCount = self.TotalGroupCount +1;
			
		else
			if firstSuperPosition.Value == "nil" then
				local collapsePart = firstSuperPosition:DebugPart();
				collapsePart.Name = "Rock_".. tostring(firstSuperPosition.Position);
				collapsePart.Material = Enum.Material.Slate;
				collapsePart.Transparency = 0;
				collapsePart.Size = Vector3.new(self.GridSize, self.GridSize, self.GridSize);
				local c = math.random(66, 95);
				collapsePart.Color = Color3.fromRGB(c,c,c);
				collapsePart.Parent = self.ParentFolder;
				
				if prevSuperPosition then
					if self.DebugParts == true then
						prevSuperPosition:DebugPart(Color3.fromRGB(58, 255, 130));
					end
					
				end
			end

		end
		
		-- debug
		if self.DebugParts == true then
			local buffer = {};
			for a=1, #self.CollapseBuffer do
				table.insert(buffer, self.CollapseBuffer[a].Position);
			end
			Debugger:Warn("CollapseBuffer", buffer);
			
		end
		--
		
		for a=1, #self.CollapseBuffer do
			local propagateSuperPosition = self.CollapseBuffer[a];
			
			propagateSuperPosition:Propagate();
		end
		
		prevSuperPosition = firstSuperPosition;
	end
	
	Debugger:Warn("Loop ",#self.Superpositions,"superpositions");
	for a=1, #self.Superpositions do
		local voxelPoint = self.Superpositions[a];
		local superPosition = voxelPoint.Value;
		
		local prototypeInfo = self.Prototypes[superPosition.Value];
		if prototypeInfo == nil then
			voxelPoint:SetTraversable(Vector3.zero, false);

			continue;
		end;
		
		
		if self.PrototypeConstraints[prototypeInfo.TileModel.Name].IsParent == false then -- Is child;
			
			local function getParent(baseSuperposition)
				for a=1, #baseSuperposition.Parents do
					local parentSuperposition = baseSuperposition.Parents[a];

					local parPrototypeInfo = self.Prototypes[parentSuperposition.Value];
					local parPrototypeConstraints = self.PrototypeConstraints[parPrototypeInfo.TileModel.Name];
					
					if parPrototypeConstraints and parPrototypeConstraints.IsParent == true then
						return parentSuperposition;
					end;
					
					local recurSuperposition = getParent(parentSuperposition);
					if recurSuperposition == superPosition then
						return nil;
						
					elseif recurSuperposition ~= nil then
						return recurSuperposition;
						
					end
				end
			end
			
			local parentSuperposition = getParent(superPosition);
			
			if parentSuperposition and parentSuperposition.Prefab then
				superPosition.Prefab.Parent = parentSuperposition.Prefab;
				
			end
		end
		
		
		for axisKey, axisVec in pairs(adjAxis) do
			local adjGridPoint = superPosition.Position + axisVec;
			local adjVoxel = self.VoxelSpace:GetOrDefault(adjGridPoint);
			local adjSuperPosition = adjVoxel.Value;
			local adjPrototypeInfo = self.Prototypes[adjSuperPosition.Value];
			
			local validAdjTiles = prototypeInfo.AdjacentTiles[axisVec];
			
			if validAdjTiles == nil or table.find(validAdjTiles, adjSuperPosition.Value) == nil then
				
				if validAdjTiles then
					superPosition:SpawnEdge(axisKey);
				end
				
				voxelPoint:SetTraversable(axisVec, false);
				if self.DebugSups == true then
					superPosition:DebugEdge(axisKey);
				end
				
			else
				if adjPrototypeInfo and prototypeInfo.TileModel.Name ~= adjPrototypeInfo.TileModel.Name then
					voxelPoint:SetTraversable(axisVec, true);
				end
				
			end
		end
	end
	
	Debugger:Warn("Generated ",self.TotalTileCount," Tiles");
end

function WaveCollapseSystem:GetEdgePoints()
	local edgeData = {};
	
	for a=1, #self.Superpositions do
		local voxelPoint = self.Superpositions[a];
		local superPosition = voxelPoint.Value;

		local prototypeInfo = self.Prototypes[superPosition.Value];
		if prototypeInfo == nil then continue end;
		
		
		for axisKey, axisVec in pairs(adjAxis) do
			local adjGridPoint = superPosition.Position + axisVec;
			local adjVoxel = self.VoxelSpace:GetOrDefault(adjGridPoint);
			local adjSuperPosition = adjVoxel.Value;

			local validAdjTiles = prototypeInfo.AdjacentTiles[axisVec];
			if validAdjTiles == nil or table.find(validAdjTiles, adjSuperPosition.Value) == nil then
				table.insert(edgeData, {
					AxisVec = axisVec;
					Superposition = superPosition;
					Position = superPosition.Position + axisVec/2;
				});
				
			end
		end
		
	end
	
	return edgeData;
end

function WaveCollapseSystem:GetSuperpositionGroup(prefab)
	return self.SuperpositionGroups[prefab];
end

function WaveCollapseSystem:GetGatesFromGroup(prefab: Model): {[number]: {VoxelPoint: Vector3, Axis: Vector3}}
	local gates = {};
	local group = self:GetSuperpositionGroup(prefab);
	if group == nil then return gates end;
	
	
	for a=1, #group do
		local voxelPoint = self.VoxelSpace:GetOrDefault(group[a].Position);
		local traversableList = voxelPoint and voxelPoint.Traversable;

		for spAxis, isDoorway in pairs(traversableList) do
			if isDoorway == true then				
				table.insert(gates, {
					VoxelPoint=voxelPoint;
					Axis=spAxis;
				})
			end
		end
	end
	
	return gates;
end

script:GetAttributeChangedSignal("PauseGen"):Connect(function()
	if script:GetAttribute("PauseGen") == true then
		Debugger:Warn("PauseGen", true);
	end
end)

return WaveCollapseSystem;
