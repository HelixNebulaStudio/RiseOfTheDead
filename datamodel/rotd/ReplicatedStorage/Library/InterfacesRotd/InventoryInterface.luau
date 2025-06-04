local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local UserInputService = game:GetService("UserInputService");
local TweenService = game:GetService("TweenService");

local localPlayer = game.Players.LocalPlayer;
local camera = workspace.CurrentCamera;

local modItem = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modConfigurations = shared.require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));
local modKeyBindsHandler = shared.require(game.ReplicatedStorage.Library.KeyBindsHandler);
local modUsableItems = shared.require(game.ReplicatedStorage.Library.UsableItems);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local modStorageInterface = shared.require(game.ReplicatedStorage.Library.UI.StorageInterface);

local interfacePackage = {
    Type = "Character";
	LoadOrder = 10;
};
--==


local CharacterConfigurations = {
	-- Defensive;
	["ArmorPoints"] = function(bodyEquips, k)
		local value = bodyEquips[k];
		return {SortKey="AAProtectArmor"; Text=`<b>Armor Points:</b> {value} AP`;}
	end;
	["HealthPoints"] = function(bodyEquips, k)
		local value = bodyEquips[k];
		return {SortKey="AAProtectHealth"; Text=`<b>Health Points:</b> {value} HP`;}
	end;

	["BulletProtection"] = function(bodyEquips, k)
		local value = bodyEquips[k];
		return {SortKey="AProtectBullet"; Text=`<b>Bullet Protection:</b> {string.format("%.1f", value*100)}%`;}
	end;
	["GasProtection"] = function(bodyEquips, k)
		local value = bodyEquips[k];
		if bodyEquips.LabCoat then
			value = value + bodyEquips.LabCoat;
		end
		return {SortKey="AProtectGas"; Text=`<b>Gas Protection:</b> {string.format("%.0f", value*100)}%`;}
	end;
	["FlinchProtection"] = function(bodyEquips, k)
		local value = bodyEquips[k];
		return {SortKey="AProtectFlinch"; Text=`<b>Flinch Protection:</b> {string.format("%.0f", value*100)}%`;}
	end;
	["TickRepellent"] = function(bodyEquips, k)
		local value = bodyEquips[k];
		return {SortKey="AProtectTicks"; Text=`<b>Ticks Protection:</b> {string.format("%.0f", value)}s`;}
	end;

	-- Status Resistance;
	["MoveImpairReduction"] = function(bodyEquips, k)
		local value = bodyEquips[k];
		return {SortKey="BuffMoveIR"; Text=`<b>Move Impair Reduction:</b> {string.format("%.1f", value*100)}%`;}
	end;

	-- Enchancments;
	["EquipTimeReduction"] = function(bodyEquips, k)
		local value = bodyEquips[k];
		return {SortKey="EnhanceEquipTimeReduction"; Text=`<b>Equip Time Reduction:</b> {string.format("%.0f", value*100)}%`;}
	end;
	["HotEquipSlots"] = function(bodyEquips, k)
		local value = bodyEquips[k];
		return {SortKey="EnhanceHS"; Text=`<b>Hotbar Slots:</b> {5+math.max(value, 0)}`;}
	end;

	-- Melee;
	["AdditionalStamina"] = function(bodyEquips, k)
		local value = bodyEquips[k];
		return {SortKey="MeleeStamina"; Text=`<b>Additional Stamina:</b> {string.format("%.0f", value)}`;}
	end;

	-- Offensive;
	["SplashReflection"] = function(bodyEquips, k)
		local value = bodyEquips[k];
		return {SortKey="ReflectSplash"; Text=`<b>Splash Reflection:</b> {string.format("%.1f", value*100)}%`;}
	end;
	["DamageReflection"] = function(bodyEquips, k)
		local value = bodyEquips[k];
		return {SortKey="ReflectDamage"; Text=`<b>Damage Reflection:</b> {string.format("%.1f", value*100)}%`;}
	end;

	-- Swimming;
	["OxygenDrainReduction"] = function(bodyEquips, k)
		local value = bodyEquips[k];
		return {SortKey="SwimOxygenD"; Text=`<b>Oxygen Drain Reduction:</b> {string.format("%.0f", value*100)}%`;}
	end;
	["OxygenRecoveryIncrease"] = function(bodyEquips, k)
		local value = bodyEquips[k];
		return {SortKey="SwimOxygenR"; Text=`<b>Oxygen Recovery Increase:</b> {string.format("%.1f", value*100)}%`;}
	end;
	["UnderwaterVision"] = function(bodyEquips, k)
		local value = bodyEquips[k];
		return {SortKey="SwimVision"; Text=`<b>Underwater Vision:</b> +{string.format("%.1f", value*100)}%`;}
	end;
	["SwimmingSpeed"] = function(bodyEquips, k)
		local value = bodyEquips[k];
		return {SortKey="SwimSpeed"; Text=`<b>Swimming Speed:</b> +{string.format("%.0f", value)} u/s`;}
	end;
};


