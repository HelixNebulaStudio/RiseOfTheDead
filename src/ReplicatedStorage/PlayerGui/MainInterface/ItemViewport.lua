local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Vars;
local RunService = game:GetService("RunService");
local UserInputService = game:GetService("UserInputService");

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modWeapons = require(game.ReplicatedStorage.Library.Weapons);
local modTools = require(game.ReplicatedStorage.Library.Tools);
local modWorkbenchLibrary = require(game.ReplicatedStorage.Library:WaitForChild("WorkbenchLibrary"));
local modColorsLibrary = require(game.ReplicatedStorage.Library:WaitForChild("ColorsLibrary"));
local modItemLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modClothingLibrary = require(game.ReplicatedStorage.Library.ClothingLibrary);
local modCustomizeAppearance = require(game.ReplicatedStorage.Library:WaitForChild("CustomizeAppearance"));
local modGarbageHandler = require(game.ReplicatedStorage.Library.GarbageHandler);
local modEventSignal = require(game.ReplicatedStorage.Library.EventSignal);

local modViewportUtil = require(game.ReplicatedStorage.Library.Util.ViewportUtil);

local remoteEquipCosmetics = game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AppearanceEditor"):WaitForChild("EquipCosmetics");
local starterCharacter = game.StarterPlayer:WaitForChild("StarterCharacter");

local camera = workspace.CurrentCamera;

local diplayPortFrameTemplate = script:WaitForChild("DisplayPort");
local itemPrefabs = game.ReplicatedStorage.Prefabs:WaitForChild("Items");

local ItemViewport = {};
ItemViewport.__index = ItemViewport;
ItemViewport.Counter = 0;

type ItemViewportObject = {
	[any]: any;
}
export type ItemViewport = typeof(setmetatable({} :: ItemViewportObject, ItemViewport));
--== Script;
function ItemViewport.new() : ItemViewport
	ItemViewport.Counter = ItemViewport.Counter+1;
	
	local self = {
		Index = ItemViewport.Counter;
		Frame = diplayPortFrameTemplate:Clone();
		WorldModel = Instance.new("WorldModel");
		
		Active=true;
		OnDisplayID = nil;
		OnDisplayPackageId = nil;
		DisplayModels = {};
		Camera = nil;
		Zoom = 2;
		OrbitTick = tick();
		PanTick = tick();
		Angles = CFrame.Angles(0, 0, 0);
		Offset = CFrame.new(0, 0, 0);
		
		HightlightSelect=false;
		CloseVisible=true;
		SelectedHighlightParts={};
		
		OnSelectionChanged = modEventSignal.new("OnSelectionChanged");
		Garbage = modGarbageHandler.new();
	};
	
	self.Garbage:Tag(self.Frame.InputChanged:Connect(function(inputObject, gameProcessed)
		--if not self.Active then return end;
		if inputObject.UserInputType == Enum.UserInputType.MouseWheel then
			if self.Camera then
				self.Zoom = math.clamp(self.Zoom+0.5*-inputObject.Position.Z, 1, 8);
			end
		end
	end));

	self.Garbage:Tag(self.Frame.InputBegan:Connect(function(inputObject, gameProcessed)
		if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
			self.OrbitTick = nil;
			
		elseif inputObject.UserInputType == Enum.UserInputType.MouseButton2 then
			self.PanTick = nil;
			
		end
	end));

	self.Garbage:Tag(self.Frame.InputEnded:Connect(function(inputObject, gameProcessed)
		if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
			self.OrbitTick = tick();
		elseif inputObject.UserInputType == Enum.UserInputType.MouseButton2 then
			self.PanTick = tick();
		end
	end));
	
	setmetatable(self, ItemViewport);

	local selectDelta = nil;
	self.Garbage:Tag(UserInputService.InputBegan:Connect(function(inputObject) 
		if inputObject.UserInputType ~= Enum.UserInputType.MouseButton1 and inputObject.UserInputType ~= Enum.UserInputType.Touch then return end;
		selectDelta = self.CurrentHighlightPart;
	
	end))
	self.Garbage:Tag(UserInputService.InputEnded:Connect(function(inputObject) 
		if inputObject.UserInputType ~= Enum.UserInputType.MouseButton1 and inputObject.UserInputType ~= Enum.UserInputType.Touch then return end;

		if self.CurrentHighlightPart == selectDelta then
			if selectDelta == nil then
				table.clear(self.SelectedHighlightParts);
			else
				if not UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
					table.clear(self.SelectedHighlightParts);
				end
				table.insert(self.SelectedHighlightParts, self.CurrentHighlightPart);
			end
			self.OnSelectionChanged:Fire(self.SelectedHighlightParts, selectDelta);
		end

		selectDelta = nil;
		
	end))
	self.Garbage:Tag(function()
		selectDelta = nil;
		table.clear(self.SelectedHighlightParts);
		self.CurrentHighlightPart = nil;
	end)

	self.Frame:WaitForChild("touchCloseButton"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
		self:Destroy();
	end)

	return self;
