local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TextService = game:GetService("TextService");

local localplayer = game.Players.LocalPlayer;

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modSyncTime = shared.require(game.ReplicatedStorage.Library.SyncTime);
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modWorkbenchLibrary = shared.require(game.ReplicatedStorage.Library.WorkbenchLibrary);
local modItemLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modBlueprintLibrary = shared.require(game.ReplicatedStorage.Library.BlueprintLibraryRotd);
local modItemModsLibrary = shared.require(game.ReplicatedStorage.Library.ItemModsLibrary);
local modWeaponsLibrary = shared.require(game.ReplicatedStorage.Library.WeaponsLibrary);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modKeyBindsHandler = shared.require(game.ReplicatedStorage.Library.KeyBindsHandler);
local modItemUnlockablesLibrary = shared.require(game.ReplicatedStorage.Library.ItemUnlockablesLibrary);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modTableManager = shared.require(game.ReplicatedStorage.Library.TableManager);

local modItemInterface = shared.require(game.ReplicatedStorage.Library.UI.ItemInterface);
local modStorageInterface = shared.require(game.ReplicatedStorage.Library.UI.StorageInterface);

local interfacePackage = {
    Type = "Character";
};
--==

function interfacePackage.onRequire()
	modKeyBindsHandler:SetDefaultKey("KeyWindowWorkbench", Enum.KeyCode.N);
end

