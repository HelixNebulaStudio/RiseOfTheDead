local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local MapLibrary = {};
MapLibrary.__index = MapLibrary;

MapLibrary.ActiveMap = {
	Local = {};
	Order = {};
}

MapLibrary.TypeIcons = {
	RampUp={Icon="rbxassetid://4621460246"; Color=Color3.fromRGB(120, 120, 120)};
	RampDown={Icon="rbxassetid://4621460357"; Color=Color3.fromRGB(120, 120, 120)};
}

--==
function MapLibrary:SetActiveMap(localGroup, orderList)
	MapLibrary.ActiveMap.Local = localGroup;
	MapLibrary.ActiveMap.Order = orderList;
	
end

function MapLibrary:LoadFolderAsMap(mapDataFolder)
	local modInteractables = require(game.ReplicatedStorage.Library.Interactables);
	
	local localGroup = {};
	local orderedByScale = {};
	
	local layer = mapDataFolder:GetChildren();
	for a=1, #layer do
		local layerModel = layer[a];
		local layerName = layerModel.Name;
		local layerData = {};

		local cframe, size = layerModel:GetBoundingBox();
		local layerObjects = layerModel:GetChildren();

		local hostileTag = layerModel:FindFirstChild("HostileZone");

		layerData.CFrame = cframe;
		layerData.Size = size;
		layerData.Data = {};
		layerData.HostileZone = hostileTag ~= nil;

		table.sort(layerObjects, function(a, b)
			if a:IsA("BasePart") and b:IsA("BasePart") then
				return a.Position.Y < b.Position.Y;
			end
			return false;
		end)

		local function newObjLayer(objectType, object)
			local cframe, size, orientation;
			
			if object:IsA("BasePart") then
				cframe, size = object.CFrame, object.Size;
				orientation = object.Orientation.Y;
				
			elseif object:IsA("Model") then
				cframe, size = object:GetBoundingBox();
				
			else
				return;
			end

			local interactableModule = object:FindFirstChild("Interactable");

			local icoInfo = MapLibrary.TypeIcons[object.Name];
			for iconType, iconInfo in pairs(modInteractables.TypeIcons) do
				if object.Name:match(iconType) then
					icoInfo = modInteractables.TypeIcons[iconType];
				end
			end
			
			local objInfo = {
				Object = object;
				Name = object.Name;
				Type = objectType;
				IconInfo = icoInfo;
				InteractableModule=interactableModule;
			}
			
			objInfo.GetSize = function()
				object = objInfo.Object;
				if object:IsA("BasePart") then
					cframe, size = object.CFrame, object.Size;
					orientation = object.Orientation.Y;

				elseif object:IsA("Model") then
					cframe, size = object:GetBoundingBox();

				else
					return;
				end
				
				local heightRatio = math.clamp(math.floor((size.Y/layerData.Size.Y)*10)/10, 0.1, 1);

				--objInfo.CFrame = cframe;
				--objInfo.Size = size;
				--objInfo.Orientation = orientation;
				--objInfo.HeightRatio = math.clamp(math.floor((objInfo.Size.Y/layerData.Size.Y)*10)/10, 0.1, 1);
				
				return cframe, size, orientation, heightRatio;
			end
			--objInfo.GetSize();
			
			table.insert(layerData.Data, objInfo);
		end

		for b=1, #layerObjects do
			newObjLayer(layerObjects[b].Name, layerObjects[b]);
		end

		local interactables = workspace:FindFirstChild("Interactables") and workspace.Interactables:GetChildren() or nil;
		if interactables then
			local scaleHalf = layerData.Size/2;
			local regionMin, regionMax = layerData.CFrame * -scaleHalf, layerData.CFrame * scaleHalf;

			for b=1, #interactables do
				local obj = interactables[b];
				local pos = obj:IsA("BasePart") and obj.Position or (obj:IsA("Model") and obj:GetBoundingBox()) or nil;
				if pos and pos.X > regionMin.X
					and pos.Y > regionMin.Y
					and pos.Z > regionMin.Z
					and pos.X < regionMax.X
					and pos.Y < regionMax.Y
					and pos.Z < regionMax.Z then
					
					local interactObj = obj:FindFirstChild("Interactable") and require(obj.Interactable) or nil;
					if interactObj then
						local objectType;
						for k, v in pairs(modInteractables.Types) do
							if interactObj.Type == v then
								objectType = k;
								break;
							end
						end
						newObjLayer(objectType, interactables[b]);
					end

				end	
			end
		end

		localGroup[layerName] = layerData;
		table.insert(orderedByScale, {LayerName=layerName; Scale=size.Magnitude;});
	end

	table.sort(orderedByScale, function(a, b) 
		return a.Scale < b.Scale;
	end)
	
	return localGroup, orderedByScale;
end

function MapLibrary:Initialize()
	task.spawn(function()
		if self.Init then return end;
		self.Init = true;
		
		local mapDataFolder = game.ReplicatedStorage:WaitForChild("MapLibraryData", 10);
		if mapDataFolder == nil then return end;
		
		MapLibrary:SetActiveMap(MapLibrary:LoadFolderAsMap(mapDataFolder));
	end)
end

function MapLibrary:LoadDynamicMap(dynamicMap)
	MapLibrary:SetActiveMap(MapLibrary:LoadFolderAsMap(dynamicMap));
	
end

function MapLibrary:GetLayer(position)
	for a=1, #MapLibrary.ActiveMap.Order do
		local layerName = MapLibrary.ActiveMap.Order[a].LayerName;
		local layerData = MapLibrary.ActiveMap.Local[layerName];
		
		local scaleHalf = layerData.Size/2;
		local regionMin, regionMax = layerData.CFrame * -scaleHalf, layerData.CFrame * scaleHalf;
		
		local inLayer = position.X > regionMin.X
		and position.Y > regionMin.Y
		and position.Z > regionMin.Z
		and position.X < regionMax.X
		and position.Y < regionMax.Y
		and position.Z < regionMax.Z;
		
		if inLayer then
			return layerName, layerData;
		end					
	end
end

return MapLibrary;
