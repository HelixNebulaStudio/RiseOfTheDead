local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Vars;
local RunService = game:GetService("RunService");
local UserInputService = game:GetService("UserInputService");

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modWeapons = require(game.ReplicatedStorage.Library.Weapons);
local modTools = require(game.ReplicatedStorage.Library.Tools);
local modWorkbenchLibrary = require(game.ReplicatedStorage.Library:WaitForChild("WorkbenchLibrary"));
local modColorsLibrary = require(game.ReplicatedStorage.Library:WaitForChild("ColorsLibrary"));
local modItemLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modClothingLibrary = require(game.ReplicatedStorage.Library.ClothingLibrary);
local modCustomizeAppearance = require(game.ReplicatedStorage.Library:WaitForChild("CustomizeAppearance"));
local modGarbageHandler = require(game.ReplicatedStorage.Library.GarbageHandler);
local modEventSignal = require(game.ReplicatedStorage.Library.EventSignal);
local modCustomizationData = require(game.ReplicatedStorage.Library.CustomizationData);

local modViewportUtil = require(game.ReplicatedStorage.Library.Util.ViewportUtil);
local modGuiObjectPlus = require(game.ReplicatedStorage.Library.UI.GuiObjectPlus);

local modData = require(game.Players.LocalPlayer:WaitForChild("DataModule") :: ModuleScript);

local remoteEquipCosmetics = game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AppearanceEditor"):WaitForChild("EquipCosmetics");
local starterCharacter = game.StarterPlayer:WaitForChild("StarterCharacter");

