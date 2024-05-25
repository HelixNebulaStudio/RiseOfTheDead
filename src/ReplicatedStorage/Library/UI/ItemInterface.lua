local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local ItemInterface = {};
ItemInterface.__index = ItemInterface;

local TextService = game:GetService("TextService");
local TweenService = game:GetService("TweenService");


local localPlayer = game.Players.LocalPlayer;

local modMath = require(game.ReplicatedStorage.Library.Util.Math);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modBranchConfigurations = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modWorkbenchLibrary = require(game.ReplicatedStorage.Library.WorkbenchLibrary);
local modShopLibrary = require(game.ReplicatedStorage.Library.RatShopLibrary);
local modItemUnlockablesLibrary = require(game.ReplicatedStorage.Library.ItemUnlockablesLibrary);
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);
local modToolTweaks = require(game.ReplicatedStorage.Library.ToolTweaks);
local modItemSkinWear = require(game.ReplicatedStorage.Library.ItemSkinWear);
local modDropRateCalculator = require(game.ReplicatedStorage.Library.DropRateCalculator);
local modColorsLibrary = require(game.ReplicatedStorage.Library:WaitForChild("ColorsLibrary"));
local modSkinsLibrary = require(game.ReplicatedStorage.Library:WaitForChild("SkinsLibrary"));

local modRichFormatter = require(game.ReplicatedStorage.Library.UI.RichFormatter);

local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local remoteStorageItemSync = modRemotesManager:Get("StorageItemSync");

local templateItemButton = script:WaitForChild("ItemButton");
local templateFavIcon = script:WaitForChild("FavIcon");
local templateAttachmentIcon = script:WaitForChild("AttachmentIcon");

local templateItemTooltip = script:WaitForChild("ToolTip");

local templateGlowEffect = script:WaitForChild("GlowEffect");
local templateProgressBar = script:WaitForChild("progressBar");


ItemInterface.ItemBarsCache = {};
ItemInterface.ItemValueSync = {};
--== Formatting
local h3O, h3C = modRichFormatter.Headers.H3O, modRichFormatter.Headers.H3C;
ItemInterface.Headers = modRichFormatter.Headers;

local colorBoolText = modRichFormatter.ColorBoolText;
local colorStringText = modRichFormatter.ColorStringText;
local colorNumberText = modRichFormatter.ColorNumberText;

--==
function ItemInterface.ProcessSyncHooks(specifiedId)
	local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
	for id, funcList in pairs(ItemInterface.ItemValueSync) do
		if specifiedId ~= nil and id ~= specifiedId then continue end;

		local storageItem = modData.GetItemById(id);
		if storageItem == nil then return end;
		
		for funcKey, func in pairs(funcList) do
			func(storageItem, funcKey);
		end
	end
end

function ItemInterface.HookValueSync(id, action, func)
	if ItemInterface.ItemValueSync[id] == nil then
		ItemInterface.ItemValueSync[id] = {};
	end

	ItemInterface.ItemValueSync[id][action] = func;
	
	return func;
end

function ItemInterface.init()
	table.clear(ItemInterface.ItemBarsCache);
	table.clear(ItemInterface.ItemValueSync);
	
end

function ItemInterface:Destroy()
	if self.ImageButton then
		Debugger.Expire(self.ImageButton, 0);
		self.ImageButton = nil;
	end
	if self.Frame then
		Debugger.Expire(self.Frame, 0);
		self.Frame = nil;
	end
	if self.RadialObject then
		Debugger.Expire(self.RadialObject.label, 0);
		self.RadialObject = nil;
	end
end

local glowTween = TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1);
function ItemInterface.newGlowEffect()
	local new = templateGlowEffect:Clone();
	
	TweenService:Create(new:WaitForChild("Rays"), glowTween, {Rotation=359}):Play();
	
	return new;
end

function ItemInterface.newProgressBar()
	local new = templateProgressBar:Clone();
	return new;
end

function ItemInterface.newItemButton(itemId, includeAspectRatio)
	itemId = itemId or "nil";
	
	local meta = {};
	meta.__index = meta;
	
	function meta:Update(storageItemData)
		if self.CustomUpdate then
			self:CustomUpdate(storageItemData);
		else
			self:DefaultUpdateItemButton(storageItemData);
		end
	end
	
	local self = {
		ItemId = itemId;
		ImageButton = templateItemButton:Clone();
	};
	
	if itemId then
		self.ImageButton.Name = itemId;
	end
	
	if includeAspectRatio then
		local new = Instance.new("UIAspectRatioConstraint");
		new.Parent = self.ImageButton;
	end
	
	setmetatable(self, meta);
	setmetatable(meta, ItemInterface);
	return self;
end