end

function ItemViewport:SetZIndex(z)
	for _, obj in pairs(self.Frame:GetDescendants()) do
		if obj:IsA("GuiObject") then
			obj.ZIndex = z or 1;
		end
	end
	self.Frame.ZIndex = z or 1;
end

function ItemViewport:Destroy()
	self:Clear();
	self.OnSelectionChanged:Destroy();
	self.Garbage:Destruct();
	game.Debris:AddItem(self.Frame, 0);
end

function ItemViewport:RefreshDisplay()
	self.Frame.touchCloseButton.Visible = self.CloseVisible;
	
	if self.Camera == nil then
		self.Camera = workspace:FindFirstChild("DisplayPortCamera");
		self.Rotor = self.Camera and self.Camera:FindFirstChild("cframer") and self.Camera["cframer"]:FindFirstChild("att");
		if self.Camera == nil then
			self.Camera = Instance.new("Camera");
			self.Camera.Name = "DisplayPortCamera";
			self.Camera.CFrame = CFrame.new(0, 0, 0);
			self.Camera.Parent = workspace;
			
			local part = Instance.new("Part");
			part.Name = "cframer";
			part.Anchored = true;
			part.Parent = self.Camera;
			part.CFrame = CFrame.identity;
			part.Size = Vector3.new(0,0,0);
			part.Transparency = 1;
			part.CanCollide = false;
			
			self.Rotor = Instance.new("Attachment");
			self.Rotor.Name = "att";
			self.Rotor.Parent = part;
		end
	end
	
	RunService:UnbindFromRenderStep("ItemViewport"..self.Index);
	self.Frame.CurrentCamera = self.Camera;
	for a=1, #self.DisplayModels do
		self.DisplayModels[a].Prefab.Parent = self.WorldModel;
		self.DisplayModels[a].Prefab.PrimaryPart.Anchored = true;
	end
	self.WorldModel.Parent = self.Frame;
	
	local spin = true;
	local rate = 180/(camera.ViewportSize.X/camera.ViewportSize.Y);
	local OnClickX, OnClickY;
	local orX, orY, orZ = 0, 0, 0;
	local posX, posY = 0, 0;
	self.Rotor.WorldOrientation = Vector3.new(0, 180, 0);
	self.Rotor.WorldPosition = Vector3.new(0, 0, 0);
	self.Offset = CFrame.new(0, 0, 0);
	
	local raycastParam = RaycastParams.new();
	-- raycastParam.FilterType = Enum.RaycastFilterType.Include;
	-- raycastParam.FilterDescendantsInstances = self.DisplayModels;

	local rayScanTick = tick();
	RunService:BindToRenderStep("ItemViewport"..self.Index, Enum.RenderPriority.Camera.Value-1, function()
		local playerMouse = UserInputService:GetMouseLocation();

		if self.HightlightSelect then
			if tick()-rayScanTick > 0.1 then
				rayScanTick = tick();
				local rayResult = modViewportUtil.RaycastInViewportFrame(self.Frame, playerMouse.X, playerMouse.Y, 16, raycastParam);
				if rayResult then
					self.CurrentHighlightPart = rayResult.Instance;
				else
					self.CurrentHighlightPart = nil;
				end
			end
		else
			self.CurrentHighlightPart = nil;
		end

		if self.CurrentHighlightPart then
			self.Frame.highlightedLabel.Text = self.CurrentHighlightPart:GetAttribute("PartLabel") or self.CurrentHighlightPart.Name;
		else
			self.Frame.highlightedLabel.Text = "";
		end

		if self.OrbitTick == nil then
			if OnClickX == nil or OnClickY == nil then
				OnClickX = playerMouse.X;
				OnClickY = playerMouse.Y;
				orX, orY, orZ = self.Rotor.WorldOrientation.X, self.Rotor.WorldOrientation.Y, self.Rotor.WorldOrientation.Z;
				spin = false;
			end
			local x, y = (playerMouse.X-OnClickX)/OnClickX * rate, (playerMouse.Y-OnClickY)/OnClickY * rate;
			self.Rotor.WorldOrientation = Vector3.new(
				orX + (math.cos(math.rad(orY)) *y),
				orY + x,
				orZ + (math.sin(math.rad(orY)) *y)
			)
		elseif self.PanTick == nil then
			if OnClickX == nil or OnClickY == nil then
				OnClickX = playerMouse.X;
				OnClickY = playerMouse.Y;
				posX, posY = self.Offset.X, self.Offset.Y;
				spin = false;
			end
			self.Offset = CFrame.new(
				math.clamp(posX + (playerMouse.X-OnClickX)/OnClickX*1.5, -1, 1),
				math.clamp(posY - (playerMouse.Y-OnClickY)/OnClickY*1.5, -1, 1),
				0
			):Lerp(CFrame.identity, 0.005);
		else
			OnClickX, OnClickY = nil;
			if spin and tick()-self.OrbitTick >= 1 then
				self.Rotor.WorldOrientation = Vector3.new(
					self.Rotor.WorldOrientation.X, 
					self.Rotor.WorldOrientation.Y +1, 
					self.Rotor.WorldOrientation.Z
				):Lerp(Vector3.new(0, self.Rotor.WorldOrientation.Y +1, 0), 0.005);
			end
		end
		self.Angles = self.Angles:lerp(self.Rotor.CFrame, 0.4);
		
		for a=1, #self.DisplayModels do
			local prefab = self.DisplayModels[a].Prefab;
			if prefab == nil or prefab.PrimaryPart == nil then continue end;

			if prefab:FindFirstChild("CFraming") then self.DisplayModels[a].Offset = prefab.CFraming.Value end;
			local prefabCFrame = self.Camera.CFrame*self.Offset*self.Angles;
			prefab:PivotTo(prefabCFrame*(self.DisplayModels[a].Offset or CFrame.identity) + self.Camera.CFrame.lookVector*self.Zoom);
		
		end
	end)
