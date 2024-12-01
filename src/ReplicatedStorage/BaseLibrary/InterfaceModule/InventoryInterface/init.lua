local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local equipedBorderColor3 = Color3.fromRGB(200, 50, 50);

--== Variables;
local Interface = {};

local localPlayer = game.Players.LocalPlayer;
local RunService = game:GetService("RunService");
local UserInputService = game:GetService("UserInputService");
local TweenService = game:GetService("TweenService");

local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
local modItem = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modConfigurations = require(game.ReplicatedStorage.Library:WaitForChild("Configurations"));
local modKeyBindsHandler = require(game.ReplicatedStorage.Library.KeyBindsHandler);
local modUsableItems = require(game.ReplicatedStorage.Library.UsableItems);

local modStorageInterface = require(game.ReplicatedStorage.Library.UI.StorageInterface);

local remoteToggleDefaultAccessories = modRemotesManager:Get("ToggleDefaultAccessories");
local remoteStorageService = modRemotesManager:Get("StorageService");
local remoteItemActionHandler = modRemotesManager:Get("ItemActionHandler");
local remoteUseStorageItem = modRemotesManager:Get("UseStorageItem");
local remoteToggleClothing = modRemotesManager:Get("ToggleClothing");

--== Script;
local BodyEquipmentStats = {
	-- Defensive;
	["ModArmorPoints"] = function(bodyEquips, k)
		local value = bodyEquips[k];
		return {SortKey="AAProtectArmor"; Text=`<b>Armor Points:</b> {value} AP`;}
	end;
	["ModHealthPoints"] = function(bodyEquips, k)
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

function Interface.init(modInterface)
	setmetatable(Interface, modInterface);

	local interfaceScreenGui = localPlayer.PlayerGui:WaitForChild("MainInterface"); -- script.Parent.Parent 

	local modCharacter = modData:GetModCharacter();
	
	local inventoryFrame = modConfigurations.CompactInterface and script:WaitForChild("MobileInventory"):Clone() or script:WaitForChild("Inventory"):Clone();--interfaceScreenGui:WaitForChild("Inventory");
	inventoryFrame.Name = "Inventory";
	inventoryFrame.Parent = interfaceScreenGui;
	local inventorySlotLists = inventoryFrame;
	
	local hotbarFrame = script.Hotbar:Clone(); --interfaceScreenGui:WaitForChild("Hotbar");
	hotbarFrame.Parent = interfaceScreenGui;
	
	local templateHotbarSlot = script:WaitForChild("hotbarSlot");
	local templateTClothingOption = script:WaitForChild("toggleClothingOption");
	local temperatureLabel, bodyEquipmentsFrame;
	
	local hotbarWindow = Interface.NewWindow("Hotbar", hotbarFrame);
	hotbarWindow.Visible = true;
	hotbarWindow.IgnoreHideAll = true;
	hotbarWindow.ReleaseMouse = false;
	hotbarWindow:SetConfigKey("DisableHotbar");
	hotbarWindow:Open();
	
	function Interface:OnToggleHuds(value)
		if modConfigurations.CompactInterface then
			hotbarFrame.Visible = (not modConfigurations.DisableHotbar) and value;
		end
	end
	
	if modConfigurations.CompactInterface then
		inventorySlotLists = inventoryFrame:WaitForChild("Inventory");

		local armorTitleLabel: TextLabel = inventorySlotLists:WaitForChild("ArmorTitle");
		temperatureLabel = armorTitleLabel:WaitForChild("temperatureLabel");
		bodyEquipmentsFrame = armorTitleLabel:WaitForChild("BodyEquipmentStats");

		Interface.Garbage:Tag(armorTitleLabel.InputBegan:Connect(function(inputObject)
			if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
				bodyEquipmentsFrame.Visible = not bodyEquipmentsFrame.Visible;
			end
		end))
		
		--hotbarFrame.UIListLayout.FillDirection = Enum.FillDirection.Vertical;
		hotbarFrame.AnchorPoint = Vector2.new(0.5, 1);
		hotbarFrame.Position = UDim2.new(0.5, 0, 1, -60);
		hotbarFrame.Size = UDim2.new(0, 40, 0, 0);
		
		templateTClothingOption.Size = UDim2.new(1, 0, 0, 30);

		local padding = Instance.new("UIPadding");
		padding.PaddingRight = UDim.new(0, 15);
		padding.Parent = inventorySlotLists;

	else
		local armorTitleLabel: TextLabel = inventoryFrame:WaitForChild("ArmorTitle");
		temperatureLabel = armorTitleLabel:WaitForChild("temperatureLabel");
		bodyEquipmentsFrame = armorTitleLabel:WaitForChild("BodyEquipmentStats");
		
		Interface.Garbage:Tag(armorTitleLabel.MouseEnter:Connect(function()
			bodyEquipmentsFrame.Visible = true;
		end))
		Interface.Garbage:Tag(armorTitleLabel.MouseLeave:Connect(function()
			bodyEquipmentsFrame.Visible = false;
		end))
		
	end

	local toggleClothingButton = inventoryFrame:WaitForChild("ToggleClothing");
	local clothingToggleMenu = toggleClothingButton:WaitForChild("Frame");

	local defaultSlots = {}; for _,value in pairs(inventorySlotLists.MainList:GetChildren()) do if value:IsA("GuiObject") and value.LayoutOrder > 0 then value:SetAttribute("Index", value.LayoutOrder); table.insert(defaultSlots, value) end end;
	local premiumSlots = {}; for _,value in pairs(inventorySlotLists.PremiumList:GetChildren()) do if value:IsA("GuiObject") and value.LayoutOrder > 0 then value:SetAttribute("Index", value.LayoutOrder); table.insert(premiumSlots, value) end end;
	local hotBarSlots = {}; for _,value in pairs(hotbarFrame:GetChildren()) do if value:IsA("GuiObject") and value.LayoutOrder > 0 then value:SetAttribute("Index", value.LayoutOrder); table.insert(hotBarSlots, value) end end;
	local clothingSlots = {}; for _,value in pairs(inventorySlotLists.ArmorList:GetChildren()) do if value:IsA("GuiObject") and value.LayoutOrder > 0 then value:SetAttribute("Index", value.LayoutOrder); table.insert(clothingSlots, value) end end;

	Interface.HotbarSlotsNum = 5;
	Interface.DefaultInterface = modStorageInterface.new("Inventory", inventoryFrame, defaultSlots);
	Interface.DefaultInterface.Name = "DefaultInterface";
	
	Interface.PremiumInterface = modStorageInterface.new("Inventory", inventoryFrame, premiumSlots);
	Interface.PremiumInterface.Name = "PremiumInterface";
	Interface.PremiumInterface.PremiumOnly = true;

	function Interface.PremiumInterface:DecorateSlot(index, slotTable)
		local slotFrame = slotTable.Frame;
		slotFrame.ImageColor3 = Color3.fromRGB(75, 50, 50);
	end
	
	Interface.HotbarInterface = modStorageInterface.new("Inventory", hotbarFrame, hotBarSlots);
	Interface.HotbarInterface.Name = "HotbarInterface";
	Interface.HotbarInterface.DisableContextMenu = true;
	
	Interface.ClothingInterface = modStorageInterface.new("Clothing", inventoryFrame, clothingSlots);
	Interface.ClothingInterface.Name = "ClothingInterface";
	Interface.ClothingInterface:ConnectDepositLimit(function(slotInterface, slotTable, slotTableB)
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
	end);
	
	Interface.ClothingInterface:AddContextOption({
		Text="Wardrobe";
		Check=function(Table)
			return Table.Library.Type == "Clothing" and Table.Library.CanVanity ~= false;
		end;
		Click=function(Table)
			modInterface:OpenWindow("ExternalStorage", "Wardrobe", nil, Table.ID);
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
				modData.HandleTool("equip", {Id=Table.ID;});
				modInterface:CloseWindow("Inventory");
				
			else
				modData.HandleTool("unequip", {Id=Table.ID;});
				
			end
		end;
		Order=1;
	};
	Interface.DefaultInterface:AddContextOption(equipContextOption);
	Interface.PremiumInterface:AddContextOption(equipContextOption);
	
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
			modInterface:CloseWindow("Inventory");
			modInterface:OpenWindow("RenameWindow", Table.Item);
			modStorageInterface.CloseOptionMenus();
		end;
		Order=8;
	};
	Interface.DefaultInterface:AddContextOption(renameContextOption);
	Interface.PremiumInterface:AddContextOption(renameContextOption);
	Interface.ClothingInterface:AddContextOption(renameContextOption);

	local removePatContextOption = {
		Text="Remove Skin";
		Check=function(Table)
			if Table.Item.Fav then
				return false;
			end
			if Table.Item.Values.ActiveSkin == nil then
				return false;
			end

			local modSkinsLibrary = require(game.ReplicatedStorage.Library:WaitForChild("SkinsLibrary"));
			local lib = modSkinsLibrary.Get(Table.Item.Values.ActiveSkin);

			if lib == nil or lib.CanClear == false then
				return false;
			end
			
			return true;
		end;
		Click=function(Table)
			local promptWindow = Interface:PromptQuestion("Remove Skin-Permanent?",
				"Are you sure you want to remove the skin permanent?", 
				"Yes", "Nevermind");
			local YesClickedSignal, NoClickedSignal;

			YesClickedSignal = promptWindow.Frame.Yes.MouseButton1Click:Connect(function()
				Interface:PlayButtonClick();

				remoteItemActionHandler:FireServer(Table.Interface.StorageId, Table.ID, "delpat");
				
				promptWindow:Close();
				promptWindow = nil;

				YesClickedSignal:Disconnect();
				NoClickedSignal:Disconnect();
			end);
			NoClickedSignal = promptWindow.Frame.No.MouseButton1Click:Connect(function()
				Interface:PlayButtonClick();
				promptWindow:Close();
				promptWindow = nil;

				YesClickedSignal:Disconnect();
				NoClickedSignal:Disconnect();
			end);
		end;
		Order=9;
	};
	Interface.DefaultInterface:AddContextOption(removePatContextOption);
	Interface.PremiumInterface:AddContextOption(removePatContextOption);
	
	local favoriteContextOption = {
		Text=function(slotItem)
			return slotItem.Item.Fav == true and "Unfavorite" or "Favorite";
		end;
		Click=function(slotItem)
			remoteItemActionHandler:FireServer(slotItem.Interface.StorageId, slotItem.ID, "setfav");
		end;
		Order=7;
	};
	Interface.DefaultInterface:AddContextOption(favoriteContextOption);
	Interface.PremiumInterface:AddContextOption(favoriteContextOption);
	Interface.ClothingInterface:AddContextOption(favoriteContextOption);

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
				usableItemLib:Use(Table.Item);

			else
				local used = remoteUseStorageItem:InvokeServer(Table.Interface.StorageId, Table.ID);

			end

			useDebounce = false;
		end;
		Order=5;
	};
	Interface.DefaultInterface:AddContextOption(usableContextOption);
	Interface.PremiumInterface:AddContextOption(usableContextOption);
	Interface.ClothingInterface:AddContextOption(usableContextOption);

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
			local setWear = remoteToggleClothing:InvokeServer(Table.Interface.StorageId, Table.ID);
			--local noWearTag = storageItem.Values and storageItem.Values.NoWear;
			toggleWearDebounce = false;
		end;
		Order=7;
	};
	Interface.ClothingInterface:AddContextOption(clothingContextOption);

	--== Shared Context Options;
	
	
	function Interface.Update()
		modStorageInterface.UpdateStorages{
			modData.Storages["Inventory"],
			modData.Storages["Clothing"]
		};
	end

	function Interface.InventoryVisibleChanged(visible)
		if visible then
			Interface.HandleStorage("OpenStorage" ,true);
			Interface.Update();

		else
			Interface.DefaultInterface:ToggleDescriptionFrame(false, nil, 0.3);
			modStorageInterface.CloseOptionMenus();
		end
	end

	function Interface.HotEquip(index)
		if not modCharacter.CharacterProperties.IsAlive then return end;
		if modData.Storages.Inventory == nil then return end;
		
		local slot = Interface.HotbarInterface.Slots[index];
		if slot and slot.Table then
			Interface.HotbarInterface:UseItem(slot.Table);
			
		end
	end
	
	Interface.HotEquipSlots = 5;
	function Interface.UpdateHotbarSize()
		local classPlayer = shared.modPlayers.Get(localPlayer);
		local playerBodyEquipments = classPlayer.Properties and classPlayer.Properties.BodyEquipments;

		Interface.HotEquipSlots = 5+math.max(playerBodyEquipments and playerBodyEquipments.HotEquipSlots or 0, 0);
		
		local updatedSlots = {};
		
		local hotbarSlots = {};
		for a=1, math.clamp(Interface.HotEquipSlots, 1, 10) do
			local new = hotbarFrame:FindFirstChild(a) or templateHotbarSlot:Clone();
			
			local label = new:WaitForChild("label");
			new.Name = a;
			new.LayoutOrder = a;
			new:SetAttribute("Index", a);
			updatedSlots[new] = true;
			
			if modConfigurations.CompactInterface then
				new.Size = UDim2.new(0, 40, 0, 40);
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
		
		Interface.HotbarSlotsNum = #hotbarSlots;
		Interface.HotbarInterface:UpdateSlotFrames(hotbarSlots);
		
		
		-- overlapping glitch here
		Interface.HotbarInterface:Update();
	end
	
	local window = Interface.NewWindow("Inventory", inventoryFrame);
	window:SetConfigKey("DisableInventory");
	window.CompactFullscreen = true;
	
	if modConfigurations.CompactInterface then
		inventoryFrame:WaitForChild("TitleFrame"):WaitForChild("touchCloseButton"):WaitForChild("closeButton").MouseButton1Click:Connect(function()
			Interface:CloseWindow("Inventory");
		end)
		window:SetOpenClosePosition(UDim2.new(0, 0, 0, 0), UDim2.new(0, 0, 1, 0));


	else
		window:SetOpenClosePosition(UDim2.new(0, 10, 0.5, 0), UDim2.new(-1, 0, 0.5, 0));
	end
	
	local classPlayer = shared.modPlayers.Get(localPlayer);
	repeat
		Debugger:Log("Waiting for humanoid...");
		task.wait(1);
	until classPlayer.Humanoid ~= nil;
	local humanoid = classPlayer.Humanoid;
	
	local function updateBodyEquipments()
		local classPlayer = shared.modPlayers.Get(localPlayer);
		local playerBodyEquipments = classPlayer.Properties and classPlayer.Properties.BodyEquipments;
		if playerBodyEquipments == nil then return end;
		
		local label = bodyEquipmentsFrame:WaitForChild("label");
		local beStr = {};

		for k, v in pairs(playerBodyEquipments) do
			
			if k == "Warmth" and playerBodyEquipments.Warmth then
				local warmth = humanoid and humanoid:GetAttribute("Warmth") or 25;
				table.insert(beStr, {SortKey="Warmth"; Text=`<b>Warmth:</b> {warmth} °C`;});

			elseif k == "ActiveProperties" then
				for activePassive, _ in pairs(v) do
					table.insert(beStr, {SortKey="ZZPassive"; Text=`<b>+ Passive</b> {activePassive}`;});
				end

			elseif BodyEquipmentStats[k] then
				table.insert(beStr, BodyEquipmentStats[k](playerBodyEquipments, k));
				
			end
		end

		table.sort(beStr, function(a, b) return a.SortKey < b.SortKey; end)
		for a=1, #beStr do
			beStr[a] = beStr[a].Text;
		end

		label.Text = table.concat(beStr, "\n");
	end


	local function updateWarmth()
		local warmth = humanoid and humanoid:GetAttribute("Warmth") or 25;
		temperatureLabel.Text = warmth.."°C";
	end
	
	window.OnWindowToggle:Connect(function(visible)
		if visible then
			if modData.Storages["Inventory"] == nil or modData.Storages["Clothing"] == nil then
				Interface.HandleStorage("RequestStorage", true);
			end
			
			Interface.InventoryVisibleChanged(window.Visible);
			updateWarmth();
			modStorageInterface.QueueRefreshStorage();
			
		else
			modStorageInterface.CloseInspectFrame()
			clothingToggleMenu.Visible = false;
			Interface.DefaultInterface:StopDragItem();
			if not modConfigurations.CompactInterface or (Interface.modWorkbenchInterface and Interface.modWorkbenchInterface.SelectedSlot == nil) then
				Interface:CloseWindow("Workbench");
				Interface:CloseWindow("WeaponStats");
			end
			Interface:CloseWindow("ExternalStorage");
			Interface:CloseWindow("SupplyStation");
			Interface:CloseWindow("RatShopWindow");
			
			task.spawn(function()
				local rPacket = remoteStorageService:InvokeServer({
					Action="CloseStorage";
					StorageIds={"Inventory"; "Clothing"};
				});
			end)
		end
	end)
	Interface.HotbarInterface.OnItemButton1Click = Interface.HotbarInterface.UseItem;
	Interface.UpdateHotbarSize();
	
	modKeyBindsHandler:SetDefaultKey("KeyWindowInventory", Enum.KeyCode.Tab);
	local quickButton = Interface:NewQuickButton("Inventory", "Inventory", "rbxassetid://2169843985");
	quickButton.LayoutOrder = 2;
	modInterface:ConnectQuickButton(quickButton, "KeyWindowInventory");
	
	task.spawn(function()
		Interface.HandleStorage("RequestStorage", true);

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
		
		Interface.HandleStorage("RequestStorage", true, storageIds);
		
		Interface.DefaultInterface:Update(modData.Storages["Inventory"]);
		Interface.PremiumInterface:Update(modData.Storages["Inventory"]);
		Interface.ClothingInterface:Update(modData.Storages["Clothing"]);
		Interface.UpdateHotbarSize();
	end)
	
	Interface.Garbage:Tag(humanoid:GetAttributeChangedSignal("Warmth"):Connect(updateWarmth));
	Interface.Garbage:Tag(temperatureLabel.MouseMoved:Connect(function()
		temperatureLabel.Text = "Env: "..(workspace:GetAttribute("GlobalTemperature") or 25).."°C"; 
	end));
	Interface.Garbage:Tag(temperatureLabel.MouseLeave:Connect(updateWarmth));
	Interface.Garbage:Tag(bodyEquipmentsFrame:GetPropertyChangedSignal("Visible"):Connect(updateBodyEquipments));
	
	toggleClothingButton.MouseButton1Click:Connect(function()
		Interface:PlayButtonClick();
		clothingToggleMenu.Visible = not clothingToggleMenu.Visible;
		
		if clothingToggleMenu.Visible then
			for _, obj in pairs(clothingToggleMenu:GetChildren()) do
				if obj:IsA("GuiObject") then
					obj:Destroy();
				end
			end
			
			local appearanceFolder = localPlayer:FindFirstChild("Appearance");
			if appearanceFolder then
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
							Interface:PlayButtonClick();
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
			end
		end
	end)
	
	return Interface;
end

return Interface;