local remoteCustomizationData = modRemotesManager:Get("CustomizationData") :: RemoteFunction;

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
		PanSensitivity = 1.5;
		Angles = CFrame.Angles(0, 0, 0);
		Offset = CFrame.new(0, 0, 0);
		
		HightlightSelect=false;
		CloseVisible=true;
		SelectedHighlightParts={};

		HighlightPort=nil;
		HighlightPartClone=nil;
		
		OnSelectionChanged = modEventSignal.new("OnSelectionChanged");
		Garbage = modGarbageHandler.new();
	};
	
	self.Garbage:Tag(self.Frame.InputChanged:Connect(function(inputObject, gameProcessed)
		--if not self.Active then return end;
		if inputObject.UserInputType == Enum.UserInputType.MouseWheel then
			if self.Camera then
				self.Zoom = math.clamp(self.Zoom+0.5*-inputObject.Position.Z, 1, 8);

				self.PanSensitivity = math.clamp(self.PanSensitivity -(inputObject.Position.Z*0.2), 1.5, 4); 
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
	local inputStart = nil;
	
	self.Garbage:Tag(UserInputService.InputBegan:Connect(function(inputObject) 
		if inputObject.UserInputType ~= Enum.UserInputType.MouseButton1 and inputObject.UserInputType ~= Enum.UserInputType.Touch then return end;

		if modGuiObjectPlus.IsMouseOver(self.Frame) then
			inputStart = tick();
			selectDelta = self.CurrentHighlightPart;
		end
	
	end))
	self.Garbage:Tag(UserInputService.InputEnded:Connect(function(inputObject) 
		if inputObject.UserInputType ~= Enum.UserInputType.MouseButton1 and inputObject.UserInputType ~= Enum.UserInputType.Touch then return end;
		if inputStart == nil then return end;
		if selectDelta == nil then return end;
		if tick()-inputStart >= 0.2 then return end;

		if modGuiObjectPlus.IsMouseOver(self.Frame) and self.CurrentHighlightPart == selectDelta then
			if selectDelta == nil then
				table.clear(self.SelectedHighlightParts);
			else
				if not UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
					table.clear(self.SelectedHighlightParts);
				end
				if table.find(self.SelectedHighlightParts, self.CurrentHighlightPart) == nil then
					table.insert(self.SelectedHighlightParts, self.CurrentHighlightPart);
				end
			end
			(self.OnSelectionChanged :: any):Fire(self.SelectedHighlightParts, selectDelta);
			inputStart = 0;
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

	game.Debris:AddItem(self.HighlightPort, 0);
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
	
	local rayScanTick = tick();
	RunService:BindToRenderStep("ItemViewport"..self.Index, Enum.RenderPriority.Camera.Value-1, function(delta)
		if not self.Frame.Visible then 
			if self.HighlightPort then
				self.HighlightPort:Destroy();
				self.HighlightPort = nil;
			end
			if self.HighlightPartClone then
				self.HighlightPartClone:Destroy();
				self.HighlightPartClone = nil;
			end
			return
		end;
		local playerMouse = UserInputService:GetMouseLocation();

		if self.HightlightSelect then
			if self.HighlightPort == nil then
				self.HighlightPort = self.Frame:Clone();
				self.HighlightPort.Name = "HighlighPort";
				self.HighlightPort.ImageColor3 = Color3.fromRGB(255, 255, 255);

				self.Garbage:Tag(self.HighlightPort);
				self.HighlightPort.Parent = self.Frame.Parent;

			else
				self.HighlightPort.Visible = self.Frame.Visible;
				self.HighlightPort.Position = self.Frame.Position;
				self.HighlightPort.Size = self.Frame.Size;
				self.HighlightPort.AnchorPoint = self.Frame.AnchorPoint;
				self.HighlightPort.CurrentCamera = self.Frame.CurrentCamera;

				self.HighlightPort.ImageTransparency = 0.5 + 0.2 * math.sin(tick()*1.5);

			end

			if tick()-rayScanTick > 0.1 then
				rayScanTick = tick();
				local rayResult = nil;
				if modGuiObjectPlus.IsMouseOver(self.Frame) then
					rayResult = modViewportUtil.RaycastInViewportFrame(self.Frame, playerMouse.X, playerMouse.Y, 16, raycastParam);
				end
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

			if self.HighlightPort then
				if self.HighlightPartClone == nil or self.HighlightPartClone.Name ~= self.CurrentHighlightPart.Name then
					if self.HighlightPartClone then
						self.HighlightPartClone:Destroy();
					end

					self.HighlightPartClone = self.CurrentHighlightPart:Clone();
					self.HighlightPartClone:ClearAllChildren();
					self.HighlightPartClone.Material = Enum.Material.Neon;
					self.HighlightPartClone.Color = Color3.fromRGB(255, 255, 255);
					if self.HighlightPartClone:IsA("MeshPart") then
						self.HighlightPartClone.TextureID = "";
					end
					self.HighlightPartClone.Parent = self.HighlightPort;
				end

				self.HighlightPartClone.CFrame = self.CurrentHighlightPart.CFrame;
				self.HighlightPartClone.Size = self.CurrentHighlightPart.Size;
			end

		else
			self.Frame.highlightedLabel.Text = "";
			if self.HighlightPort then
				self.HighlightPort:ClearAllChildren();
				self.HighlightPartClone = nil;
			end

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
				math.clamp(posX + (playerMouse.X-OnClickX)/OnClickX*self.PanSensitivity, -4, 4),
				math.clamp(posY - (playerMouse.Y-OnClickY)/OnClickY*self.PanSensitivity, -4, 4),
				0
			):Lerp(CFrame.identity, 0.005);
		else
			OnClickX, OnClickY = nil;
			if spin and tick()-self.OrbitTick >= 1 then
				self.Rotor.WorldOrientation = Vector3.new(
					self.Rotor.WorldOrientation.X, 
					self.Rotor.WorldOrientation.Y +0.5, 
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
	
	local phantomValues = storageItem.PhantomValues or {};
	local customizationData = phantomValues._Customs;

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
				modCustomizeAppearance.ClientAddAccessory(characterModel, accessoryData, clothingLib.GroupName, storageItem);
			else
				Debugger:Warn("Could not load accessory:",clothingLib.Name);
			end

			table.insert(self.DisplayModels, {Prefab=characterModel;});
			self:RefreshDisplay();

			if yieldFunc then
				yieldFunc(self);
			end

			modCustomizeAppearance.RefreshIndex(characterModel);
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
					
					local prefix = "";
					if weldName == "LeftToolGrip" then
						prefix = "Left";
						prefab.Name = prefix..prefabName;
						prefab:SetAttribute("DisplayModelPrefix", "Left");

					elseif weldName == "RightToolGrip" then
						prefix = "Right";
						prefab.Name = prefix..prefabName;
						prefab:SetAttribute("DisplayModelPrefix", "Right");

					end
					prefab:SetAttribute("Grip", weldName);
					
					local displayOffset = itemDisplayLib[weldName.."Offset"];

					table.insert(self.DisplayModels, {
						WeldName=weldName; 
						Prefab=prefab; 
						BasePrefab=itemPrefabs[prefabName]; 
						Offset=displayOffset; 
						Prefix=prefix;
					});
				end
			end
		end
		
		self.PartDataList = modCustomizationData.LoadPartDataList(itemId, self.DisplayModels);
		modCustomizationData.ClientLoadCustomizations(storageItem, self.PartDataList);

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
	self.PartDataList = nil;

	if self.HighlightPort then
		self.HighlightPort:Destroy();
		self.HighlightPort = nil;
	end
	if self.HighlightPartClone then
		self.HighlightPartClone:Destroy();
		self.HighlightPartClone = nil;
	end

	pcall(function()
		self.Frame.ItemIcon.Image = "";
		self.Frame.ItemIcon.Visible = false;
	end)
end

return ItemViewport;