function interfacePackage.newInstance(interface: InterfaceInstance)
    local remoteStorageItemSync = modRemotesManager:Get("StorageItemSync");
	local remoteWorkbenchService = modRemotesManager:Get("WorkbenchService");

    local modData = shared.require(localplayer:WaitForChild("DataModule"));
	local branchColor = modBranchConfigurations.BranchColor;
	
	local workbenchFrame;
	if modConfigurations.CompactInterface then
		workbenchFrame = script:WaitForChild("MobileWorkbench"):Clone();
	else
		workbenchFrame = script:WaitForChild("WorkbenchFrame"):Clone();
	end
	workbenchFrame.Parent = interface.ScreenGui;

	local workbenchTitleLabel = workbenchFrame.Title;
	local pageFrame = workbenchFrame.pageFrame;
	local navBar = workbenchFrame.navBar;
	local navButtons = navBar:GetChildren();
	local listFrameTemplate = script:WaitForChild("listFrame");
	local cateTabTemplate = script:WaitForChild("categoryTab");
	local gridListTemplate = script:WaitForChild("gridList");
	local basicListTemplate = script:WaitForChild("basicList");
	local labelTemplate = script:WaitForChild("label");
	local itemButtonTemplate = script:WaitForChild("itemButton");

	local clearSelectionButton;

	local workbenchWindow: InterfaceWindow = interface:NewWindow("Workbench", workbenchFrame);
	workbenchWindow.CompactFullscreen = true;
	workbenchWindow.DisableInteractables = true;
	workbenchWindow.CloseWithInteract = true;

    local binds = workbenchWindow.Binds;
	binds.IsPremium = false;
	binds.Workbenches = {};
	binds.ActiveWorkbenches = {};

	if modConfigurations.CompactInterface then
		clearSelectionButton = workbenchFrame.TitleFrame:WaitForChild("clearSelectionButton");
		workbenchWindow:SetClosePosition(UDim2.new(1, 0, 1, 0), UDim2.new(1, 0, 0, 0));
		
		workbenchFrame.TitleFrame:WaitForChild("closeButton").MouseButton1Click:Connect(function()
			workbenchWindow:Close();
		end)
		workbenchFrame.TitleFrame:WaitForChild("clearSelectionButton").MouseButton1Click:Connect(function()
			binds.SelectedSlot = nil;
			binds.ClearSelection();
			interface:ToggleWindow("Inventory", true);
		end)
	else
		workbenchWindow:SetClosePosition(UDim2.new(2, 0, 0.5, 0), UDim2.new(1, -10, 0.5, 0));
	end

	local quickButton = interface:NewQuickButton("Workbench", "Workbench", "rbxassetid://2273400846");
	quickButton.LayoutOrder = 15;
	interface:ConnectQuickButton(quickButton, "KeyWindowWorkbench");

	task.spawn(function()
		while modData.Profile == nil do task.wait() end;
		interface:BindConfigKey("DisableWorkbench", {workbenchWindow}, nil, function()
			return modData.Profile == nil 
				or modData.Profile.GamePass == nil 
				or modData.Profile.GamePass.PortableWorkbench == nil;
		end)
	end)
	interface:BindConfigKey("DisableWorkbench", {workbenchWindow});
	workbenchWindow:AddCloseButton(workbenchFrame);
	
    
	workbenchWindow.OnToggle:Connect(function(visible, packet)
		packet = packet or {};

		packet.DontCloseInventory = packet.DontCloseInventory == true;
		
        if visible then
			binds.Interactable = packet.Interactable;
			binds.InteractPart = binds.Interactable and binds.Interactable.Part or nil;

			binds.IsPremium = modData.Profile ~= nil and modData.Profile.Premium or false;
			workbenchTitleLabel.Text = "Workbench";
			
            task.spawn(function() remoteWorkbenchService:InvokeServer("interfacetoggle", visible); end);
            
            modData:RequestData("GameSave/Workbench");
            modData:RequestData("GameSave/Blueprints");
            
            binds.ClearSelection();
            binds.RefreshNavigations();

			for a=#interface.StorageInterfaces, 1, -1 do
				local storageInterface: StorageInterface = interface.StorageInterfaces[a];
				if storageInterface == nil then continue end;
				if storageInterface.StorageId ~= "Inventory" and storageInterface.StorageId ~= "Clothing" then
					continue;
				end
				storageInterface.OnItemButton1Click = binds.onItemSelect;
			end

			interface:HideAll{[workbenchWindow.Name]=true; ["Inventory"]=true; ["WeaponStats"]=true};
            interface:ToggleWindow("Inventory", true);

            if not (modData.Profile ~= nil and modData.Profile.GamePass and modData.Profile.GamePass.PortableWorkbench) then
                spawn(function()
                    repeat until 
                        not workbenchWindow.Visible 
                        or binds.InteractPart == nil 
                        or not binds.InteractPart:IsDescendantOf(workspace) 
                        or localplayer:DistanceFromCharacter(binds.InteractPart.Position) >= 16 
                        or not wait(0.5);
                    interface:ToggleWindow("Inventory", false);
                end)
            end

			modData:RequestData("ItemUnlockables");
			interface:ToggleWindow("WeaponStats", true);

        else
            for k, listMenu in pairs(binds.ActiveWorkbenches) do
                listMenu.Menu.Visible = false;
            end

			binds.ClearSelection();
            binds.clearSlotHighlight();
            binds.SelectedSlot = nil;
			
			for a=#interface.StorageInterfaces, 1, -1 do
				local storageInterface: StorageInterface = interface.StorageInterfaces[a];
				if storageInterface == nil then continue end;
				if storageInterface.StorageId ~= "Inventory" and storageInterface.StorageId ~= "Clothing" then
					continue;
				end
				storageInterface.OnItemButton1Click = storageInterface.BeginDragItem;
			end
            
            if packet.DontCloseInventory ~= true then
                interface:ToggleWindow("Inventory", false)
            end
            interface:ToggleWindow("WeaponStats", false);
			interface:ToggleWindow("ItemInspect", false);
        end
	end)
	

    interface.Garbage:Tag(modData.OnDataEvent:Connect(function(action, hierarchyKey, data)
        if action ~= "sync" then return end;
        
        if hierarchyKey == "GameSave/Blueprints" and binds.ActivePage == "Blueprints" then
            binds.GetProcesses();
            
            binds.ClearPages("blueprints");
            binds.ActiveWorkbenches.Blueprints = binds.Workbenches.Blueprints.Workbench.new();
            binds.RefreshNavigations();
            
            binds.SetPage(binds.ActiveWorkbenches.Blueprints.Menu);
        end
        
    end))

    interface.Garbage:Tag(modData.OnDataEvent:Connect(function(action, hierarchyKey, data)
        if action ~= "sync" or hierarchyKey ~= "GameSave/Workbench" then return end;
        
        if binds.GetProcesses then
            local processes = binds.GetProcesses();
            
            if #processes > 0 then
                binds.LoadProcesses();
            end
			
			workbenchTitleLabel.Text = "Workbench ";
            binds.RefreshNavigations();
            
        end
    end))


	function workbenchWindow:Init()

		binds.Workbenches["Processes"]={
			Workbench=shared.require(script.Processes).init(interface, workbenchWindow)
		}; -- List of processes
		binds.Workbenches["Blueprints"]={
			Workbench=shared.require(script.Blueprints).init(interface, workbenchWindow)
		}; -- List of play unlocked blueprints.

		binds.Workbenches["Build"]={
			Library=modBlueprintLibrary.Library; Workbench=shared.require(script.Build).init(interface, workbenchWindow)
		};
		binds.Workbenches["Upgrades"]={
			Library=modWorkbenchLibrary.ItemUpgrades; Workbench=shared.require(script.Upgrades).init(interface, workbenchWindow)
		};
		binds.Workbenches["Appearance"]={
			Library=modWorkbenchLibrary.ItemAppearance; Workbench=shared.require(script.Appearance).init(interface, workbenchWindow)
		};
		binds.Workbenches["Customization"]={
			Library=modWorkbenchLibrary.ItemAppearance; Workbench=shared.require(script.Customization).init(interface, workbenchWindow)
		};
		binds.Workbenches["DeconstructMod"]={
			Library=modItemModsLibrary.Library; Workbench=shared.require(script.DeconstructMod).init(interface, workbenchWindow)
		};
		binds.Workbenches["DeconstructWeapon"]={
			Library=modWeaponsLibrary; Workbench=shared.require(script.DeconstructWeapon).init(interface, workbenchWindow)
		};
		binds.Workbenches["PolishTool"]={
			Library=modWorkbenchLibrary.ItemAppearance; Workbench=shared.require(script.PolishTool).init(interface, workbenchWindow)
		};
		binds.Workbenches["Tweak"]={
			Library=modWorkbenchLibrary.ItemAppearance; Workbench=shared.require(script.Tweak).init(interface, workbenchWindow)
		};

		for _, obj in pairs(navButtons) do
			if obj:IsA("ImageButton") then
				local function updateButtonColors()
					for _, button in pairs(navButtons) do
						if button:IsA("ImageButton") then
							button.ImageColor3 = (button == obj or binds.ActivePage == button.Name) and branchColor or Color3.fromRGB(255, 255, 255);
							button.label.Visible = button == obj;
						end
					end
				end

				obj.MouseButton1Click:Connect(function()
					if binds.ActiveWorkbenches[obj.Name] then
						interface:PlayButtonClick();
						binds.SetPage(binds.ActiveWorkbenches[obj.Name].Menu);
					end
					updateButtonColors();
				end)
				obj.MouseEnter:Connect(updateButtonColors)
				obj.MouseLeave:Connect(function()
					obj.ImageColor3 = binds.ActivePage == obj.Name and branchColor or Color3.fromRGB(255, 255, 255);
					obj.label.Visible = false;
				end)
			end
		end
	end

	local function onSelectionChange()
		binds.ClearSelection();
	
		local inspectWindow: InterfaceWindow = interface:GetWindow("ItemInspect");
		if inspectWindow then
			if modConfigurations.CompactInterface then
				inspectWindow.Binds.SetStyle("QuadTopLeft");
			else
				inspectWindow.Binds.SetStyle("Workbench");
			end
		end

		if binds.SelectedSlot then
			if clearSelectionButton then
				clearSelectionButton.Visible = true;
			end
			local itemId = binds.SelectedSlot.Item.ItemId;
			local itemLib = modItemLibrary:Find(itemId);

			if inspectWindow then
				local itemViewport = inspectWindow.Binds.ItemViewport;
				if itemViewport.OnDisplayID ~= binds.SelectedSlot.Item.ID then
					remoteStorageItemSync:FireServer("update", binds.SelectedSlot.Item.ID);
					inspectWindow:Open(binds.SelectedSlot.Item);
				end
			end

			for key, wb in pairs(binds.Workbenches) do
				if key == "Appearance" and itemLib.Type ~= modItemLibrary.Types.Clothing then
					continue;
				end

				if wb.Library and wb.Workbench then
					if wb.Library[itemId] or (modItemUnlockablesLibrary:Find(itemId) and key == "Appearance") then

						binds.ActiveWorkbenches[key] = wb.Workbench.new(itemId, binds.Workbenches[key].Library[itemId], binds.SelectedSlot.Item);
						if binds.ActiveWorkbenches[key] then
							binds.ActiveWorkbenches[key].Menu.Parent = pageFrame;
						end
					end
				end
			end
			if binds.ActiveWorkbenches.Build then
				if binds.ActiveWorkbenches.Blueprints then
					binds.ActiveWorkbenches.Blueprints.Menu:Destroy();
					binds.ActiveWorkbenches.Blueprints = nil;
				end
			end
			if (itemLib.Type == modItemLibrary.Types.Tool or itemLib.Type == modItemLibrary.Types.Clothing) and binds.ActiveWorkbenches.Upgrades then
				binds.SetPage(binds.ActiveWorkbenches.Upgrades.Menu);

			elseif itemLib.Type == modItemLibrary.Types.Mod then
				if binds.ActiveWorkbenches.Upgrades == nil then
					binds.ActiveWorkbenches.Upgrades = binds.Workbenches.Upgrades.Workbench.new(itemId, itemLib, binds.SelectedSlot.Item);
				end
				binds.SetPage(binds.ActiveWorkbenches.Upgrades.Menu);

			elseif itemLib.Type == modItemLibrary.Types.Blueprint and binds.ActiveWorkbenches.Build then
				binds.SetPage(binds.ActiveWorkbenches.Build.Menu);
			end

		else
			if clearSelectionButton then
				clearSelectionButton.Visible = false;
			end
			if inspectWindow then
				inspectWindow:Close();
			end
			
		end
		binds.RefreshNavigations();
	end

	function binds.clearSlotHighlight(slot)
		for a=#interface.StorageInterfaces, 1, -1 do
			local storageInterface: StorageInterface = interface.StorageInterfaces[a];
			if storageInterface == nil then continue end;
			if storageInterface.StorageId ~= "Inventory" and storageInterface.StorageId ~= "Clothing" then
				continue;
			end

			for id, button in pairs(storageInterface.Buttons) do
				if (slot == nil or id ~= slot.ID) and button.Button then
					button.Button.BackgroundTransparency = 1;
				end
			end
		end
	end
	

	--== List Frame Options;
	local ListMenu = {};
	ListMenu.__index = ListMenu;

	function ListMenu:ClearSearches()
		self.SearchBox.Text = "";
	end

	function ListMenu:SetEnableSearchBar(value)
		self.SearchBar.Visible = value;
		self.ContentList.Size = UDim2.new(1, self.ContentList.Size.X.Offset, 1, value and -20 or 0);
	end

	function ListMenu:SetEnableScrollBar(value)
		local showScrollBars = modData.Settings and modData.Settings.ShowScrollbars == 1 or false;
		self.ContentList.ScrollBarThickness = value and 5 or 0;
		if showScrollBars then
			self.ContentList.ScrollBarThickness = 5;
		end
	end

	function ListMenu:SetListPadding(size, padding)
		self.ContentList.Size = size or self.ContentList.Size;
		if padding then
			if padding.Bottom then
				self.ContentList.UIPadding.PaddingBottom = padding.Bottom;
			end
			if padding.Left then
				self.ContentList.UIPadding.PaddingLeft = padding.Left;
			end
			if padding.Right then
				self.ContentList.UIPadding.PaddingRight = padding.Right;
			end
			if padding.Top then
				self.ContentList.UIPadding.PaddingTop = padding.Top;
			end
		end
	end

	function ListMenu:NewBasicList()
		local list = basicListTemplate:Clone();
		local contentlist = list:WaitForChild("list");
		local _layout = contentlist:WaitForChild("UIListLayout");

		return list;
	end

	function ListMenu:NewGridList()
		local list = gridListTemplate:Clone();
		local contentlist = list:WaitForChild("list");
		local _gridLayout = contentlist:WaitForChild("UIGridLayout");

		return list;
	end

	function ListMenu:NewTab(subject)
		local tab = cateTabTemplate:Clone();
		local _titleLabel = tab:WaitForChild("titleLabel");
		local collapseSign = tab:WaitForChild("collapseSign");

		local active = true;
		tab.MouseButton1Click:Connect(function()
			interface:PlayButtonClick();
			active = not active;
			subject.Visible = active;
			collapseSign.Visible = not active;
		end)

		return tab;
	end

	function ListMenu:NewLabel(text)
		local label = labelTemplate:Clone();
		label.Text = text;
		self:Add(label);

		local textBounds = TextService:GetTextSize(text, label.TextSize, label.Font, Vector2.new(label.AbsoluteSize.X, 1000));
		label.Size = UDim2.new(1, 0, 0, textBounds.Y+10);
		return label;
	end

	function ListMenu:NewItemButton(itemId, storageItem)
		local button = itemButtonTemplate:Clone();
		button.Name = "";

		button.MouseButton1Click:Connect(function()
			modStorageInterface.ToggleDesc(false);
		end)

		button.MouseMoved:Connect(function()
			modStorageInterface.SetDescription(itemId, storageItem);

			local itemToolTipElement: InterfaceElement = interface:GetOrDefaultElement("ItemToolTip");
			if itemToolTipElement then
				itemToolTipElement.SetPosition(button);
			end
			modStorageInterface.ToggleDesc(true);
		end)

		button.MouseLeave:Connect(function()
			modStorageInterface.ToggleDesc(false);
		end)

		return button;
	end

	function ListMenu:Destroy()
		if self.Menu then
			self.Menu:Destroy();
		end
		self = nil;
	end

	function ListMenu.create()
		local self = {};
		self.Refresh=nil;
		self.ClearSearches=nil;
		self.OnVisiblityChanged=nil;

		self.Menu = listFrameTemplate:Clone();
		self.Menu.Parent = pageFrame;
		self.SearchBar = self.Menu:WaitForChild("searchBar");
		self.ContentList = self.Menu:WaitForChild("scrollList");
		self.SearchBox = self.SearchBar:WaitForChild("searchBox");
		self.SearchIndexes = {};

		self.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
			for a=1, #self.SearchIndexes do
				local visible = false;
				if #self.SearchBox.Text > 0 then
					local tags = self.SearchIndexes[a].Tags;
					for b=1, #tags do
						if tags[b]:lower():match(self.SearchBox.Text:lower()) then
							visible = true;
							break;
						end
					end
				else
					visible = true;
				end
				if self.SearchIndexes[a].Gui then
					self.SearchIndexes[a].Gui.Visible = visible;
				end
			end
		end)

		self.Menu.Destroying:Connect(function()
			self.Menu.Visible = false;
			if self.OnVisiblityChanged then
				task.spawn(function()
					self:OnVisiblityChanged();
				end)
			end
		end)

		self.Menu:GetPropertyChangedSignal("Visible"):Connect(function()
			if self.OnVisiblityChanged then
				task.spawn(function()
					self:OnVisiblityChanged();
				end)
			end
			if self.Menu.Visible then
				if self.Refresh then
					self:Refresh();
				end
				self:ClearSearches();
			end
		end)

		setmetatable(self, ListMenu);
		return self;
	end

	function ListMenu:AddSearchIndex(guiObject, tags)
		table.insert(self.SearchIndexes, {Gui=guiObject; Tags=tags});
	end

	function ListMenu:Add(guiObject, order)
		guiObject.Parent = self.ContentList;
		guiObject.LayoutOrder = order or guiObject.LayoutOrder;
	end

	binds.List = ListMenu;

	--== List Mods;
	binds.ListMods = shared.require(script.ListMods).init(interface, workbenchWindow);

	--== General functions;
	function binds.SetPage(pageObject)
		for _, frame in pairs(pageFrame:GetChildren()) do
			if frame:IsA("GuiObject") then
				frame.Visible = frame == pageObject;
			end
		end
		for navName, listMenu in pairs(binds.ActiveWorkbenches) do
			if listMenu.Menu == pageObject then
				binds.ActivePage = navName;
				
				if listMenu.OnMenuToggle then
					listMenu:OnMenuToggle();
				end
				
				for _, obj in pairs(navButtons) do
					if obj:IsA("ImageButton") then
						obj.ImageColor3 = binds.ActivePage == obj.Name and branchColor or Color3.fromRGB(255, 255, 255);
					end
				end
			end
		end
		binds.RefreshNavigations();
		modStorageInterface.ToggleDesc(false);
	end

	function binds.ClearPages(name)
		for _, frame in pairs(pageFrame:GetChildren()) do
			if frame.Name == name then
				frame:Destroy();
			end
		end
	end

	function binds.RefreshNavigations()
		for _, obj in pairs(navButtons) do
			if obj:IsA("ImageButton") then
				obj.Visible = binds.ActiveWorkbenches[obj.Name] ~= nil;
			end
		end
	end

	function binds.ForceClear()
        local inventoryWindow: InterfaceWindow = interface:GetWindow("Inventory");
        if inventoryWindow then
            inventoryWindow:Open();
        end
		binds.clearSlotHighlight();
		binds.SelectedSlot = nil;
		onSelectionChange();
	end

	function binds.onItemSelect(storageInterface, slot)
		if binds.SelectedSlot == nil or binds.SelectedSlot.ID ~= (slot and slot.ID or 0) then
			binds.clearSlotHighlight(slot);
			interface:PlayButtonClick();

			slot.Button.BackgroundTransparency = 0.3;
			slot.Button.BackgroundColor3 = branchColor;

			binds.SelectedSlot = slot;
            task.spawn(function() remoteWorkbenchService:InvokeServer("itemselect", binds.SelectedSlot.ID); end);
			onSelectionChange();
			if modConfigurations.CompactInterface then
                interface:ToggleWindow("Inventory", false);
			end
		else
			binds.ForceClear();
		end
	end

	local processTypeSorting = {BuildComplete=1; Deconstruction=2; PolishTool=3; Building=10;};
	function binds.GetProcesses()
		local processes= {};
		local processesData = modTableManager.GetDataHierarchy(modData.Profile, "GameSave/Workbench/Processes") or {};
		
		for a=1, #processesData do
			local process = processesData[a];
			if process.Type == 1 then -- Building;
				if modSyncTime.GetTime() >= process.BT then
					table.insert(processes, {Type="BuildComplete"; Index=a; Data=process;});
				else
					table.insert(processes, {Type="Building"; Index=a; Data=process;});
				end
			elseif process.Type == 2 then
				table.insert(processes, {Type="Deconstruction"; Index=a; Data=process;});

			elseif process.Type == 3 then
				table.insert(processes, {Type="Deconstruction"; Index=a; Data=process;});
				
			elseif process.Type == 4 then
				table.insert(processes, {Type="PolishTool"; Index=a; Data=process;});

			end
		end

		table.sort(processes, function(A, B)
			return (processTypeSorting[A.Type] or 999) < (processTypeSorting[B.Type] or 999);
		end)

		local processCountStr = `({tostring(#processes)}/{binds.IsPremium and "10" or "5"})`;
		workbenchTitleLabel.Text = `Workbench {processCountStr}`;

		return processes;
	end
	
	function binds.LoadProcesses()
		if binds.ActiveWorkbenches.Processes then return end;
		binds.ActiveWorkbenches.Processes = binds.Workbenches.Processes.Workbench.new();
		binds.ActiveWorkbenches.Processes.Menu.Parent = pageFrame;
	end
	
	function binds.ClearSelection()
		if clearSelectionButton then
			clearSelectionButton.Visible = false;
		end

		for k, listMenu in pairs(binds.ActiveWorkbenches) do
			listMenu:Destroy();
			binds.ActiveWorkbenches[k] = nil;
		end
		
		binds.ActiveWorkbenches.Blueprints = binds.Workbenches.Blueprints.Workbench.new();
		binds.ActiveWorkbenches.Blueprints.Menu.Parent = pageFrame;
		binds.ActiveWorkbenches.Blueprints.Menu.Name = "bpListFrame";
		
        local weaponStats: InterfaceWindow = interface:GetWindow("WeaponStats");
        if weaponStats then
            weaponStats:Close();
        end
		local inspectWindow: InterfaceWindow = interface:GetWindow("ItemInspect");
		if inspectWindow then
			inspectWindow:Close();
		end

		local processes = binds.GetProcesses();
		if #processes > 0 then
			binds.LoadProcesses();
			binds.SetPage(binds.ActiveWorkbenches.Processes.Menu);
		else
			binds.SetPage(binds.ActiveWorkbenches.Blueprints.Menu);
		end
	end



    function binds.PlayUpgradeSound()
        modAudio.Preload("StorageWeaponPickup", 5);
        modAudio.Play("StorageWeaponPickup", nil, nil, false);
    end

    function binds.PlayCollectSound()
        modAudio.Preload("StorageItemPickup", 5);
        modAudio.Play("StorageItemPickup", nil, nil, false);
    end



end

return interfacePackage;

