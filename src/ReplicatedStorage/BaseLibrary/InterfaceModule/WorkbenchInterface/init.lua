local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local Interface : any = {};

local TextService = game:GetService("TextService");

local localplayer = game.Players.LocalPlayer;

local modData = require(localplayer:WaitForChild("DataModule") :: ModuleScript);
local modAudio = require(game.ReplicatedStorage.Library:WaitForChild("Audio"));
local modSyncTime = require(game.ReplicatedStorage.Library:WaitForChild("SyncTime"));
local modBranchConfigs = require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("BranchConfigurations"));
local modWorkbenchLibrary = require(game.ReplicatedStorage.Library:WaitForChild("WorkbenchLibrary"));
local modItemLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modBlueprintLibrary = require(game.ReplicatedStorage.Library.BlueprintLibrary);
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);
local modWeaponsLibrary = require(game.ReplicatedStorage.Library.Weapons);
local modConfigurations = require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));
local modKeyBindsHandler = require(game.ReplicatedStorage.Library.KeyBindsHandler);
local modItemUnlockablesLibrary = require(game.ReplicatedStorage.Library.ItemUnlockablesLibrary);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modTableManager = require(game.ReplicatedStorage.Library.TableManager);

local modItemInterface = require(game.ReplicatedStorage.Library.UI.ItemInterface);
local modStorageInterface = require(game.ReplicatedStorage.Library.UI.StorageInterface);

local remoteStorageItemSync = modRemotesManager:Get("StorageItemSync");

modData.OnDataEvent:Connect(function(action, hierarchyKey, data)
	if action ~= "sync" then return end;
	
	if hierarchyKey == "GameSave/Blueprints" and Interface.ActivePage == "Blueprints" then
		Interface.GetProcesses();
		
		Interface.ClearPages("blueprints");
		Interface.ActiveWorkbenches.Blueprints = Interface.Workbenches.Blueprints.Workbench.new();
		Interface.RefreshNavigations();
		
		Interface.SetPage(Interface.ActiveWorkbenches.Blueprints.Menu);
	end
	
end)

modData.OnDataEvent:Connect(function(action, hierarchyKey, data)
	if action ~= "sync" or hierarchyKey ~= "GameSave/Workbench" then return end;
	
	if Interface.GetProcesses then
		local processes = Interface.GetProcesses();
		
		if #processes > 0 then
			Interface.LoadProcesses();
		end
		Interface.RefreshNavigations();
		
	end
end)