end

function ItemViewport:SetDisplay(storageItem, yieldFunc)
	self:Clear();
	local itemId = storageItem.ItemId;
	local itemValues = storageItem.Values;
	self.OnDisplayID = storageItem.ID;
	
	local itemDisplayLib = modWorkbenchLibrary.ItemAppearance[itemId];
	local clothingLib = modClothingLibrary:Find(itemId);
	
	if clothingLib then
		local characterModel = starterCharacter:Clone();
		
		self.Zoom = 7;
		task.spawn(function()
			local packageId = itemValues.ActiveSkin or itemId;
			
			local accessoryData, _actionType = remoteEquipCosmetics:InvokeServer(itemId, packageId);
			
			local isSameModel = self.OnDisplayID ~= storageItem.ID;
			if self.OnDisplayPackageId ~= packageId then
				isSameModel = false;
			end

			if isSameModel then
				self:RefreshDisplay();
				return;
			end
			
			if accessoryData then
				modCustomizeAppearance.ClientAddAccessory(characterModel, accessoryData, clothingLib.GroupName);
			else
				Debugger:Warn("Could not load accessory:",clothingLib.Name);
			end

			table.insert(self.DisplayModels, {Prefab=characterModel;});
			self:RefreshDisplay();

			if yieldFunc then
				yieldFunc(self);
			end
		end)
		
	elseif itemDisplayLib then
		self.Zoom = 2;
		
		local toolLib = modWeapons[itemId] or modTools[itemId];
		for weldName, prefabName in pairs(toolLib.Welds) do
			-- weldName = ToolGrip, LeftToolGrip or RightToolGrip;
			if itemDisplayLib[weldName] then
				local prefab = itemPrefabs:FindFirstChild(prefabName) and itemPrefabs[prefabName]:Clone() or nil;
				if prefab then
					prefab:SetAttribute("ItemId", itemId);
					
					if weldName == "LeftToolGrip" then
						prefab.Name = "Left"..prefabName;
					elseif weldName == "RightToolGrip" then
						prefab.Name = "Right"..prefabName;
					end
					modColorsLibrary.ApplyAppearance(prefab, itemValues);
					
					local displayOffset = itemDisplayLib[weldName.."Offset"];
					table.insert(self.DisplayModels, {WeldName=weldName; Prefab=prefab; BasePrefab=itemPrefabs[prefabName]; Offset=displayOffset});
				end
			end
		end
		
	else
		local prefab = itemPrefabs:FindFirstChild(itemId) and itemPrefabs[itemId]:Clone() or nil;
		if prefab then
			table.insert(self.DisplayModels, {Prefab=prefab; BasePrefab=itemPrefabs[itemId];});
		else
			self.Frame.ItemIcon.Visible = true;
			local itemLib = modItemLibrary:Find(itemId);
			if itemLib then
				self.Frame.ItemIcon.Image = itemLib.Icon;
			end
		end
	end
	self:RefreshDisplay();
end

function ItemViewport:Clear()
	RunService:UnbindFromRenderStep("ItemViewport"..self.Index);
	for _, obj in pairs(self.WorldModel:GetChildren()) do
		obj:Destroy();
	end
	for a=1, #self.DisplayModels do
		game.Debris:AddItem(self.DisplayModels[a].Prefab, 0);
	end
	self.DisplayModels = {};
	self.OnDisplayID = nil;
	self.OnDisplayPackageId = nil;
	self.Frame.ItemIcon.Image = "";
	self.Frame.ItemIcon.Visible = false;
end

return ItemViewport;