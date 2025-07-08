local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local TextService = game:GetService("TextService");
local TweenService = game:GetService("TweenService");
local UserInputService = game:GetService("UserInputService");

local localPlayer = game.Players.LocalPlayer;

local modConfigurations = shared.require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));
local modBranchConfigs = shared.require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("BranchConfigurations"));
local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modKeyBindsHandler = shared.require(game.ReplicatedStorage.Library.KeyBindsHandler);
local modGameModeLibrary = shared.require(game.ReplicatedStorage.Library.GameModeLibrary);
local modRewardsLibrary = shared.require(game.ReplicatedStorage.Library.RewardsLibrary);
local modItem = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modMapLibrary = shared.require(game.ReplicatedStorage.Library.MapLibrary);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local modNpcProfileLibrary = shared.require(game.ReplicatedStorage.Library.NpcProfileLibrary);

local modItemInterface = shared.require(game.ReplicatedStorage.Library.UI.ItemInterface);

local SHOW_MAP_OBJECTS = {
	Wall=true;
	RampUp=true;
	RampDown=true;
	Door=true;
	Boss=true;
	Travel=true;
	Shop=true;
	GameModeEnter=true;
	GameModeExit=true;
	Tile=true;
};

local interfacePackage = {
    Type = "Character";
};
--==


function interfacePackage.newInstance(interface: InterfaceInstance)
    local modData = shared.require(localPlayer:WaitForChild("DataModule"));