function interfacePackage.newInstance(interface: InterfaceInstance)
	local remoteToggleDefaultAccessories = modRemotesManager:Get("ToggleDefaultAccessories");
	local remoteStorageService = modRemotesManager:Get("StorageService");
	local remoteItemActionHandler = modRemotesManager:Get("ItemActionHandler");
	local remoteUseStorageItem = modRemotesManager:Get("UseStorageItem");
	local remoteToggleClothing = modRemotesManager:Get("ToggleClothing");

	local modData = shared.require(localPlayer:WaitForChild("DataModule"));

	local interfaceScreenGui = interface.ScreenGui;

	local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);
	local configurations: ConfigVariable = playerClass.Configurations;

	local modCharacter = modData:GetModCharacter();
	
	local inventoryFrame = modConfigurations.CompactInterface 
						and script:WaitForChild("MobileInventory"):Clone() 
						or script:WaitForChild("Inventory"):Clone();
	inventoryFrame.Name = "Inventory";
	inventoryFrame.Parent = interfaceScreenGui;
	local inventorySlotLists = inventoryFrame;
	
	local inventoryWindow: InterfaceWindow = interface:NewWindow("Inventory", inventoryFrame);
	inventoryWindow.CompactFullscreen = true;
	interface:BindConfigKey("DisableInventory", {inventoryWindow});
	
	if modConfigurations.CompactInterface then
		inventoryFrame:WaitForChild("TitleFrame"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
			inventoryWindow:Close();
		end)
		inventoryWindow:SetClosePosition(UDim2.new(0, 0, 1, 0), UDim2.new(0, 0, 0, 0));
	else
		inventoryWindow:SetClosePosition(UDim2.new(-1, 0, 0.5, 0), UDim2.new(0, 10, 0.5, 0));
	end

	modKeyBindsHandler:SetDefaultKey("KeyWindowInventory", Enum.KeyCode.Tab);
	local quickButton = interface:NewQuickButton("Inventory", "Inventory", "rbxassetid://2169843985");
	quickButton.LayoutOrder = 2;
	interface:ConnectQuickButton(quickButton, "KeyWindowInventory");


	local hotbarFrame = script.Hotbar:Clone(); --interfaceScreenGui:WaitForChild("Hotbar");
	hotbarFrame.Parent = interfaceScreenGui;
	
	local templateHotbarSlot = script:WaitForChild("hotbarSlot");
	local templateTClothingOption = script:WaitForChild("toggleClothingOption");
	local temperatureLabel, bodyEquipmentsFrame;
	
	local hotbarWindow: InterfaceWindow = interface:NewWindow("Hotbar", hotbarFrame);
	hotbarWindow.IgnoreHideAll = true;
	hotbarWindow.ReleaseMouse = false;
	hotbarWindow:Open();
	interface:BindConfigKey("DisableHotbar", {hotbarWindow});

	if modConfigurations.CompactInterface then
        interface.Properties.OnChanged:Connect(function(k, v)
            if k == "IsCompactFullscreen" then
                if modConfigurations.DisableHotbar then
                    hotbarFrame.Visible = false;
                else
                    hotbarFrame.Visible = not v;
                end
            end
        end)
        
		inventorySlotLists = inventoryFrame:WaitForChild("Inventory");

		local armorTitleLabel: TextLabel = inventorySlotLists:WaitForChild("ArmorTitle");
		temperatureLabel = armorTitleLabel:WaitForChild("temperatureLabel");
		bodyEquipmentsFrame = armorTitleLabel:WaitForChild("BodyEquipmentStats");

		interface.Garbage:Tag(armorTitleLabel.InputBegan:Connect(function(inputObject)
			if inputObject.UserInputType == Enum.UserInputType.MouseButton1 
			or inputObject.UserInputType == Enum.UserInputType.Touch then
				bodyEquipmentsFrame.Visible = not bodyEquipmentsFrame.Visible;
			end
		end))
		
		hotbarFrame.AnchorPoint = Vector2.new(0.5, 1);
		hotbarFrame.Position = UDim2.new(0.5, 0, 1, -50);
		hotbarFrame.Size = UDim2.new(0, 50, 0, 0);
		
		templateTClothingOption.Size = UDim2.new(1, 0, 0, 30);

		local padding = Instance.new("UIPadding");
		padding.PaddingRight = UDim.new(0, 15);
		padding.Parent = inventorySlotLists;

	else
		interface.OnWindowToggle:Connect(function(window: InterfaceWindow, visible: boolean, ...)
			if window.Name == "WeaponStats" then
				if visible then
					hotbarWindow:Close();
				elseif modConfigurations.DisableHotbar ~= true then
					hotbarWindow:Open();
				end

			elseif window.Name == "RatShopWindow" then
				if visible and camera.ViewportSize.Y <= 910 then
					hotbarWindow:Close();
				elseif modConfigurations.DisableHotbar ~= true then
					hotbarWindow:Open();
				end

			end
		end)

		local armorTitleLabel: TextLabel = inventoryFrame:WaitForChild("ArmorTitle");
		temperatureLabel = armorTitleLabel:WaitForChild("temperatureLabel");
		bodyEquipmentsFrame = armorTitleLabel:WaitForChild("BodyEquipmentStats");
		
		interface.Garbage:Tag(armorTitleLabel.MouseEnter:Connect(function()
			bodyEquipmentsFrame.Visible = true;
		end))
		interface.Garbage:Tag(armorTitleLabel.MouseLeave:Connect(function()
			bodyEquipmentsFrame.Visible = false;
		end))
		
	end

	local toggleClothingButton = inventoryFrame:WaitForChild("ToggleClothing");
	local clothingToggleMenu = toggleClothingButton:WaitForChild("Frame");

	local defaultSlots = {}; for _,value in pairs(inventorySlotLists.MainList:GetChildren()) do if value:IsA("GuiObject") and value.LayoutOrder > 0 then value:SetAttribute("Index", value.LayoutOrder); table.insert(defaultSlots, value) end end;
	local premiumSlots = {}; for _,value in pairs(inventorySlotLists.PremiumList:GetChildren()) do if value:IsA("GuiObject") and value.LayoutOrder > 0 then value:SetAttribute("Index", value.LayoutOrder); table.insert(premiumSlots, value) end end;
	local hotBarSlots = {}; for _,value in pairs(hotbarFrame:GetChildren()) do if value:IsA("GuiObject") and value.LayoutOrder > 0 then value:SetAttribute("Index", value.LayoutOrder); table.insert(hotBarSlots, value) end end;
	local clothingSlots = {}; for _,value in pairs(inventorySlotLists.ArmorList:GetChildren()) do if value:IsA("GuiObject") and value.LayoutOrder > 0 then value:SetAttribute("Index", value.LayoutOrder); table.insert(clothingSlots, value) end end;

	local defaultStorageInterface = modStorageInterface.new("Inventory", inventoryFrame, defaultSlots);
	defaultStorageInterface.Name = "DefaultInterface";
	
	local premiumStorageInterface = modStorageInterface.new("Inventory", inventoryFrame, premiumSlots);
	premiumStorageInterface.Name = "PremiumInterface";
	premiumStorageInterface.PremiumOnly = true;

	function premiumStorageInterface:DecorateSlot(index, slotTable)
		local slotFrame = slotTable.Frame;
		slotFrame.ImageColor3 = Color3.fromRGB(75, 50, 50);
	end
	
	local hotbarStorageInterface = modStorageInterface.new("Inventory", hotbarFrame, hotBarSlots);
	hotbarStorageInterface.Name = "HotbarInterface";
	hotbarStorageInterface.DisableContextMenu = true;
	
	hotbarFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		if hotbarFrame.Visible == false then return end;
		hotbarStorageInterface:Update();
	end)
	
	local clothingStorageInterface = modStorageInterface.new("Clothing", inventoryFrame, clothingSlots);
	clothingStorageInterface.Name = "ClothingInterface";
	clothingStorageInterface:ConnectDepositLimit(function(slotInterface, slotTable, slotTableB)
		if slotTable.Library.Type ~= modItem.Types.Clothing then
			if not slotInterface.WarnLabel.Visible then
				slotInterface.WarnLabel.Text = "Clothing Only!"
				slotInterface.WarnLabel.Visible = true;
				delay(1, function()
					slotInterface.WarnLabel.Visible = false;
				end)
			end
			if slotTable then slotTable.Button:TweenPosition(UDim2.new(), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.1, true); end
			if slotTableB then slotTableB.Button:TweenPosition(UDim2.new(), Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 0.1, true); end
			return false;
		end
		return;
	end);
	
	clothingStorageInterface:AddContextOption({
		Text="Wardrobe";
		Check=function(Table)
			return Table.Library.Type == "Clothing" and Table.Library.CanVanity ~= false;
		end;
		Click=function(Table)
			interface:ToggleWindow("ExternalStorage", true, "Wardrobe", nil, Table.ID);
		end;
		Order=0;
	})

	--== Shared Context Options;
	local equipContextOption = {
		Text=function(Table)
			return Table.Item.Values.IsEquipped == nil and "Equip" or "Unequip";
		end;
		Check=function(Table)
			return Table.Library.Equippable;
		end;
		Click=function(Table)
			if Table.Item.Values.IsEquipped == nil then
				modData.HandleTool("equip", {Siid=Table.ID; ItemId=Table.ItemId});
				inventoryWindow:Close();
				
			else
				modData.HandleTool("unequip", {Siid=Table.ID; ItemId=Table.ItemId});
				
			end
		end;
		Order=1;
		HotInteract=true;
	};
	defaultStorageInterface:AddContextOption(equipContextOption);
	premiumStorageInterface:AddContextOption(equipContextOption);
	
	local renameContextOption = {
		Text="Rename";
		Check=function(Table)
			if Table.Item.Fav then
				return false;
			end
			if Table.Library.Stackable or Table.Item.Quantity > 1 then
				return false;
			end
			if Table.Library.CanBeRenamed == false then
				return false;
			end
			return true;
		end;
		Click=function(Table)
			inventoryWindow:Close();
			local storageItem = modData.GetItemById(Table.Item.ID);
			if storageItem then
				Debugger:StudioLog(`Rename StorageItem:`, storageItem);
				interface:ToggleWindow("RenameItem", true, storageItem);
			end
			modStorageInterface.CloseOptionMenus();
		end;
		Order=8;
	};
	defaultStorageInterface:AddContextOption(renameContextOption);
	premiumStorageInterface:AddContextOption(renameContextOption);
	clothingStorageInterface:AddContextOption(renameContextOption);

	local removePatContextOption = {
		Text="Remove Skin";
		Check=function(Table)
			if Table.Item.Fav then
				return false;
			end
			if Table.Item.Values.ActiveSkin == nil then
				return false;
			end

			local modSkinsLibrary = shared.require(game.ReplicatedStorage.Library:WaitForChild("SkinsLibrary"));
			local lib = modSkinsLibrary.Get(Table.Item.Values.ActiveSkin);

			if lib == nil or lib.CanClear == false then
				return false;
			end
			
			return true;
		end;
		Click=function(Table)
			local promptWindow = modClientGuis.promptQuestion("Remove Skin-Permanent?",
				"Are you sure you want to remove the skin permanent?", 
				"Yes", "Nevermind");
			local YesClickedSignal, NoClickedSignal;

			YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
				interface:PlayButtonClick();

				remoteItemActionHandler:FireServer(Table.Interface.StorageId, Table.ID, "delpat");
				
				promptWindow:Close();
				promptWindow = nil;

				YesClickedSignal:Disconnect();
				NoClickedSignal:Disconnect();
			end);
			NoClickedSignal = promptWindow.Frame.No.MouseButton1Click:Connect(function()
				interface:PlayButtonClick();
				promptWindow:Close();
				promptWindow = nil;

				YesClickedSignal:Disconnect();
				NoClickedSignal:Disconnect();
			end);
		end;
		Order=9;
	};
	defaultStorageInterface:AddContextOption(removePatContextOption);
	premiumStorageInterface:AddContextOption(removePatContextOption);
	
	local favoriteContextOption = {
		Text=function(slotItem)
			return slotItem.Item.Fav == true and "Unfavorite" or "Favorite";
		end;
		Click=function(slotItem)
			remoteItemActionHandler:FireServer(slotItem.Interface.StorageId, slotItem.ID, "setfav");
		end;
		Order=7;
	};
	defaultStorageInterface:AddContextOption(favoriteContextOption);
	premiumStorageInterface:AddContextOption(favoriteContextOption);
	clothingStorageInterface:AddContextOption(favoriteContextOption);

	local useDebounce = false;
	local usableContextOption = {
		Id="Usable";
		Text=function(Table)
			return Table.Library.Usable or "Use";
		end;
		Check=function(Table)
			return Table.Library.Type == "Usable" or Table.Library.Usable ~= nil;
		end;
		Click=function(Table)
			if useDebounce then return end;
			useDebounce = true;

			local usableItemLib = modUsableItems:Find(Table.Item.ItemId);
			if usableItemLib then
				local invokeServer = usableItemLib:ClientUse(Table.Item);
				if invokeServer ~= false then
					remoteUseStorageItem:InvokeServer(Table.Interface.StorageId, Table.ID);
				end
			end

			useDebounce = false;
		end;
		Order=5;
		HotInteract=true;
	};
	defaultStorageInterface:AddContextOption(usableContextOption);
	premiumStorageInterface:AddContextOption(usableContextOption);
	clothingStorageInterface:AddContextOption(usableContextOption);

	local toggleWearDebounce = false;
	local clothingContextOption = {
		Text=function(Table)
			local storageItem = Table.Item;
			local noWearTag = storageItem.Values and storageItem.Values.NoWear;

			return noWearTag == nil and "Hide" or "Show";
		end;
		Check=function(Table)
			return Table.Library.Type == "Clothing" and Table.Library.CanVanity ~= false;
		end;
		Click=function(Table)
			if toggleWearDebounce then return end;
			toggleWearDebounce = true;
			local _setWear = remoteToggleClothing:InvokeServer(Table.Interface.StorageId, Table.ID);
			--local noWearTag = storageItem.Values and storageItem.Values.NoWear;
			toggleWearDebounce = false;
		end;
		Order=7;
	};
	clothingStorageInterface:AddContextOption(clothingContextOption);


	--== Shared Context Options;
	local function handleStorage(action, request, storageIds)
		local rPacket = remoteStorageService:InvokeServer({
			Action=action;
			StorageIds=(storageIds or {"Inventory"; "Clothing"; "Wardrobe"});
			Request=request;
		});

		if rPacket.Storages then
			for storageId, _ in pairs(rPacket.Storages) do
				modData.SetStorage(rPacket.Storages[storageId]);
			end
		end
	end

	interface.Properties.ActiveHotbarKeys = 5;
	interface.Properties.HotEquip = function(index)
		if not modCharacter.CharacterProperties.IsAlive then return end;
		if modData.Storages.Inventory == nil then return end;
		
		local slot = hotbarStorageInterface.Slots[index];
		if slot and slot.Table then
			hotbarStorageInterface:UseItem(slot.Table);
			
		end
	end
	
	function hotbarWindow.Binds.UpdateHotbarSize()
		interface.Properties.ActiveHotbarKeys = configurations.HotEquipSlots;
		
		local updatedSlots = {};
		
		local hotbarSlots = {};
		for a=1, math.clamp(interface.Properties.ActiveHotbarKeys, 1, 10) do
			local new = hotbarFrame:FindFirstChild(a) or templateHotbarSlot:Clone();
			
			local label = new:WaitForChild("label");
			new.Name = a;
			new.LayoutOrder = a;
			new:SetAttribute("Index", a);
			updatedSlots[new] = true;
			
			if modConfigurations.CompactInterface then
				new.Size = UDim2.new(0, hotbarFrame.Size.X.Offset, 0, hotbarFrame.Size.X.Offset);
			end
			new.Parent = hotbarFrame;
			label.Text = a;
			table.insert(hotbarSlots, new);
		end
		for _, obj in pairs(hotbarFrame:GetChildren()) do
			if obj:IsA("GuiObject") and updatedSlots[obj] ~= true then
				obj:Destroy();
			end
		end
		
		hotbarStorageInterface:UpdateSlotFrames(hotbarSlots);
		
		-- overlapping glitch here
		hotbarStorageInterface:Update();
	end
	
	local function listCharacterConfigurations()
		local label = bodyEquipmentsFrame:WaitForChild("label");
		local beStr = {};

		for k, v in pairs(configurations:GetKeyPairs()) do
			if k == "Warmth" and configurations.Warmth then
				local warmth = localPlayer:GetAttribute("Warmth") or 25;
				table.insert(beStr, {SortKey="Warmth"; Text=`<b>Warmth:</b> {warmth} °C`;});

			elseif k == "ActiveProperties" then
				for activePassive, _ in pairs(v) do
					table.insert(beStr, {SortKey="ZZPassive"; Text=`<b>+ Passive</b> {activePassive}`;});
				end

			elseif CharacterConfigurations[k] then
				table.insert(beStr, CharacterConfigurations[k](configurations, k));
				
			end
		end

		table.sort(beStr, function(a, b) return a.SortKey < b.SortKey; end)
		for a=1, #beStr do
			beStr[a] = beStr[a].Text;
		end

		label.Text = table.concat(beStr, "\n");
	end


	local function updateWarmth()
		local warmth = localPlayer:GetAttribute("Warmth") or 25;
		temperatureLabel.Text = warmth.."°C";
	end
	
	inventoryWindow.OnToggle:Connect(function(visible)
		if visible then
			if modData.Storages["Inventory"] == nil or modData.Storages["Clothing"] == nil then
				handleStorage("RequestStorage", true);
			end
			
			handleStorage("OpenStorage" ,true);
			modStorageInterface.UpdateStorages{
				modData.Storages["Inventory"],
				modData.Storages["Clothing"]
			};
			updateWarmth();
			modStorageInterface.QueueRefreshStorage();

		else
			clothingToggleMenu.Visible = false;
			defaultStorageInterface:StopDragItem();

			defaultStorageInterface:ToggleDescriptionFrame(false, nil, 0.3);
			modStorageInterface.CloseOptionMenus();

			if not modConfigurations.CompactInterface then
				-- or (Interface.modWorkbenchInterface and Interface.modWorkbenchInterface.SelectedSlot == nil) 
				interface:ToggleWindow("Workbench", false);
				interface:ToggleWindow("WeaponStats", false);
			end
			interface:ToggleWindow("ExternalStorage", false);
			interface:ToggleWindow("SupplyStation", false);
			interface:ToggleWindow("RatShopWindow", false);
			
			task.spawn(function()
				local _rPacket = remoteStorageService:InvokeServer({
					Action="CloseStorage";
					StorageIds={"Inventory"; "Clothing"};
				});
			end)
		end
	end)
	hotbarStorageInterface.OnItemButton1Click = hotbarStorageInterface.UseItem;
	hotbarWindow.Binds.UpdateHotbarSize();
	
	
	task.spawn(function()
		handleStorage("RequestStorage", true);

		local storageIds = {};
		
		local function getRequestSid(storageContainer)
			if storageContainer == nil then return end;

			for id, storageItem in pairs(storageContainer) do
				table.insert(storageIds, id);

				local usableItemLib = modUsableItems:Find(storageItem.ItemId);
				if usableItemLib and usableItemLib.PortableStorage then
					local storageConfig = usableItemLib.PortableStorage;
					local storageId = storageConfig and storageConfig.StorageId or nil;

					if storageId then
						table.insert(storageIds, storageId);
					end
				end
			end
		end
		getRequestSid(modData.Storages["Inventory"].Container);
		getRequestSid(modData.Storages["Clothing"].Container);
		
		handleStorage("RequestStorage", true, storageIds);
		
		defaultStorageInterface:Update(modData.Storages["Inventory"]);
		premiumStorageInterface:Update(modData.Storages["Inventory"]);
		clothingStorageInterface:Update(modData.Storages["Clothing"]);

		hotbarWindow.Binds.UpdateHotbarSize();
	end)
	
	
	interface.Garbage:Tag(temperatureLabel.MouseMoved:Connect(function()
		temperatureLabel.Text = "Env: "..(workspace:GetAttribute("GlobalTemperature") or 25).."°C"; 
	end));
	interface.Garbage:Tag(temperatureLabel.MouseLeave:Connect(updateWarmth));
	interface.Garbage:Tag(bodyEquipmentsFrame:GetPropertyChangedSignal("Visible"):Connect(listCharacterConfigurations));
	
	toggleClothingButton.MouseButton1Click:Connect(function()
		interface:PlayButtonClick();
		clothingToggleMenu.Visible = not clothingToggleMenu.Visible;
		
		if not clothingToggleMenu.Visible then return end;

		for _, obj in pairs(clothingToggleMenu:GetChildren()) do
			if obj:IsA("GuiObject") then
				obj:Destroy();
			end
		end
			
		local appearanceFolder = localPlayer:FindFirstChild("Appearance");
		if appearanceFolder == nil then return end;

		for _, obj in pairs(appearanceFolder:GetChildren()) do
			local assetId = obj:GetAttribute("AssetId");
			if assetId then
				local asset = obj;
				local new = templateTClothingOption:Clone();
				new.Text = asset.Name;
				new.Parent = clothingToggleMenu;
				new.ZIndex = clothingToggleMenu.ZIndex;
				
				local function updateToggleClothing()
					if modData.Settings == nil or modData.Settings.ToggleClothing == nil then return end;
					
					local clothingSettings = modData.Settings.ToggleClothing;
					local value = clothingSettings[assetId];
					
					new.BackgroundColor3 = value == false and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(66, 91, 100);
					
					local character = localPlayer.Character;
					if character then
						modCharacter = modData:GetModCharacter();
						
						for _, obj in pairs(character:GetChildren()) do
							if obj:GetAttribute("AssetId") == assetId then
								for _, c in pairs(obj:GetChildren()) do
									if c:IsA("BasePart") then
										if modCharacter.CharacterProperties.FirstPersonCamera then
											c.Transparency = 1;
										else
											c.Transparency = value == false and 1 or 0;
										end
									end
								end
								break;
							end
						end
					end
				end
				
				new.MouseButton1Click:Connect(function()
					interface:PlayButtonClick();
					local clothingSettings = modData.Settings and modData.Settings.ToggleClothing or {};
					
					local value = clothingSettings[assetId];
					if value == nil then
						clothingSettings[assetId] = false;
					else
						clothingSettings[assetId] = nil;
					end

					remoteToggleDefaultAccessories:InvokeServer(assetId, clothingSettings[assetId]);
					updateToggleClothing();
				end)
				updateToggleClothing();
				
			end
		end
	end)

end

return interfacePackage;