--== Script;
function Interface.init(modInterface)
	setmetatable(Interface, modInterface);

	local interfaceScreenGui = localplayer.PlayerGui:WaitForChild("MainInterface"); -- script.Parent.Parent 
	
	local workbenchFrame;
	if modConfigurations.CompactInterface then
		workbenchFrame = script:WaitForChild("MobileWorkbench"):Clone();
	else
		workbenchFrame = script:WaitForChild("WorkbenchFrame"):Clone();
	end

	local workbenchTitleLabel = workbenchFrame.Title;
	local pageFrame = workbenchFrame.pageFrame;
	local navBar = workbenchFrame.navBar;
	local navButtons = navBar:GetChildren();
	local processesTag = workbenchFrame.processTag;
	local listFrameTemplate = script:WaitForChild("listFrame");
	local cateTabTemplate = script:WaitForChild("categoryTab");
	local gridListTemplate = script:WaitForChild("gridList");
	local basicListTemplate = script:WaitForChild("basicList");
	local labelTemplate = script:WaitForChild("label");
	local itemButtonTemplate = script:WaitForChild("itemButton");

	Interface.Workbenches = {
		Processes={Workbench=require(script.Processes).init(Interface)}; -- List of processes
		Blueprints={Workbench=require(script.Blueprints).init(Interface)}; -- List of play unlocked blueprints.

		Build={Library=modBlueprintLibrary.Library; Workbench=require(script.Build).init(Interface)};
		Upgrades={Library=modWorkbenchLibrary.ItemUpgrades; Workbench=require(script.Upgrades).init(Interface)};
		
		Appearance={Library=modWorkbenchLibrary.ItemAppearance; Workbench=require(script.Appearance).init(Interface)};
		Customization={Library=modWorkbenchLibrary.ItemAppearance; Workbench=require(script.Customization).init(Interface)};

		DeconstructMod={Library=modModsLibrary.Library; Workbench=require(script.DeconstructMod).init(Interface)};
		DeconstructWeapon={Library=modWeaponsLibrary; Workbench=require(script.DeconstructWeapon).init(Interface)};
		
		PolishTool={Library=modWorkbenchLibrary.ItemAppearance; Workbench=require(script.PolishTool).init(Interface)};

		Tweak={Library=modWorkbenchLibrary.ItemAppearance; Workbench=require(script.Tweak).init(Interface)};
	};
	Interface.ActiveWorkbenches = {};

	local remotes = game.ReplicatedStorage.Remotes;
	local remoteWorkbenchInteract = remotes.Workbench:WaitForChild("WorkbenchInteract");
	local defaultInterface, premiumInterface, clothingInterface;
	local selectedSlot; -- StorageSlot;

	local branchColor = modBranchConfigs.BranchColor;
	Interface.IsPremium = false;
	workbenchFrame.Parent = interfaceScreenGui;
	
	defaultInterface, premiumInterface = Interface.modInventoryInterface.DefaultInterface, Interface.modInventoryInterface.PremiumInterface;
	clothingInterface = Interface.modInventoryInterface.ClothingInterface;
	
	local newItemDisplay = modInterface.ItemViewport.new();
	newItemDisplay.Frame.Parent = interfaceScreenGui;
	newItemDisplay.CloseVisible = false;
	modInterface.WorkbenchItemDisplay = newItemDisplay;
	
	if modConfigurations.CompactInterface then
		newItemDisplay.Frame.AnchorPoint = Vector2.new(0, 0);
		newItemDisplay.Frame.Position = UDim2.new(0, 0, 0, 0);
		newItemDisplay.Frame.Size = UDim2.new(0.5, 0, 0.5, 0);

	end
	
	local connWeapStatToggle = false;
	local function onSelectionChange()
		Interface.ClearSelection();
		Interface:CloseWindow("WeaponStats");
		
		if modConfigurations.CompactInterface then
			if connWeapStatToggle == false then
				connWeapStatToggle = true;

				if Interface.Windows.WeaponStats then
					Interface.Windows.WeaponStats.OnWindowToggle:Connect(function(visible)
						if visible then
							newItemDisplay.Frame.Size = UDim2.new(0.5, 0, 0.5, 0);
						else
							newItemDisplay.Frame.Size = UDim2.new(0.5, 0, 1, 0);
						end
					end)
				end
			end
		end

		if selectedSlot then
			newItemDisplay.Frame.Visible = true;
			local itemId = selectedSlot.Item.ItemId;
			local itemLib = modItemLibrary:Find(itemId);

			if newItemDisplay.OnDisplayID ~= selectedSlot.Item.ID then
				remoteStorageItemSync:FireServer("update", selectedSlot.Item.ID);
				newItemDisplay:SetDisplay(selectedSlot.Item);
			end

			for key, wb in pairs(Interface.Workbenches) do
				if key == "Appearance" and itemLib.Type ~= modItemLibrary.Types.Clothing then
					continue;
				end

				if wb.Library and wb.Workbench then
					if wb.Library[itemId] or (modItemUnlockablesLibrary:Find(itemId) and key == "Appearance") then

						Interface.ActiveWorkbenches[key] = wb.Workbench.new(itemId, Interface.Workbenches[key].Library[itemId], selectedSlot.Item);
						if Interface.ActiveWorkbenches[key] then
							Interface.ActiveWorkbenches[key].Menu.Parent = pageFrame;
						end
					end
				end
			end
			if Interface.ActiveWorkbenches.Build then
				if Interface.ActiveWorkbenches.Blueprints then
					Interface.ActiveWorkbenches.Blueprints.Menu:Destroy();
					Interface.ActiveWorkbenches.Blueprints = nil;
				end
			end
			if (itemLib.Type == modItemLibrary.Types.Tool or itemLib.Type == modItemLibrary.Types.Clothing) and Interface.ActiveWorkbenches.Upgrades then
				Interface.SetPage(Interface.ActiveWorkbenches.Upgrades.Menu);

			elseif itemLib.Type == modItemLibrary.Types.Mod then
				if Interface.ActiveWorkbenches.Upgrades == nil then
					Interface.ActiveWorkbenches.Upgrades = Interface.Workbenches.Upgrades.Workbench.new(itemId, itemLib, selectedSlot.Item);
				end
				Interface.SetPage(Interface.ActiveWorkbenches.Upgrades.Menu);

			elseif itemLib.Type == modItemLibrary.Types.Blueprint and Interface.ActiveWorkbenches.Build then
				Interface.SetPage(Interface.ActiveWorkbenches.Build.Menu);
			end
		else
			newItemDisplay.Frame.Visible = false;
		end
		Interface.RefreshNavigations();
	end

	local function clearSlotHighlight(slot)
		for id, button in pairs(defaultInterface.Buttons) do
			if (slot == nil or id ~= slot.ID) and button.Button then
				button.Button.BackgroundTransparency = 1;
			end
		end
		for id, button in pairs(premiumInterface.Buttons) do
			if (slot == nil or id ~= slot.ID) and button.Button then
				button.Button.BackgroundTransparency = 1;
			end
		end
		for id, button in pairs(clothingInterface.Buttons) do
			if (slot == nil or id ~= slot.ID) and button.Button then
				button.Button.BackgroundTransparency = 1;
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
			Interface:PlayButtonClick();
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

			modStorageInterface.GlobalItemToolTipObject:SetPosition(button)
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

	Interface.List = ListMenu;

	--== List Mods;
	Interface.ListMods = require(script.ListMods).init(Interface);

	--== General functions;
	function Interface.SetPage(pageObject)
		for _, frame in pairs(pageFrame:GetChildren()) do
			if frame:IsA("GuiObject") then
				frame.Visible = frame == pageObject;
			end
		end
		for navName, listMenu in pairs(Interface.ActiveWorkbenches) do
			if listMenu.Menu == pageObject then
				Interface.ActivePage = navName;
				
				if listMenu.OnMenuToggle then
					listMenu:OnMenuToggle();
				end
				
				for _, obj in pairs(navButtons) do
					if obj:IsA("ImageButton") then
						obj.ImageColor3 = Interface.ActivePage == obj.Name and branchColor or Color3.fromRGB(255, 255, 255);
					end
				end
			end
		end
		Interface.RefreshNavigations();
		modStorageInterface.ToggleDesc(false);
	end

	function Interface.ClearPages(name)
		for _, frame in pairs(pageFrame:GetChildren()) do
			if frame.Name == name then
				frame:Destroy();
			end
		end
	end

	function Interface.RefreshNavigations()
		for _, obj in pairs(navButtons) do
			if obj:IsA("ImageButton") then
				obj.Visible = Interface.ActiveWorkbenches[obj.Name] ~= nil;
			end
		end
	end

	function Interface.ForceClear()
		Interface:OpenWindow("Inventory");
		clearSlotHighlight();
		selectedSlot = nil;
		Interface.SelectedSlot = selectedSlot;
		onSelectionChange();
	end

	local function onItemSelect(interface, slot)
		if selectedSlot == nil or selectedSlot.ID ~= (slot and slot.ID or 0) then
			clearSlotHighlight(slot);
			Interface:PlayButtonClick();

			slot.Button.BackgroundTransparency = 0.3;
			slot.Button.BackgroundColor3 = branchColor;

			remoteWorkbenchInteract:FireServer(true);
			selectedSlot = slot;
			Interface.SelectedSlot = selectedSlot;
			onSelectionChange();
			if modConfigurations.CompactInterface then
				Interface:CloseWindow("Inventory");
			end
		else
			Interface.ForceClear();
		end
	end

	for _, obj in pairs(navButtons) do
		if obj:IsA("ImageButton") then
			local function updateButtonColors()
				for _, button in pairs(navButtons) do
					if button:IsA("ImageButton") then
						button.ImageColor3 = (button == obj or Interface.ActivePage == button.Name) and branchColor or Color3.fromRGB(255, 255, 255);
						button.label.Visible = button == obj;
					end
				end
			end

			obj.MouseButton1Click:Connect(function()
				if Interface.ActiveWorkbenches[obj.Name] then
					Interface:PlayButtonClick();
					Interface.SetPage(Interface.ActiveWorkbenches[obj.Name].Menu);
				end
				updateButtonColors();
			end)
			obj.MouseEnter:Connect(updateButtonColors)
			obj.MouseLeave:Connect(function()
				obj.ImageColor3 = Interface.ActivePage == obj.Name and branchColor or Color3.fromRGB(255, 255, 255);
				obj.label.Visible = false;
			end)
		end
	end

	local processTypeSorting = {BuildComplete=1; Deconstruction=2; PolishTool=3; Building=10;};
	function Interface.GetProcesses()
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

		processesTag.Text = ("($c/$t)"):gsub("$c", tostring(#processes)):gsub("$t", Interface.IsPremium and "10" or "5");

		return processes;
	end
	
	function Interface.LoadProcesses()
		if Interface.ActiveWorkbenches.Processes then return end;
		Interface.ActiveWorkbenches.Processes = Interface.Workbenches.Processes.Workbench.new();
		Interface.ActiveWorkbenches.Processes.Menu.Parent = pageFrame;
	end
	
	function Interface.ClearSelection()
		for k, listMenu in pairs(Interface.ActiveWorkbenches) do
			listMenu:Destroy();
			Interface.ActiveWorkbenches[k] = nil;
		end
		
		Interface.ActiveWorkbenches.Blueprints = Interface.Workbenches.Blueprints.Workbench.new();
		Interface.ActiveWorkbenches.Blueprints.Menu.Parent = pageFrame;
		Interface.ActiveWorkbenches.Blueprints.Menu.Name = "bpListFrame";
		
		newItemDisplay:Clear();

		local processes = Interface.GetProcesses();
		if #processes > 0 then
			Interface.LoadProcesses();
			Interface.SetPage(Interface.ActiveWorkbenches.Processes.Menu);
		else
			Interface.SetPage(Interface.ActiveWorkbenches.Blueprints.Menu);
		end
	end
	
	
	local workbenchWindow = Interface.NewWindow("Workbench", workbenchFrame);
	workbenchWindow.CompactFullscreen = true;
	if modConfigurations.CompactInterface then
		workbenchWindow:SetOpenClosePosition(UDim2.new(1, 0, 0, 0), UDim2.new(1, 0, 1, 0));
		
		workbenchFrame:WaitForChild("TitleFrame"):WaitForChild("touchCloseButton"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
			Interface:CloseWindow("Workbench");
		end)
	else
		workbenchWindow:SetOpenClosePosition(UDim2.new(1, -10, 0.5, 0), UDim2.new(2, 0, 0.5, 0));
	end
	workbenchWindow:SetConfigKey("DisableWorkbench", function()
		return modData.Profile and modData.Profile.GamePass and modData.Profile.GamePass.PortableWorkbench ~= nil;	
	end);
	
	workbenchWindow.OnWindowToggle:Connect(function(visible, packet)
		packet = packet or {};
		
		spawn(function()
			Interface.IsPremium = modData.Profile ~= nil and modData.Profile.Premium or false;
			newItemDisplay.Frame.Visible = false;
			workbenchTitleLabel.Text = "Workbench";
			
			remoteWorkbenchInteract:FireServer(visible);
			if visible then
				modData:RequestData("GameSave/Workbench");
				modData:RequestData("GameSave/Blueprints");
				
				Interface.ClearSelection();
				Interface.RefreshNavigations();
				defaultInterface.OnItemButton1Click = onItemSelect;
				premiumInterface.OnItemButton1Click = onItemSelect;
				clothingInterface.OnItemButton1Click = onItemSelect;
				
				Interface:HideAll{[workbenchWindow.Name]=true; ["Inventory"]=true; ["WeaponStats"]=true};
				Interface:ToggleInteraction(false);
				Interface:OpenWindow("Inventory");
				if not (modData.Profile ~= nil and modData.Profile.GamePass and modData.Profile.GamePass.PortableWorkbench) then
					spawn(function()
						repeat until not workbenchWindow.Visible or Interface.Object == nil or not Interface.Object:IsDescendantOf(workspace) or Interface.modCharacter.Player:DistanceFromCharacter(Interface.Object.Position) >= 16 or not wait(0.5);
						Interface:ToggleWindow("Inventory", false);
					end)
				end

			else
				for k, listMenu in pairs(Interface.ActiveWorkbenches) do
					listMenu.Menu.Visible = false;
				end

				task.delay(0.1, function()
					Interface.ClearSelection();
				end)
				clearSlotHighlight();
				selectedSlot = nil;
				Interface.SelectedSlot = selectedSlot;
				defaultInterface.OnItemButton1Click = Interface.modInventoryInterface.DefaultInterface.BeginDragItem;
				premiumInterface.OnItemButton1Click = Interface.modInventoryInterface.PremiumInterface.BeginDragItem;
				clothingInterface.OnItemButton1Click = Interface.modInventoryInterface.ClothingInterface.BeginDragItem;
				
				if packet.DontCloseInventory ~= true then
					Interface:CloseWindow("Inventory");
				end
				Interface:CloseWindow("WeaponStats");
				task.delay(0.3, function()
					Interface:ToggleInteraction(true);
				end)
			end

			modData:RequestData("ItemUnlockables");
		end)
	end)
	
	
	modKeyBindsHandler:SetDefaultKey("KeyWindowWorkbench", Enum.KeyCode.N);
	local quickButton = Interface:NewQuickButton("Workbench", "Workbench", "rbxassetid://2273400846");
	quickButton.LayoutOrder = 15;
	modInterface:ConnectQuickButton(quickButton, "KeyWindowWorkbench");
	
	return Interface;
end;

function Interface.PlayUpgradeSound()
	modAudio.Preload("StorageWeaponPickup", 5);
	modAudio.Play("StorageWeaponPickup", nil, nil, false);
end

function Interface.PlayCollectSound()
	modAudio.Preload("StorageItemPickup", 5);
	modAudio.Play("StorageItemPickup", nil, nil, false);
end

return Interface;