local mapMenu = script:WaitForChild("MapFrame"):Clone();
	mapMenu.Parent = interface.ScreenGui;
	
	local locationPopup = script:WaitForChild("locationPopup"):Clone();
	locationPopup.Parent = interface.ScreenGui;
	local locationPopupGradient = locationPopup:WaitForChild("UIGradient");

	local mainFrame = mapMenu:WaitForChild("MainFrame");
	local mapImage = mainFrame:WaitForChild("mapImage");

	local locationLabel = mapMenu:WaitForChild("locationLabel");
	local templateObjectFrame = script:WaitForChild("ObjectFrame");
	local templatePlayerPointer = script:WaitForChild("PlayerPointer");

	local templateNpcToolTip = script:WaitForChild("npcToolTip");

	local pageInfo = mapMenu:WaitForChild("pageInfo");
	local centerButton = pageInfo:WaitForChild("centerButton");
	local minimizeButton = pageInfo:WaitForChild("minimizeButton");
	local gpsButton = pageInfo:WaitForChild("gpsButton");

	local helpButton = mapMenu:WaitForChild("HelpButton");
	local hintLabel = mapMenu:WaitForChild("hintLabel");
	
	if modConfigurations.CompactInterface then
		mapMenu.Position = UDim2.new(0.5, 0, 0.5, 0);
		mapMenu.Size = UDim2.new(1, 0, 1, 0);
		
		mapMenu:WaitForChild("HelpButton").Visible = false;
	end

    
	local window: InterfaceWindow = interface:NewWindow("MapMenu", mapMenu);
    interface:BindConfigKey("DisableMapMenu", {window});
	
	modKeyBindsHandler:SetDefaultKey("KeyWindowMapMenu", Enum.KeyCode.M);
	local quickButton = interface:NewQuickButton("MapMenu", "Map", "rbxassetid://4615489625");
	quickButton.LayoutOrder = 4;
	interface:ConnectQuickButton(quickButton, "KeyWindowMapMenu");

	if modConfigurations.CompactInterface then
		window:SetClosePosition(UDim2.new(0.5, 0, -2, 0), UDim2.new(0.5, 0, 0.5, 0));
	else
		window:SetClosePosition(UDim2.new(0.5, 0, -2, 0), UDim2.new(0.5, 0, 0.5, -35));
	end

    local binds = window.Binds;
	binds.Minimized = false;
    binds.MapFrameOffset = Vector2.new();

	mapMenu:WaitForChild("closeButton").MouseButton1Click:Connect(function()
        window:Close();
	end)
	
	local transparencyTag = Instance.new("NumberValue", script);

	local mapOverviewLib = modBranchConfigs.MapOverviews[modBranchConfigs.GetWorld()];
	if mapOverviewLib then
		SHOW_MAP_OBJECTS.Wall = false;
		SHOW_MAP_OBJECTS.RampUp = false;
		SHOW_MAP_OBJECTS.RampDown = false;
	end

	local rats = {};
	local layerFrames = {};
	local dynamicObjects = {};
	local activeLayer = nil;
	local scaleRatio = 3;


	local mapScale = 1024;
	local mapRatio = Vector2.new(1, 1);
	local mapLayerLib;

	local itemToolTip = modItemInterface.newItemTooltip();
	itemToolTip:SetZIndex(6);

	local localPlayerPointer;
	
	--==
	
	local function getCenterVec()
		local centerVec = script:GetAttribute("Center") or mapLayerLib and mapLayerLib.Center;
		return mapLayerLib and centerVec*scaleRatio or Vector2.new();
	end

	local function renderLayer(layerName, layerData)
		layerFrames[layerName] = {
			Alpha = {};
			Update = {};
		};
		local frameData = layerFrames[layerName];
		
		local frame = Instance.new("Frame");
		frame.Name = layerName;
		frame.BackgroundTransparency = 1;
		frame.BorderSizePixel = 0;
		frame.Position = UDim2.new(0.5, 0, 0.5, 0);
		frame.AnchorPoint = Vector2.new(0.5, 0.5);
		frame.Size = UDim2.new(1, 0, 1, 0);
		frame.Parent = mapImage;
		frameData.Frame = frame;
		
		local function frameObject(objInfo)
			local objPart = objInfo.Object;

			local cframe, size, orientation, heightRatio = objInfo.GetSize();
			
			local new = templateObjectFrame:Clone();
			local obj = new:WaitForChild("obj");
			local iconLabel = new:WaitForChild("icon");
			
			new:SetAttribute("ObjectName", objPart and objPart.Name or "nil");
				
			new.Parent = frame;
			obj.Rotation = -(tonumber(orientation) or 0);

			if objInfo.IconInfo then
				iconLabel.Image = objInfo.IconInfo.Icon;
				iconLabel.ImageColor3 = objInfo.IconInfo.Color;
				iconLabel.Size = UDim2.new(0, 25, 0, 25);
				iconLabel.Visible = true;
				
				itemToolTip:BindHoverOver(iconLabel, function()
					itemToolTip.Frame.Parent = mapMenu;
					
					function itemToolTip:CustomUpdate()
						
						local defaultFrame = self.Frame:WaitForChild("default");
						defaultFrame.Visible = false;
						
						local customFrame = self.Frame:WaitForChild("custom");
						customFrame.Visible = true;
						
						local nameTag = self.Frame:WaitForChild("NameTag");
						nameTag.Text = objInfo.Name;
						
						customFrame:ClearAllChildren();
						
                        if objInfo.InteractableConfig == nil then return end;
                        
                        local interactable: InteractableInstance = modInteractables.getOrNew(objInfo.InteractableConfig);

                        if interactable.Type == "GameModeEnter" then
                            self.Frame.Size = UDim2.new(0, 200, 0, 260);
                            
                            local mode = interactable.Values.Mode;
                            local stage = interactable.Values.Stage;

                            nameTag.Text = `{mode}: {stage}`;
                            
                            local levelLabel = nameTag:Clone();
                            levelLabel.Size = UDim2.new(1, 0, 1, 0);
                            levelLabel.Parent = customFrame;
                            levelLabel.TextXAlignment = Enum.TextXAlignment.Left;
                            levelLabel.TextYAlignment = Enum.TextYAlignment.Top;
                            levelLabel.TextSize = 14;
                            
                            local uiPadding = Instance.new("UIPadding");
                            uiPadding.Parent = levelLabel;
                            uiPadding.PaddingLeft = UDim.new(0, 5);
                            uiPadding.PaddingTop = UDim.new(0, 5);
                            uiPadding.PaddingRight = UDim.new(0, 5);
                            uiPadding.PaddingBottom = UDim.new(0, 5);
                            
                            local stageLib = modGameModeLibrary.GameModes[mode].Stages[stage];
                            local rewardsLib = modRewardsLibrary:Find(stageLib.RewardsId);
                            
                            levelLabel.Text = rewardsLib.Level and "Mastery "..rewardsLib.Level.."+\n\n" or "";
                            
                            local rewardsString = "Rewards:\n";
                            
                            for a=1, #rewardsLib.Rewards do
                                local lib = modItem:Find(rewardsLib.Rewards[a].ItemId);
                                rewardsString = rewardsString.."• "..lib.Name..(a ~= #rewardsLib.Rewards and ",\n" or "");
                            end
                            levelLabel.Text = levelLabel.Text..rewardsString;
                            
                        elseif interactable.Type == "Travel" then
                            self.Frame.Size = UDim2.new(0, 360, 0, 200);
                            
                            local worldName = modBranchConfigs.GetWorldDisplayName(interactable.Values.WorldId);
                            nameTag.Text = "Travel: "..worldName
                            
                            local worldLib = modBranchConfigs.WorldLibrary[interactable.Values.WorldId];
                            
                            local newImage = Instance.new("ImageLabel");
                            newImage.Image = worldLib.Icon or "";
                            newImage.Size = UDim2.new(1, 0, 1, 0);
                            newImage.Parent = customFrame;
                            newImage.BorderSizePixel = 0;
                            newImage.BackgroundTransparency = 1;
                            newImage.ZIndex = 6;
                            
                        elseif interactable.Type == "Shop" then
                            nameTag.Text = "Shop";

                        --elseif interactData.Type == "Door" then
                        --	nameTag.Text = "Door";
                            
                        end
                            
					end
					
					itemToolTip:Update();
					itemToolTip:SetPosition(iconLabel);
				end);
			end
			
			local lastSizeUpdate;
			local function updateObjInfo()
				local baseCenterOffset = getCenterVec();
				
				if lastSizeUpdate == nil or tick()-lastSizeUpdate > 1 then
					lastSizeUpdate = tick();
					
					cframe, size, orientation, heightRatio = objInfo.GetSize();
				end
				
				obj.Size = UDim2.new(0, size.X*scaleRatio, 0, size.Z*scaleRatio);

				new.Position = UDim2.new(
					0.5, 
					((cframe.X*scaleRatio) - baseCenterOffset.X)*mapRatio.X, 
					0.5, 
					((cframe.Z*scaleRatio) - baseCenterOffset.Y)*mapRatio.Y
				);

				iconLabel.Size = UDim2.new(0, 25, 0, 25);
			end
			updateObjInfo();
			table.insert(frameData.Update, updateObjInfo);
			
			local layerAlphaPacket = {
				Active = nil;
			};
			local objectType = objInfo.Type;
			
			if objectType == "Wall" then
				local heightColor = 50+(90 * heightRatio);
				obj.BackgroundColor3 = Color3.fromRGB(heightColor + (layerData.HostileZone and 50 or 0), heightColor, heightColor);
				
			elseif objectType == "RampUp" or objectType == "RampDown" then
				obj.BackgroundColor3 = Color3.fromRGB(80, 80, 80);
				obj.Color = obj.BackgroundColor3;
				
			elseif objectType == "Tile" then
				layerAlphaPacket.GetOriginalValue=function()
					return objInfo.Object.Color;
				end

				objInfo.Object:GetPropertyChangedSignal("Color"):Connect(function()
					if layerAlphaPacket.Active then
						obj.BackgroundColor3 = layerAlphaPacket.GetOriginalValue();
					end
				end)

				obj.BackgroundColor3 = layerAlphaPacket.GetOriginalValue();

				
			else
				obj.ZIndex = 5;
				iconLabel.ZIndex = 5;
				
				if objectType == "Door" then
					obj.BackgroundColor3 = Color3.fromRGB(85, 170, 255);
					
				elseif objectType == "Boss" then
					obj.BackgroundColor3 = Color3.fromRGB(85, 0, 255);
					
				elseif objectType == "Travel" then
					obj.BackgroundColor3 = Color3.fromRGB(85, 170, 255);
					
				end
				
			end

			layerAlphaPacket.Active=false;
			layerAlphaPacket.Object=obj;

			layerAlphaPacket.Property="BackgroundColor3";
			layerAlphaPacket.OriginalValue=obj.BackgroundColor3;

			layerAlphaPacket.GhostValue=Color3.fromRGB(45, 45, 45);
			layerAlphaPacket.ZIndex=obj.ZIndex;

			table.insert(frameData.Alpha, layerAlphaPacket);
		end

		for a=1, #layerData.Data do
			local objInfo = layerData.Data[a];
			local objectType = objInfo.Type;
			
			if SHOW_MAP_OBJECTS[objectType] then
				frameObject(objInfo);
				
			end
		end
	end

	function binds.AddDynamic(class, name, basePart)
		local id = class.."_"..name;
		if dynamicObjects[id] then 
			dynamicObjects[id].Object = basePart;
			dynamicObjects[id].Update();
			return
		end;
		
		local new = {};
		new.Class = class;
		new.Name = name;
		new.Object = basePart;
		
		new.Frame = templatePlayerPointer:Clone();
		new.Frame.Name = id;
		new.Frame.Size = UDim2.new(0, 10, 0, 10) -- UDim2.new(0, 2 * scaleRatio, 0, 2 * scaleRatio);
		
		if class == "Player" and name == localPlayer.Name then
			new.Frame.ImageColor3 = Color3.fromRGB(255, 238, 0);
			new.ZIndex = 5;
			
		elseif modNpcProfileLibrary.ClassColors[class] then
			new.Frame.ImageColor3 = modNpcProfileLibrary.ClassColors[class];
			
		end
		
		new.Frame.Parent = mapImage;
		
		new.Update = function(lerp)
			local baseCenterOffset = getCenterVec();
			
			new.Frame.Size = UDim2.new(0, 10, 0, 10) -- UDim2.new(0, 2 * scaleRatio, 0, 2 * scaleRatio);
			
			local newPosition = UDim2.new(
				0.5, 
				((new.Object.Position.X * scaleRatio) - baseCenterOffset.X)*mapRatio.X, 
				0.5, 
				((new.Object.Position.Z * scaleRatio) - baseCenterOffset.Y)*mapRatio.Y
			);
			new.Frame.Position = newPosition;
		end
		
		new.Frame.Size = UDim2.new(0, 10, 0, 10);
		new.Frame.Position = UDim2.new(0.5, new.Object.Position.X * scaleRatio, 0.5, new.Object.Position.Z * scaleRatio);
		
		if modNpcProfileLibrary.ClassColors[class] then
			itemToolTip:BindHoverOver(new.Frame, function()
				itemToolTip.Frame.Parent = mapMenu;
				
				function itemToolTip:CustomUpdate()
					self.Frame.Size = UDim2.new(0, 200, 0, 260);
					
					local defaultFrame = self.Frame:WaitForChild("default");
					defaultFrame.Visible = false;
					
					local customFrame = self.Frame:WaitForChild("custom");
					customFrame.Visible = true;
					
					local nameTag = self.Frame:WaitForChild("NameTag");
					nameTag.Text = name;
					
					customFrame:ClearAllChildren();
					
					local viewportFrame = templateNpcToolTip:Clone();
					viewportFrame.Parent = customFrame;
					
					local prefab = workspace.Entity:FindFirstChild(name);
					if prefab then
						local npcPrefab = prefab:Clone();
						
						local vpCamera = Instance.new("Camera");
						npcPrefab.Parent = viewportFrame;
						vpCamera.Parent = viewportFrame;
						viewportFrame.CurrentCamera = vpCamera;
						
						local rCframe = npcPrefab:GetPrimaryPartCFrame();
						local origin = rCframe.p + Vector3.new(0, 2, 0);
						vpCamera.CFrame = CFrame.lookAt(origin + rCframe.LookVector*4.5 + Vector3.new(0, 1, 0), origin - Vector3.new(0, 0.5, 0));
					end
				end
				
				itemToolTip:Update();
				itemToolTip:SetPosition(new.Frame);
			end);
		end
		
		dynamicObjects[id] = new;
		return new;
	end

	function binds.RemoveDynamic(id)
		if dynamicObjects[id] == nil then return end;
		game.Debris:AddItem(dynamicObjects[id].Frame, 0);
		dynamicObjects[id] = nil;
	end
	
	function binds.PopupLocationText(text)
		locationPopup.Text = text;
		TweenService:Create(
			transparencyTag, 
			TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In),
			{Value=0}
		):Play();
		delay(10, function()
			TweenService:Create(
				transparencyTag, 
				TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In),
				{Value=1}
			):Play();
		end)
	end

    --MARK: OnUpdate
    window.OnUpdate:Connect(function(lerp)
		local rootPart = localPlayer.Character and localPlayer.Character.PrimaryPart;
		if rootPart == nil then Debugger:Warn("Missing RootPart."); return end;
		
		local playerYPos = rootPart.Position.Y;
		if mapOverviewLib then
			mapLayerLib = mapOverviewLib[1];
			
			for a=1, #mapOverviewLib do
				if playerYPos > mapOverviewLib[a].Y then
					mapLayerLib = mapOverviewLib[a];
					break;
				end
			end
			
			mapImage.Image = mapLayerLib.ImageId;
			
			local rescale = mapScale * mapLayerLib.PperStud;
			mapRatio = Vector2.new(rescale/mapLayerLib.Scale.X , rescale/mapLayerLib.Scale.Y);
		else
			mapImage.Image = "";
		end
		
		local layerName, _layerData = modMapLibrary:GetLayer(rootPart.Position);
		binds.LocationName = layerName;
		
		if layerName then
			if layerName ~= activeLayer then
				local frameData = layerFrames[layerName];
				if frameData then
					for lName, lData in pairs(layerFrames) do
						if lName == layerName then
							for a=1, #lData.Alpha do
								local alphaData = lData.Alpha[a];
								
								local propertyValue = alphaData.OriginalValue;
								
								if alphaData.GetOriginalValue then
									propertyValue = alphaData.GetOriginalValue();
								end
								
								alphaData.Active = true;
								alphaData.Object[alphaData.Property] = propertyValue;
								alphaData.Object.ZIndex = alphaData.ZIndex;
							end
							
						else
							for a=1, #lData.Alpha do
								local alphaData = lData.Alpha[a];

								alphaData.Active = false;
								alphaData.Object[alphaData.Property] = alphaData.GhostValue;
								alphaData.Object.ZIndex = alphaData.ZIndex-1;
							end
							
						end
					end
				end
				
				binds.PopupLocationText(layerName);
			end
			locationLabel.Text = "Wrighton Dale, ".. modBranchConfigs.WorldName..", "..layerName;
			activeLayer = layerName;
			
		else
			activeLayer = nil;
			for lName, lData in pairs(layerFrames) do
				for a=1, #lData.Alpha do
					local alphaData = lData.Alpha[a];

					alphaData.Active = false;
					alphaData.Object[alphaData.Property] = alphaData.GhostValue;
					alphaData.Object.ZIndex = alphaData.ZIndex-1;
				end
			end
			locationLabel.Text = "Wrighton Dale, "..(modBranchConfigs.GetWorldDisplayName(modBranchConfigs.WorldName) or "");
			
		end
		
		if not mapMenu.Visible then return end;
		for lN, _ in pairs(layerFrames) do
			for a=1, #layerFrames[lN].Update do
				layerFrames[lN].Update[a]();
			end
		end
		
		for id, _ in pairs(dynamicObjects) do
			local objData = dynamicObjects[id];
			if objData.Object and objData.Object:IsDescendantOf(workspace) then
				if objData.Update then objData.Update(lerp) end;
			else
				binds.RemoveDynamic(id);
			end
		end
		
		if binds.Minimized then
			local frame = localPlayerPointer.Frame;
			mapImage.Position = UDim2.new(0.5, -frame.Position.X.Offset, 0.5, -frame.Position.Y.Offset);
			
		else
			local newPosition = UDim2.new(0.5, 
				0-(rootPart.Position.X * scaleRatio) + binds.MapFrameOffset.X, 
				0.5, 
				0-(rootPart.Position.Z * scaleRatio) + binds.MapFrameOffset.Y);
			
			mapImage.Position = newPosition;
			
		end
		
		mapImage.Size = UDim2.new(0, mapScale*scaleRatio, 0, mapScale*scaleRatio);
		
	end)
	
	
	local mapLoaded = false;
	local function loadMap()
		if mapLoaded then return end
		mapLoaded = true;
		
		local dynamicMapFolder = game.ReplicatedStorage:FindFirstChild("DynamicMap");
		if dynamicMapFolder then
			modMapLibrary:LoadDynamicMap(dynamicMapFolder);
			
		end
		
		for layerName, layerData in pairs(modMapLibrary.ActiveMap.Local) do
			renderLayer(layerName, layerData);
		end
	end
	
    --MARK: OnToggle
	window.OnToggle:Connect(function(visible)
		binds.Minimized = false;
		window.IgnoreHideAll = false;

		if modConfigurations.CompactInterface then
			mapMenu.AnchorPoint = Vector2.new(0.5, 0.5);
			mapMenu.Size = UDim2.new(1, 0, 1, 0);
		else
			mapMenu.AnchorPoint = Vector2.new(0.5, 0.5);
			mapMenu.Size = UDim2.new(0.8, 0, 1, -220);
		end

		pageInfo.Visible = true;
		locationLabel.Visible = true;
		helpButton.Visible = true;
		hintLabel.Visible = true;
		
		if visible then
			loadMap();
			
			scaleRatio = 3;
			
			interface:HideAll{[window.Name]=true;};
			
			binds.MapFrameOffset = getCenterVec();
            window:Update();
		else
			window.ReleaseMouse = true;
			window.UseTween = true;
			
		end
	end)
	
	modMapLibrary:Initialize();
	loadMap()
	
	task.defer(function()
		local rootPart = localPlayer.Character and localPlayer.Character.PrimaryPart;
		for a=1, 10 do
			wait(1);
			if rootPart then break; end;
		end
		pcall(function()
			localPlayerPointer = binds.AddDynamic("Player", localPlayer.Name, rootPart);
		end)
		
		local namesList = modNpcProfileLibrary:GetKeys();
		for a=1, #namesList do
			local npcName = namesList[a];
			local npcRootPart = workspace.Entity:FindFirstChild(npcName) and workspace.Entity[npcName].PrimaryPart;

			local npcLib = modNpcProfileLibrary:Find(npcName);
			if npcLib.Class ~= "Hidden" then
				if npcLib.Class == "RAT" then
					table.insert(rats, npcName);
				end
				if npcLib and npcRootPart then
					binds.AddDynamic(npcLib.Class, npcName, npcRootPart)
				end;
			end
		end
		
        window:Update();
		
		while true do
			if not mapMenu.Visible then
				task.wait(3);
			end
            window:Update();
			task.wait();
		end
	end)
	
	interface.Garbage:Tag(mainFrame.InputChanged:Connect(function(inputObject, gameProcessed)
		if not gameProcessed then
			if inputObject.UserInputType == Enum.UserInputType.MouseWheel then
				local preScale = scaleRatio;
				
				scaleRatio = math.clamp(scaleRatio + inputObject.Position.Z*0.5, 0.5, 8);
				
				if scaleRatio ~= preScale then
					
					--local mousePosition = UserInputService:GetMouseLocation();
					
					--local localMousePos = mousePosition - (mapImage.AbsolutePosition + mapImage.AbsoluteSize/2);
					--local rawMousePos = localMousePos/mapImage.AbsoluteSize;
					
					--mapImage.Size = UDim2.new(0, mapScale*scaleRatio, 0, mapScale*scaleRatio);
					
					--local new = rawMousePos*mapImage.AbsoluteSize;
					--local offset = localMousePos-new;
					
					--Interface.MapFrameOffset = newOffsetVec + offset;
					
					binds.MapFrameOffset = getCenterVec();
                    window:Update();
				end
			end
		end
	end));

	transparencyTag:GetPropertyChangedSignal("Value"):Connect(function()
		locationPopupGradient.Transparency = NumberSequence.new(transparencyTag.Value);
	end)

	local modUsableItems = shared.require(game.ReplicatedStorage.Library.UsableItems);
	gpsButton.MouseButton1Click:Connect(function()
		local listOfGps = modData.ListItemIdFromCharacter("gps");
		if #listOfGps > 0 then
			local storageItem;
			for a=1, #listOfGps do
				local item = listOfGps[a];
				if item.Fav then
					storageItem = item;
					break;
				end
				storageItem = item;
			end
			
			if storageItem then
				local usableItemLib = modUsableItems:Find("gps");
				usableItemLib:ClientUse(storageItem);
                
                window:Close();
			else
				modClientGuis.promptWarning("You do not have a GPS to fast travel.");
			end
		else
			modClientGuis.promptWarning("You do not have a GPS to fast travel.");
		end
	end)


	minimizeButton.MouseButton1Click:Connect(function()
		scaleRatio = 0.5;
		binds.Minimized = true;
		binds.MapFrameOffset = getCenterVec();
		window.IgnoreHideAll = true;
		window.ReleaseMouse = false;
		window.UseTween = false;
        interface:RefreshInterfaces();

		if modConfigurations.CompactInterface then
			mapMenu.AnchorPoint = Vector2.new(0, 0);
			mapMenu.Position = UDim2.new(0, 10, 0, 70);
			mapMenu.Size = UDim2.new(0.2, 0, 0.2, 0);
			
		else
			mapMenu.AnchorPoint = Vector2.new(1, 1);
			mapMenu.Position = UDim2.new(1, -5, 1, -65);
			mapMenu.Size = UDim2.new(0.2, 0, 0.2, 0);
			
		end
		
		pageInfo.Visible = false;
		locationLabel.Visible = false;
		helpButton.Visible = false;
		hintLabel.Visible = false;
	end)

	centerButton.MouseButton1Click:Connect(function()
		scaleRatio = 3;
		binds.MapFrameOffset = getCenterVec();
        
        window:Update();
	end)


	local enemyCounter = 0;
	interface.Garbage:Tag(workspace.Entity.ChildAdded:Connect(function(child)
		if not child:IsA("Model") then return end;
		wait(0.5);
		
		local npcLib = modNpcProfileLibrary:Find(child.Name);
		local npcHumanoid = child:FindFirstChildWhichIsA("Humanoid");
		
		if child.PrimaryPart then
			if npcLib and npcLib.Class ~= "Hidden" then
				binds.AddDynamic(npcLib.Class, child.Name, child.PrimaryPart);
				
			elseif modConfigurations.AutoMarkEnemies == true and npcHumanoid and (npcHumanoid.Name == "Zombie" or npcHumanoid.Name == "Bandit") then
				enemyCounter = enemyCounter +1;
				binds.AddDynamic("Enemy", child.Name..enemyCounter, child.PrimaryPart);
				
			end
		end;
	end))
	interface.Garbage:Tag(workspace.Entity.ChildRemoved:Connect(function(child)
		for id, _ in pairs(dynamicObjects) do
			if child:IsA("Model") and dynamicObjects[id].Object == child.PrimaryPart then
				binds.RemoveDynamic(id);
			end
		end
	end))

end

return interfacePackage;