function ItemInterface.newItemTooltip()
	local meta = {};
	meta.__index = meta;
	
	function meta:Update(itemId, storageItemData)
		if self.CustomUpdate then
			self:CustomUpdate(itemId, storageItemData);
			
		else
			self:DefaultUpdateItemTooltip(itemId, storageItemData);
			
		end
	end
	
	function meta:SetZIndex(index)
		index = index or 3;
		
		self.Frame.ZIndex = index;
		for _, obj in pairs(self.Frame:GetDescendants()) do
			if obj:IsA("GuiObject") then
				obj.ZIndex = index;
			end
		end
	end
	
	function meta:SetPosition(guiObject)
		local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
		local modInterface = modData:GetInterfaceModule();

		local padding = 5;

		local targetPos = guiObject.AbsolutePosition;
		local targetSize = guiObject.AbsoluteSize;

		local vpSize = workspace.CurrentCamera.ViewportSize;

		if targetPos.X <= vpSize.X/2 then
			targetPos = targetPos + Vector2.new(targetSize.X, 0);
		end
		modInterface.SetPositionWithPadding(self.Frame, targetPos, padding);
	end
	
	function meta:BindHoverOver(guiObject, onToggle)
		guiObject.MouseEnter:Connect(function()
			self.Frame.Visible = true;
			if onToggle then onToggle() end;
		end)
		
		guiObject.MouseMoved:Connect(function()
			if not self.Frame.Visible then
				self.Frame.Visible = true;
				if onToggle then onToggle() end;
			end
		end)
		
		guiObject.MouseLeave:Connect(function()
			self.Frame.Visible = false;
			if onToggle then onToggle() end;
		end)
	end
	
	local self = {
		Frame = templateItemTooltip:Clone();
		ToolTipType = "default";
	};
	
	self.Frame.InputBegan:Connect(function(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self.Frame.Visible = false;
		end
	end)
	
	setmetatable(self, meta);
	setmetatable(meta, ItemInterface);
	return self;
end

function ItemInterface:DefaultUpdateItemButton(storageItemData)
	local playerGui = localPlayer:WaitForChild("PlayerGui");
	local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	local serverUnixTime = modSyncTime.GetTime();
	
	if storageItemData and self.ItemId ~= storageItemData.ItemId then
		self.ItemId = storageItemData.ItemId;
		self.ItemLib = nil;
	end
	
	local itemId = self.ItemId;
		
	if self.ItemLib == nil then self.ItemLib = modItemsLibrary:Find(itemId); end;
	if self.ItemLib == nil then return end;
	
	local itemIcon = self.ItemLib.Icon or "rbxasset://textures/ui/GuiImagePlaceholder.png";

	if self.ItemLib.OverlayIcons and #self.ItemLib.OverlayIcons > 0 then
		local overlayFrame = self.ImageButton.Overlays;
		overlayFrame.ZIndex = self.ImageButton.ZIndex;

		for a=1, #self.ItemLib.OverlayIcons do
			local overlayData = self.ItemLib.OverlayIcons[a];

			local newImage = overlayFrame:FindFirstChild("Overlay".. a);
			newImage = newImage or Instance.new("ImageLabel");
			newImage.Name = "Overlay"..a;
			newImage.Image = overlayData.Icon;
			newImage.BackgroundTransparency = 1;
			newImage.Size = UDim2.new(1, 0, 1, 0);
			newImage.ZIndex = overlayFrame.ZIndex;
			newImage.Parent = overlayFrame;
		end
	end

	local itemButtonColor = modItemsLibrary.TierColors[self.ItemLib.Tier];
	
	local typeIconLabel = self.ImageButton:WaitForChild("TypeIcon");
	typeIconLabel.Image = self.ItemLib.TypeIcon or self.ItemLib.Type and modItemsLibrary.TypeIcons[self.ItemLib.Type] or "";
	
	if self.HideTypeIcon then
		typeIconLabel.Image = "";
	end
	
	if storageItemData then 
		local storageItemID = storageItemData.ID;
		local itemValues = storageItemData.Values or {};
		
		if itemValues.Tier then
			itemButtonColor = modItemsLibrary.TierColors[itemValues.Tier];
		end
		
		local quantityLabel = self.ImageButton:WaitForChild("QuantityLabel");

		if typeof(storageItemData.Quantity) == "table" and storageItemData.Quantity.Min and storageItemData.Quantity.Max then
			quantityLabel.Visible = true;
			quantityLabel.Text = storageItemData.Quantity.Min.."~"..storageItemData.Quantity.Max;
			quantityLabel.TextColor3 = Color3.fromRGB(255, 255, 255);
			
		elseif storageItemData.Quantity > 1 then
			quantityLabel.Visible = true;
			quantityLabel.Text = "x"..storageItemData.Quantity;
			quantityLabel.TextColor3 = Color3.fromRGB(255, 255, 255);

		elseif itemValues.Power then
			quantityLabel.Visible = true;
			quantityLabel.Text = string.format("%.1f", itemValues.Power).."%";
			quantityLabel.TextColor3 = Color3.fromRGB(255, 255, 255);

		elseif itemValues.Fuel then
			quantityLabel.Visible = true;
			quantityLabel.Text = itemValues.Fuel.."%";
			quantityLabel.TextColor3 = Color3.fromRGB(255, 255, 255);

		elseif itemValues.L then
			quantityLabel.Visible = true;
			quantityLabel.Text = itemValues.L;
			quantityLabel.TextColor3 = Color3.fromRGB(255, 227, 188);

		elseif itemValues.GoldPrice then
			quantityLabel.Visible = true;
			quantityLabel.Text = itemValues.GoldPrice.."G";
			quantityLabel.TextColor3 = Color3.fromRGB(255, 205, 79);
			
		elseif itemValues.State then
			quantityLabel.Visible = true;
			quantityLabel.Text = itemValues.State;
			quantityLabel.TextColor3 = Color3.fromRGB(255, 227, 188);
			
		elseif itemValues.Health and itemValues.MaxHealth then
			quantityLabel.Visible = true;
			quantityLabel.Text = string.format("%.0f", (itemValues.Health/itemValues.MaxHealth)*100) .."%";
			quantityLabel.TextColor3 = Color3.fromRGB(255, 82, 82);
			
		else
			quantityLabel.Visible = false;
			quantityLabel.Text = "";

		end

		if itemValues.ActiveSkin then
			local permType = nil;
			local permLib = modItemUnlockablesLibrary:Find(itemValues.ActiveSkin);
			if permLib then
				permType = "Clothing";
				
				local unlockItemLib = modItemsLibrary:Find(itemValues.ActiveSkin);
				itemIcon = permLib.Icon or unlockItemLib.Icon or itemIcon;

			else
				permLib = modSkinsLibrary.Get(itemValues.ActiveSkin);
				if permLib then
					permType = "Tool";
				end
			end

			if permType then
			end;
		end

		if storageItemData.Fav and self.HideFavIcon ~= true then
			local iconLabel = self.ImageButton:FindFirstChild("FavIcon") or templateFavIcon:Clone();
			iconLabel.Parent = self.ImageButton;
			iconLabel.Visible = true;

		elseif self.ImageButton:FindFirstChild("FavIcon") then
			Debugger.Expire(self.ImageButton.FavIcon, 0);

		end
		
		if itemValues.Color then
			itemButtonColor = Color3.fromHex(itemValues.Color);
		end

		if storageItemID then -- Item is tied to storageItem and not proxy;
			local itemBar = self.ImageButton:WaitForChild("itemBar");
			
			if self.Itembar == true then
				local function setBar(a)
					itemBar.Visible = true;
					itemBar.ImageColor3 = modBranchConfigurations.BranchColor;
					itemBar.Size = UDim2.new(math.clamp(a, 0, 1), 0, 0, 3);
				end

				if itemValues.Expire and itemValues.ExpireLength then
					if ItemInterface.ItemBarsCache[storageItemID] == nil then
						ItemInterface.ItemBarsCache[storageItemID] = true;
						spawn(function()
							while ItemInterface.ItemBarsCache[storageItemID] do
								wait(1);
								local timeLeft = itemValues.Expire - modSyncTime.GetTime();
								local barFill = math.clamp(timeLeft/itemValues.ExpireLength, 0, 1);
								setBar(barFill);
								if barFill <= 0 then
									remoteStorageItemSync:FireServer("update", storageItemID);
								end

								if not self.ImageButton:IsDescendantOf(playerGui) then
									ItemInterface.ItemBarsCache[storageItemID] = nil;
								end
							end	
						end);
					end
				else
					local toolInfo, toolType = modData:GetItemClass(storageItemID, true);
					if toolInfo then
						if toolType == "Weapon" and toolInfo.Configurations then
							local barFill = itemValues.A == nil and 1 or itemValues.A/toolInfo.Configurations.AmmoLimit;
							setBar(barFill);
						end
					end

					if itemValues.Power then
						local barFill = itemValues.Power/100;
						setBar(barFill);

					elseif itemValues.Fuel then
						local barFill = itemValues.Fuel/100;
						setBar(barFill);

					elseif itemValues.Cap then
						local barFill = itemValues.Cap/itemValues.MaxCap;
						setBar(barFill);

					elseif itemValues.Uses then
						local barFill = itemValues.Uses/3;
						setBar(barFill);
						
					elseif itemValues.MaxHealth then
						local health =  itemValues.Health or itemValues.MaxHealth;
						local barFill = health/itemValues.MaxHealth;
						setBar(barFill);
						
						if health <= 0 then
							itemButtonColor = Color3.fromRGB(140, 70, 70);
						end
					end
				end

			else
				itemBar.Visible = false;
			end

			local a = 1;
			local activatableIconLabel = self.ImageButton:FindFirstChild("ActivatableIcon");
			if activatableIconLabel then
				activatableIconLabel.Image = "";
			end
			if modData.Storages[storageItemID] and self.HideAttachmentIcons ~= true then
				for id, item in pairs(modData.Storages[storageItemID].Container) do
					local modLib = modModsLibrary.Get(item.ItemId);

					if modLib and modLib.ActivationDuration then
						local iconLabel = self.ImageButton:FindFirstChild("ActivatableIcon") or templateAttachmentIcon:Clone();
						iconLabel.Name = "ActivatableIcon";
						iconLabel.Parent = self.ImageButton;

						local itemLib = modItemsLibrary:Find(item.ItemId);
						iconLabel.Image = itemLib.Icon;
						iconLabel.AnchorPoint = Vector2.new(0.5, 0.5);
						--iconLabel.AnchorPoint = Vector2.new(0, 0);
						--iconLabel.Position = UDim2.new(0, 0, 0, 4);
						--iconLabel.Size = UDim2.new(0, 20, 0, 20);
						--iconLabel.ImageColor3 = modLib.Color;

						if modLib.ActivationDuration then
							local idleSize, idlePos = UDim2.new(0, 20, 0, 20), UDim2.new(0, 10, 0, 12);
							local activeSize, activePos = UDim2.new(0, 30, 0, 30), UDim2.new(0, 30, 0, 30);

							local fullColor = Color3.fromRGB(255, 255, 255);
							local halfColor = Color3.fromRGB(100, 100, 100);
							local cooldownColor = Color3.fromRGB(80, 80, 80);
							local emptyColor = Color3.fromRGB(25, 25, 25);

							local barGradient = iconLabel:FindFirstChild("Ratio") or script.UIGradient:Clone();
							barGradient.Name = "Ratio";
							barGradient.Color = ColorSequence.new(fullColor);
							barGradient.Parent = iconLabel;

							ItemInterface.HookValueSync(id, "UpdateActivatableIcon", function(storageItem, funcKey)
								if funcKey and funcKey ~= "UpdateActivatableIcon" then return end;

								local timelapsed = modSyncTime.GetTime() - (storageItem.Values.AT or 0);

								iconLabel.ImageColor3 = modLib.Color;

								local newState = -1;
								if timelapsed > modLib.ActivationDuration+modLib.CooldownDuration then -- Idle
									barGradient.Color = ColorSequence.new(Color3.fromRGB(255,255,255));
									newState = 0;

								elseif timelapsed > modLib.ActivationDuration then -- Cooldown
									local cooldownRatio = math.clamp(1-((timelapsed-modLib.ActivationDuration)/modLib.CooldownDuration), 0, 0.999);
									cooldownRatio = modMath.MapNum(cooldownRatio, 0, 0.999, 0.1, 0.9);

									barGradient.Color = ColorSequence.new{
										ColorSequenceKeypoint.new(0, emptyColor);
										ColorSequenceKeypoint.new(cooldownRatio, emptyColor);
										ColorSequenceKeypoint.new(cooldownRatio+0.001, cooldownColor);
										ColorSequenceKeypoint.new(1, cooldownColor);
									}
									newState = 2;

								elseif timelapsed >= 0 then -- Active
									local activeRatio = math.clamp(timelapsed/modLib.ActivationDuration, 0, 0.999);
									activeRatio = modMath.MapNum(activeRatio, 0, 0.999, 0.1, 0.9);

									barGradient.Color = ColorSequence.new{
										ColorSequenceKeypoint.new(0, halfColor);
										ColorSequenceKeypoint.new(activeRatio, halfColor);
										ColorSequenceKeypoint.new(activeRatio+0.001, fullColor);
										ColorSequenceKeypoint.new(1, fullColor);
									}
									newState = 1;

								end

								if iconLabel:GetAttribute("State") ~= newState then
									iconLabel:SetAttribute("State", newState);

									if newState == 0 then -- Idle
										if localPlayer.PlayerGui:IsAncestorOf(iconLabel) then
											iconLabel:TweenSizeAndPosition(idleSize, idlePos, Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, 0.2, true);

										else
											iconLabel.Size = idleSize;
											iconLabel.Position = idlePos;

										end

									elseif newState == 1 then -- Active
										if localPlayer.PlayerGui:IsAncestorOf(iconLabel) then
											iconLabel:TweenSizeAndPosition(activeSize, activePos, Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, 0.2, true);

										else
											iconLabel.Size = activeSize;
											iconLabel.Position = activePos;

										end

									elseif newState == 2 then -- Cooldown;
										if localPlayer.PlayerGui:IsAncestorOf(iconLabel) then
											iconLabel:TweenSizeAndPosition(idleSize, activePos, Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, 0.2, true);

										else
											iconLabel.Size = activeSize;
											iconLabel.Position = activePos;

										end

									end
								end

							end)(item);
						end

					else
						if a <= 4 then
							local iconLabel = self.ImageButton:FindFirstChild("AttachmentIcon"..a) or templateAttachmentIcon:Clone();
							iconLabel.Name = "AttachmentIcon"..a;

							local itemLib = modItemsLibrary:Find(item.ItemId);
							if itemLib then
								iconLabel.Image = itemLib.Icon;
								iconLabel.ImageColor3 = modItemsLibrary.TierColors[itemLib.Tier];
							else
								Debugger:Log("Missing item lib for attachment icon (",item.ItemId,")");
							end
							iconLabel.Position = UDim2.new(0, 2+(14*(a-1)), 1, -2);
							iconLabel.Parent = self.ImageButton;
							a = a +1;
						end;

					end
				end
			end
			for b=a, 4 do
				local iconLabel = self.ImageButton:FindFirstChild("AttachmentIcon"..b);
				if iconLabel then iconLabel.Image = ""; end
			end
			if a > 1 then
				typeIconLabel.Image = "";
			end
		end
	end
	
	if self.DimOut ~= nil and self.DimOut ~= false then
		local dimVal = tonumber(self.DimOut) or 0.235294;
		local h, s, _v = itemButtonColor:ToHSV();
		local c = Color3.fromHSV(h, s, dimVal);

		self.ImageButton.ImageColor3 = c;
		for _, obj in pairs(self.ImageButton:GetDescendants()) do
			if obj:GetAttribute("DimOutIgnore") == true then continue end
			if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
				if obj:GetAttribute("NonDimColor") == nil then
					obj:SetAttribute("NonDimColor", obj.ImageColor3);
				end
				obj.ImageColor3 = c;

			end;
		end
		
	else
		self.ImageButton.ImageColor3 = itemButtonColor;
		for _, obj in pairs(self.ImageButton:GetDescendants()) do
			if obj:GetAttribute("DimOutIgnore") == true then continue end
			if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
				if obj:GetAttribute("NonDimColor") then
					obj.ImageColor3 = obj:GetAttribute("NonDimColor");
				end
			end;
		end
		
	end
	
	self.ImageButton.Image = itemIcon;
end

function ItemInterface:DefaultUpdateItemTooltip(itemId, storageItemData)
	local itemLib = modItemsLibrary:Find(itemId);
	if itemLib == nil then return end;
	
	local serverUnixTime = modSyncTime.GetTime();
	local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
	local defaultFrame = self.Frame:WaitForChild("default");
	local nameTag = self.Frame:WaitForChild("NameTag");
	local itemIcon = defaultFrame:WaitForChild("Icon");
	local quantityLabel = defaultFrame:WaitForChild("QuantityLabel");
	local typeIcon = defaultFrame:WaitForChild("TypeIcon");
	local descLabel = defaultFrame:WaitForChild("Description");
	local modUpgradesFrame = defaultFrame:WaitForChild("modUpgrades");
	
	local itemName = itemLib.Name;
	local itemLibIcon = itemLib.Icon;
	local itemDesc = "";
	local itemColor = modItemsLibrary.TierColors[itemLib.Tier];
	
	local frameHeight = 0;
	
	defaultFrame.Visible = true;
	if modWorkbenchLibrary.ItemUpgrades[itemId] then
		itemDesc = itemDesc..h3O.."Type: "..h3C..table.concat(modWorkbenchLibrary.ItemUpgrades[itemId].Type, ", ");
	else
		itemDesc = itemDesc..h3O.."Type: "..h3C..itemLib.Type
	end
	
	itemDesc = itemDesc..h3O.."\nDescription:"..h3C.."\n"..(itemLib.Description or "Missing description").."\n";

	local modBlueprintLibrary = require(game.ReplicatedStorage.Library.BlueprintLibrary);
	local bpLib = modBlueprintLibrary.Get(itemId);
	local sellingPrice = modShopLibrary.SellPrice[itemId]
				or bpLib and (bpLib.SellPrice or (bpLib.Tier and modShopLibrary.SellPrice["Tier"..bpLib.Tier])) or nil;
	if sellingPrice then
		itemDesc = itemDesc..h3O.."\nSell To Shop: "..h3C..colorNumberText("$"..sellingPrice);
	end
	
	if bpLib then
		itemDesc = itemDesc..h3O.."\nUnlockable: "..h3C..colorBoolText(bpLib.CanUnlock == true);
		if itemLib.RequireDesc then
			itemDesc = itemDesc..h3O.."\nRequires: "..h3C..itemLib.RequireDesc;
		end
	end
	
	if itemLib.Equippable == true then
		itemDesc = itemDesc..h3O.."\nEquipable: "..h3C..colorBoolText(itemLib.Equippable);
		
	end
	if itemLib.Type == "Clothing" then
		itemDesc = itemDesc..h3O.."\nWearable: "..h3C..colorBoolText(true);
		
	end

	if itemLib.Recyclable == true then
		itemDesc = itemDesc..h3O.."\nRecyclable: "..h3C..colorBoolText(itemLib.Recyclable);
		
	end
	
	
	if storageItemData and storageItemData.NonTradeable then
		if storageItemData.NonTradeable == 1  then
			itemDesc = itemDesc..h3O.."\nTradable: "..h3C.."Trade Restricted (Roblox Policy)";
		else
			itemDesc = itemDesc..h3O.."\nTradable: "..h3C.."Trade Restricted (Limited)";
		end
		
	elseif itemLib.Tradable == modItemsLibrary.Tradable.Nontradable then
		itemDesc = itemDesc..h3O.."\nTradable: "..h3C.. colorStringText(itemLib.Tradable);
		
	else
		itemDesc = itemDesc..h3O.."\nTrading: "..h3C;
		
		local totalTax = 0;
		local taxStr = {};
		if itemLib.TradingTax and itemLib.TradingTax > 0 then
			totalTax = totalTax + itemLib.TradingTax;
			table.insert(taxStr, "(Base Tax:"..itemLib.TradingTax..")")
		end
		if itemLib.Tradable == modItemsLibrary.Tradable.PremiumOnly then -- and modData.IsPremium == false
			local npTax = (itemLib.NonPremiumTax or 50);
			totalTax = totalTax + npTax;
			table.insert(taxStr, "(Non-Premium Tax:"..npTax..")")
		end
		if totalTax > 0 then
			itemDesc = itemDesc.. modRichFormatter.ColorPremiumText(table.concat(taxStr, "+") .." = <b>".. totalTax .."G</b>");
		else
			itemDesc = itemDesc.. colorStringText("Tax Free");
		end
	end
	
	if itemId == "watch" then
		itemDesc = itemDesc..h3O.."\nTime:"..h3C.." "..colorNumberText(game.Lighting.TimeOfDay);
	end
	
	if modItemsLibrary:HasTag(itemId, "Skin Perm") then
		local skinLib = modItemUnlockablesLibrary:Find(itemId);
		if skinLib then
			local skinNames = {};
			table.insert(skinNames, `{skinLib.Name} {itemLib.TargetName}`);

			if skinLib.BundleList then
				for k, bundleSkinLib in pairs(skinLib.BundleList) do
					table.insert(skinNames, `{bundleSkinLib.Name} {itemLib.TargetName}`);
				end
			end

			itemDesc = itemDesc..h3O.."\nUnlocks:"..h3C..colorStringText("\n    - "..table.concat(skinNames, "\n    - "));
		else
			skinLib = modSkinsLibrary.GetByName(itemLib.SkinPerm);

			if skinLib then
				itemDesc = itemDesc..h3O.."\nUnlocks: "..h3C..colorStringText(`{skinLib.Name} {itemLib.TargetName}`);
			end
		end
	end
	
	if storageItemData then
		local isCustomName = storageItemData.Name ~= itemLib.Name;
		if isCustomName then
			itemName = storageItemData.DisplayName or itemName;
		end
		
		local itemValues = storageItemData.Values or {};
		
		if itemValues.Color then
			itemColor = Color3.fromHex(itemValues.Color);
		end

		if isCustomName then
			itemDesc = h3O.."Name:"..h3C.." ".. colorStringText(itemLib.Name) .."\n"..itemDesc;
		end
		if itemValues.PickUpItemId then
			itemName = "Place "..itemValues.PickUpItemId or "unknown";
		end
		

		if storageItemData.Vanity then
			local vanityItem = modData.GetItemById(storageItemData.Vanity);
			if vanityItem then
				itemDesc = itemDesc..h3O.."\nVanity: "..h3C.. colorStringText(vanityItem.Name);
			end
		end
		
		if itemValues.ActiveSkin then
			local permType = nil;
			local permLib = modItemUnlockablesLibrary:Find(itemValues.ActiveSkin);
			if permLib then
				permType = "Clothing";

			else
				permLib = modSkinsLibrary.Get(itemValues.ActiveSkin);
				if permLib then
					permType = "Tool";
				end
			end
			
			if permType ~= nil then
				itemName = string.gsub(itemName, permLib.Name, "");
				itemName = '<font color="rgb(136, 105, 191)">'..permLib.Name..'</font> '..itemName;
				itemDesc = itemDesc..h3O.."\nSkin-Permanent: "..h3C.. colorStringText(permLib.Name);
			end
		end

		if itemValues.Skins then
			for a=1, #itemValues.Skins do
				itemValues.Skins[a] = tostring(itemValues.Skins[a]);
			end
			table.sort(itemValues.Skins);

			local skinNames = {};
			for a=1, #itemValues.Skins do
				local skinId = itemValues.Skins[a];
				local skinName = nil;

				local skinLib = modItemUnlockablesLibrary:Find(skinId);
				if skinLib then
					skinName = skinLib.Name;
					if skinLib.BundleList then
						for k, bundleSkinLib in pairs(skinLib.BundleList) do
							skinName = skinName..` & {bundleSkinLib.Name}`;
						end
					end

				else
					skinLib = modSkinsLibrary.Get(skinId);
					if skinLib then
						skinName = skinLib.Name;
					end
					
				end

				if skinName then
					table.insert(skinNames, `\n    - {skinName}`);
				end
			end

			itemDesc = itemDesc..h3O.."\nSkins:"..h3C.. modRichFormatter.RichFontSize(colorStringText(table.concat(skinNames)), 10);
		end
		
		if itemValues.Tweak and itemValues.TweakValues then
			local tweakValues = itemValues.TweakValues;

			local random = Random.new(itemValues.Tweak);
			
			local titlesList = modToolTweaks.TierTitles[#tweakValues+1];
			local title = titlesList[random:NextInteger(1, #titlesList)];
			
			if title then
				itemName = '<font face="ArialBold" color="rgb(255,230,51)">'.. title ..'</font> '..itemName;
				itemDesc = itemDesc..h3O.."\nTrait: "..h3C.. title;
			end
		end
		
		if itemValues.SkinWearId then
			local skinWearLib = modItemSkinWear.LoadFloat(itemId, itemValues.SkinWearId);

			if skinWearLib.Title then
				local titleString = modItemSkinWear.Titles[skinWearLib.Title];
				
				itemDesc = itemDesc..h3O.."\nCondition: "..h3C.. colorStringText(titleString) .." (".. colorNumberText(math.round(skinWearLib.Float*10000)/10000) ..")";

				if itemValues.TimesPolished then
					itemDesc = itemDesc.." Polished: "..colorNumberText(itemValues.TimesPolished);
				end
			end
		end

		if itemValues.Power then
			itemDesc = itemDesc..h3O.."\nBattery: "..h3C.. colorNumberText(string.format("%.2f", itemValues.Power).."%");
		end
		if itemValues.Fuel then
			itemDesc = itemDesc..h3O.."\nFuel: "..h3C.. colorNumberText(itemValues.Fuel.."%");
		end
		if itemValues.Uses then
			itemDesc = itemDesc..h3O.."\nUses: "..h3C.. colorNumberText(itemValues.Uses).." left";
		end
		if itemValues.Unlocked then
			local unlockedList = {};
			for k, v in pairs(itemValues.Unlocked) do
				if v ~= nil and v ~= false then
					table.insert(unlockedList, colorStringText(k));
				end
			end
			itemDesc = itemDesc..h3O.."\nUnlocked: "..h3C.. table.concat(unlockedList, ", ");
		end
		
		if itemValues.L then
			itemDesc = itemDesc..h3O.."\nLevel: "..h3C.. colorNumberText(itemValues.L);
		end
		if itemValues.CardGameStats then
			itemDesc = itemDesc..h3O.."\nStats: "..h3C.. colorNumberText(itemValues.CardGameStats);
		end
		if itemValues.WantedNpc then
			local modNpcProfileLibrary = require(game.ReplicatedStorage.BaseLibrary.NpcProfileLibrary);
			local npcLib = modNpcProfileLibrary:Find(itemValues.WantedNpc);
			itemName = '<font face="ArialBold" color="#'.. modNpcProfileLibrary.ClassColors[npcLib.Class]:ToHex() ..'">'.. itemValues.WantedNpc ..'</font> Wanted Poster';
			itemDesc = itemDesc..h3O.."\nWanted: "..h3C.. itemValues.WantedNpc;
		end
		if itemValues.Seed then
			itemName = itemName.." #"..itemValues.Seed;
			itemDesc = itemDesc..h3O.."\nSeed: "..h3C.. colorNumberText(itemValues.Seed);
		end
		
		if itemValues.Color then
			itemDesc = itemDesc..h3O.."\nColor: "..h3C..'<font color="#'..itemValues.Color..'"> #'..itemValues.Color..'</font>';
		end

		if itemValues.DescExtend then
			itemDesc = itemDesc.. itemValues.DescExtend;
		end
		
		if itemId == "portableautoturret" then
			local patWeaponStorageItem = modData.FindIndexFromStorage(itemId, 1);
			local patWeaponValues = patWeaponStorageItem and patWeaponStorageItem.Values or {};
			if patWeaponStorageItem then
				itemDesc = itemDesc..h3O.."\nWeapon: "..h3C.. colorStringText(patWeaponStorageItem.ItemId);
				itemDesc = itemDesc..h3O.."\nAmmo: "..h3C.. colorNumberText((patWeaponValues.A or "Full").."/"..(patWeaponValues.MA or "Full"));
				
			else
				itemDesc = itemDesc..h3O.."\nWeapon: "..h3C.. colorStringText("none");

			end
			
			local patBatteryStorageItem = modData.FindIndexFromStorage(itemId, 2);
			local patBatteryValues = patBatteryStorageItem and patBatteryStorageItem.Values or {};
			if patBatteryStorageItem then
				itemDesc = itemDesc..h3O.."\nBattery: "..h3C.. colorNumberText(patBatteryValues.Power and string.format("%.2f", patBatteryValues.Power).."%" or "0%");
			else
				itemDesc = itemDesc..h3O.."\nBattery: "..h3C.. colorStringText("none");
			end
			
			local turretConfig = itemLib.GetTurretConfigs();
			local configToStr = {};
			if itemValues.Config then
				for k, v in pairs(itemValues.Config) do
					local configInfo = turretConfig[k];
					if configInfo == nil or configInfo.HideTooltip then continue end;
					if k == "Hitlist" then continue end;
					
					local value = colorStringText(configInfo.Options[v]);
					
					table.insert(configToStr, "\n    - <b>"..k..":</b> "..value);
				end
			end
			itemDesc = itemDesc..h3O.."\nConfigurations: "..h3C.. ((#configToStr > 0) and table.concat(configToStr) or colorStringText("default"));
		end
		
		if modData.Storages[storageItemData.ID] then
			if itemLib.Type == modItemsLibrary.Types.Tool or itemLib.Type == modItemsLibrary.Types.Clothing then
				local first = true;
				
				for id, item in pairs(modData.Storages[storageItemData.ID].Container) do
					if first then itemDesc = itemDesc..h3O.."\nAttached: "..h3C end;
					local attachedItemLib = modItemsLibrary:Find(item.ItemId);
					if attachedItemLib then
						itemDesc = itemDesc..(not first and ", " or "")..colorStringText(attachedItemLib.Name);
						first = false;
					else
						Debugger:Log("Missing item lib for description (",item.ItemId,")");
					end
				end
			end
		end
		
		local itemClass, classType = modData:GetItemClass(storageItemData.ID);
		
		if itemClass then

			itemDesc = itemDesc.."\n";
			
			if itemClass.Warmth then
				itemDesc = itemDesc..h3O.."\nWarmth: "..h3C.. colorNumberText(itemClass.Warmth.."°C");
			end
			if itemClass.FlinchProtection then
				itemDesc = itemDesc..h3O.."\nFlinch Protection: "..h3C.. colorNumberText(math.ceil(itemClass.FlinchProtection*100).."%");
			end
			
			if itemClass.Slaughterfest then
				itemDesc = itemDesc..h3O.."\nSlaughterfest: "..h3C..colorStringText("Wearing this into slaughterfest will yield 10% more candies when killing players!");
			end
			
			if classType == "Weapon" then
				itemDesc = itemDesc..h3O.."\nAmmo: "..h3C.. colorNumberText((itemValues.A or "Full").."/"..(itemValues.MA or "Full"));
			end


			itemDesc = itemDesc.."\n";
		end
		
		if itemLib.Type == modItemsLibrary.Types.Mod then
			local modLib = modModsLibrary.Get(itemId);
			
			for _, obj in pairs(modUpgradesFrame:GetChildren()) do
				if obj:IsA("GuiObject") then
					obj:Destroy();
				end
			end
			
			for a=1, #modLib.Upgrades do
				local upgradeInfo = modLib.Upgrades[a];
				local upgradeLvl = (itemValues[upgradeInfo.DataTag] or 0);
				local maxLvl = modLib.Upgrades[a].MaxLevel;
				
				local upgradeValue;
				if upgradeInfo.Scaling == modModsLibrary.ScalingStyle.NaturalCurve then
					upgradeValue = modModsLibrary.NaturalInterpolate(upgradeInfo.BaseValue, upgradeInfo.MaxValue, upgradeLvl, maxLvl, upgradeInfo.Rate);
				elseif upgradeInfo.Scaling == modModsLibrary.ScalingStyle.Linear then
					upgradeValue = modModsLibrary.Linear(upgradeInfo.BaseValue, upgradeInfo.MaxValue, upgradeLvl, maxLvl);
				end
				if upgradeInfo.ValueType == "Normal" then
					itemDesc = itemDesc:gsub("$"..upgradeInfo.Name, math.floor(upgradeValue));
				else
					itemDesc = itemDesc:gsub("$"..upgradeInfo.Name, math.floor(upgradeValue*10000)/100);
				end
				
				
				local upgradesLayout = modUpgradesFrame.UIListLayout;
				local newUpgradeLabel = upgradesLayout.upgradeLabel:Clone();
				newUpgradeLabel.LayoutOrder = a*2;
				newUpgradeLabel.Text = upgradeInfo.Name..(" ($lvl/$maxlvl)"):gsub("$lvl", tostring(math.min(upgradeLvl,maxLvl))):gsub("$maxlvl", maxLvl);
				newUpgradeLabel.Parent = modUpgradesFrame;
				local newLevelList = upgradesLayout.UpgradeLevelList:Clone();
				newLevelList.LayoutOrder = a*2+1;
				for a=1, upgradeLvl do
					local newLevel = upgradesLayout.LevelSlot:Clone();
					newLevel.Parent = newLevelList;
				end
				if upgradeLvl < maxLvl then
					local newLevel = upgradesLayout.EmptyLevelSlot:Clone();
					newLevel.Parent = newLevelList;
				end
				newLevelList.Parent = modUpgradesFrame;
				
			end
			frameHeight = frameHeight + modUpgradesFrame.UIListLayout.AbsoluteContentSize.Y;
			modUpgradesFrame.Visible = true;
		end
		
		local appearanceData = {};

		if itemValues.Colors then
			local names = {};
			for partName, colorId in pairs(itemValues.Colors) do
				local lib = modColorsLibrary.Get(colorId);
				if lib then
					local packName = colorStringText(lib.Pack..":"..lib.Name);
					if table.find(names, packName) == nil then
						table.insert(names, packName);
					end
				end
			end
			table.insert(appearanceData, "      Colors: "..table.concat(names, ", "));
		end
		if itemValues.Textures then
			local names = {};
			
			for partName, textureId in pairs(itemValues.Textures) do
				if itemValues.ActiveSkin and textureId == itemValues.ActiveSkin then continue end;
				local lib = modSkinsLibrary.Get(textureId);
				if lib then
					local packName = colorStringText(lib.Pack..":"..lib.Name);
					if table.find(names, packName) == nil then
						table.insert(names, packName);
					end
				end
			end
			
			if #names > 0 then
				table.insert(appearanceData, "      Textures: "..table.concat(names, ", "));
				
			end
		end
		if #appearanceData > 0 then
			itemDesc = itemDesc..h3O.."\nAppearance: "..h3C.."\n".. table.concat(appearanceData, "\n");
		end

		
		if itemValues.Expire and itemValues.ExpireLength then
			local timeLeft = itemValues.Expire - serverUnixTime;
			itemDesc = itemDesc..h3O.."\nExpires: "..h3C.. modSyncTime.ToString(timeLeft);
		end
	end;
	
	if itemLib.Type ~= modItemsLibrary.Types.Mod then
		if modUpgradesFrame then
			for _, obj in pairs(modUpgradesFrame:GetChildren()) do
				if obj:IsA("GuiObject") then
					obj:Destroy();
				end
			end
			modUpgradesFrame.Visible = false;
		end
	end

	local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);
	local rewardsList = modRewardsLibrary:Find(itemId);
	if rewardsList and rewardsList.Rewards and rewardsList.Hidden ~= true then
		local str = "";

		local groups = modDropRateCalculator.Calculate(rewardsList, {HardMode=true});
		
		local multiSlot = #groups > 1;
		for a=1, #groups do
			
			local chance = 0;
			
			for b=1, #groups[a] do
				local rewardInfo = groups[a][b];
				chance = chance + rewardInfo.Chance;
				
				if rewardInfo.ItemId or rewardInfo.Type then
					local lib = modItemsLibrary:Find(rewardInfo.ItemId or rewardInfo.Type);
					if lib then
						local oddsProb = rewardInfo.Chance/groups[a].TotalChance;
							
						str = str..(multiSlot and "["..a.."]  " or "•  ");
						str = str..((rewardInfo.Weekday and "("..rewardInfo.Weekday..") " or "")..(lib.Name)..": ".. math.ceil(oddsProb *1000)/10 .."%")
						str = str.."\n";
						
					end
				end
			end
			if chance <= groups[a].TotalChance then
				str = str..(multiSlot and "["..a.."]  " or "•  ");
				str = str..("Nothing: ".. math.ceil(( (groups[a].TotalChance-chance) /groups[a].TotalChance)*1000)/10 .."%");
				str = str.."\n";
			end
		end
			
		itemDesc = itemDesc.."\n\n"..h3O.."Rewards: "..h3C.."\n"..colorStringText(str);
	end
	
	nameTag.Text = itemName;
	
	itemIcon.Image = itemLibIcon;
	itemIcon.ImageColor3 = itemColor;
	
	quantityLabel.Text = storageItemData and storageItemData.Quantity > 1 and "x"..storageItemData.Quantity or "";
	
	typeIcon.Image =  modItemsLibrary.TypeIcons[itemLib.Type] or "";
	
	descLabel.Text = itemDesc;
	
	local textbounds = TextService:GetTextSize(itemDesc, 
		descLabel.TextSize, 
		descLabel.Font, 
		Vector2.new(300, 1000));
	
	self.Frame.Size = UDim2.new(0, 340, 0, frameHeight+textbounds.Y + 125);	
end

local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
local moddedSelf = modModEngineService:GetModule(script.Name);
if moddedSelf then moddedSelf:Init(ItemInterface); end

return ItemInterface;