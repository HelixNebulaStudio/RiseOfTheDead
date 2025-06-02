local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local TweenService = game:GetService("TweenService");

local localPlayer = game.Players.LocalPlayer;

local modItemModsLibrary = shared.require(game.ReplicatedStorage.Library.ItemModsLibrary);
local modWorkbenchLibrary = shared.require(game.ReplicatedStorage.Library:WaitForChild("WorkbenchLibrary"));
local modBranchConfigs = shared.require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("BranchConfigurations"));
local modItemLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

local modStorageInterface = shared.require(game.ReplicatedStorage.Library.UI.StorageInterface);
local modComponents = shared.require(game.ReplicatedStorage.Library.UI.Components);


local WorkbenchClass = {};
--==

function WorkbenchClass.init(interface: InterfaceInstance, workbenchWindow: InterfaceWindow)
	local modData = shared.require(localPlayer:WaitForChild("DataModule"));

	local binds = workbenchWindow.Binds;

	local upgradeFrameTemplate = script:WaitForChild("UpgradeFrame");
	local capacityFrameTemplate = script:WaitForChild("CapacityFrame");
	local addModuleFrameTemplate = script:WaitForChild("AddModuleFrame");

	local upgradeLevelListTemplate = script:WaitForChild("UpgradeLevelList");
	local upgradeLevelButtonTemplate = script:WaitForChild("UpgradeLevelButton");

	local LevelSlotTemplateStart = script:WaitForChild("LevelSlotStart");
	local LevelSlotTemplate = script:WaitForChild("LevelSlot");
	local templateSliderBar = script:WaitForChild("SliderBar");

	local remotes = game.ReplicatedStorage.Remotes;
	local remotePurchaseUpgrade = remotes.Workbench:WaitForChild("PurchaseUpgrade");
	local remoteModHandler = remotes.Workbench:WaitForChild("ModHandler");
	local remoteItemModAction = modRemotesManager:Get("ItemModAction");

	local ModUpgrader = {};
	local upgradesGuiTable = {};

	function ModUpgrader.new(modLib, modifierStorageItem, equipmentStorageItem)
		local self = {
			RefreshEquippedMods = nil;
			Clickable = true;
		};
		
		local itemModifierSiid = modifierStorageItem.ID;
		local equipmentSiid = equipmentStorageItem.ID;

		local itemLib = modItemLibrary:Find(modifierStorageItem.ItemId);
		
		local tierColor = modItemLibrary.TierColors[itemLib.Tier];
		if modifierStorageItem.Values.Tier then
			tierColor = modItemLibrary.TierColors[modifierStorageItem.Values.Tier];
		end
		
		local upgradeFrame = upgradeFrameTemplate:Clone();
		local titleTag = upgradeFrame:WaitForChild("TitleTag");
		local upgradesList = upgradeFrame:WaitForChild("Upgrades");
		local upgradesListLayout = upgradesList:WaitForChild("UIListLayout");
		self.UpgradeFrame = upgradeFrame;

		local gapFrame = upgradesList:WaitForChild("Gap");
		local descTag = upgradesList:WaitForChild("DescTag");
		local detachButton = upgradeFrame:WaitForChild("DetachButton");
		self.DetachButton = detachButton;
		
		
		local tierOfItem, tierOfMod;
		local function updateFrameDetails()
			self.UpgradeFrame.LayoutOrder = modifierStorageItem.Index or 999;
			
			titleTag.Text = modLib.Name;
			titleTag.TextColor3 = tierColor;
			
			if equipmentStorageItem then
				local upgradeLib = modWorkbenchLibrary.ItemUpgrades[equipmentStorageItem.ItemId];
				tierOfItem = (upgradeLib and upgradeLib.Tier) or 1;
				
				tierOfMod = modifierStorageItem.Values.Tier or modLib.Tier;
				
				if tierOfItem < tierOfMod then
					titleTag.Text = modLib.Name..' <font color="rgb(221, 97, 97)">(Incompatible Tier)</font>';
				end
			end

			if modifierStorageItem.Values.StackConflict then
				titleTag.Text = modLib.Name..' <font color="rgb(221, 97, 97)">('.. modifierStorageItem.Values.StackConflict ..' Conflict)</font>';
			end
		end
		updateFrameDetails();
		
		upgradeFrame.Name = modLib.Name;
		descTag.Text = binds.ListMods.UpdateModDesc(modifierStorageItem, modLib, equipmentStorageItem)
		
		local levelButtons = {};
			
		upgradesListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() --not crash
			TweenService:Create(upgradeFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size=UDim2.new(1, 0, 0, upgradesListLayout.AbsoluteContentSize.Y+30)}):Play();
		end)
		
		local detachDebounce = false;
		detachButton.MouseButton1Click:Connect(function()
			if detachDebounce then return end;
			detachDebounce = true;
			interface:PlayButtonClick();
			upgradeFrame.Visible = false;
			local success = remoteModHandler:InvokeServer(binds.InteractObject, 2, itemModifierSiid);
			if type(success) ~= "number" then
				upgradeFrame:Destroy();
				upgradesGuiTable[itemModifierSiid] = nil;
				
				modStorageInterface.UpdateStorages(success);
				if self.RefreshEquippedMods then self.RefreshEquippedMods() end;
				
				local equipmentClass = shared.modPlayers.get(localPlayer).WieldComp:GetEquipmentClass(equipmentSiid);
				if equipmentClass then
					equipmentClass.Configurations:Calculate();
				end
				
			else
				if success == 3 then
					modClientGuis.promptWarning("Mod equipped in a different tool!");
				elseif success == 4 then
					modClientGuis.promptWarning("Storage is full!");
				else
					modClientGuis.promptWarning("Unknown error("..tostring(success)..").");
				end
				upgradeFrame.Visible = true;
			end
			
			local weaponStatsWindow: InterfaceWindow = interface:GetWindow("WeaponStats");
			if weaponStatsWindow then
				weaponStatsWindow:Update(equipmentStorageItem);
				task.delay(0.2, function()
					weaponStatsWindow:Update(equipmentStorageItem);
				end)
			end
			
			detachDebounce = false;
		end)
		
		local expanded, expandDebounce = false, false;
		self.Expand = function()
			expandDebounce = true;
			for oId, obj in pairs(upgradesGuiTable) do
				if oId ~= itemModifierSiid then
					spawn(function()
					obj.Minimize();
					end)
				end
			end
			for i=#levelButtons, 1, -1 do
				if levelButtons[i] then levelButtons[i].Visible = true; else table.remove(levelButtons, i) end
			end;
			descTag.Text = binds.ListMods.UpdateModDesc(modifierStorageItem, modLib, equipmentStorageItem);
			descTag.Size = UDim2.new(1, -30, 0, 0);
			gapFrame.Visible = true;
			descTag.Visible = true;
			descTag.RichText = true;
			wait(0.1);
			expanded = true;
			expandDebounce = false;
		end
		
		self.Minimize = function()
			expandDebounce = true;
			for i=#levelButtons, 1, -1 do
				if levelButtons[i] then levelButtons[i].Visible = false; else table.remove(levelButtons, i) end
			end;
			gapFrame.Visible = false;
			descTag.Visible = false;
			descTag.RichText = false;
			wait(0.1);
			expanded = false;
			expandDebounce = false;
		end
		
		upgradeFrame.InputBegan:Connect(function(inputObject, gameProcessed)
			if self.Clickable == false then return end;
			if not gameProcessed and not expandDebounce then
				if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
					interface:PlayButtonClick();
					if not expanded then
						self.Expand();
					else
						self.Minimize();
					end
				end
			end
		end)
		
		local LevelObject = {};
		self.Update = function(siom)
			modifierStorageItem = modData.GetItemById(itemModifierSiid);

			tierColor = modItemLibrary.TierColors[itemLib.Tier];

			if modifierStorageItem.Values.Tier then
				tierColor = modItemLibrary.TierColors[modifierStorageItem.Values.Tier];
			end
			
			updateFrameDetails();
			descTag.Text = binds.ListMods.UpdateModDesc(modifierStorageItem, modLib, equipmentStorageItem);
			
			for b=1, #modLib.Upgrades do
				if LevelObject[b] ~= nil then LevelObject[b].Update(); continue end;
				
				LevelObject[b] = {};
				
				local upgradeData = modLib.Upgrades[b];
				local _upgradeName = upgradeData.Name;
				local newLevelList = upgradeLevelListTemplate:Clone();
				local newLevelButton = upgradeLevelButtonTemplate:Clone();
				newLevelList.Parent = upgradesList;
				newLevelButton.Parent = upgradesList;
				newLevelButton.Name = upgradeData.Name.."UpgradeButton";
				table.insert(levelButtons, newLevelButton);

				
				local currencyType = upgradeData.Currency or "Perks";
				local dataUpgradeLevel = (modifierStorageItem.Values[upgradeData.DataTag] or 0);
				local upgradeCost = modWorkbenchLibrary.CalculateCost(upgradeData, dataUpgradeLevel);
				
				local upgradeMaxLevel = upgradeData.MaxLevel;
				local newPointSize = (math.max(310, newLevelList.AbsoluteSize.X) /upgradeMaxLevel);
				
				
				local sliderObj;
				if upgradeData.SliderTag then
					local levelVal = modifierStorageItem.Values[upgradeData.DataTag] or 0;
					local selectVal = modifierStorageItem.Values[upgradeData.SliderTag] or levelVal;
					local sliderVal = math.clamp(selectVal / upgradeData.MaxLevel, 0, 1);

					local newBar = templateSliderBar:Clone();
					local bkFrame = newBar:WaitForChild("BkFrame");
					bkFrame.BackgroundColor3 = tierColor;
					local sliderNob = newBar:WaitForChild("SliderNob");
					sliderNob.BackgroundColor3 = tierColor;
					newBar.Parent = upgradesList;

					local _lastSliderInput = nil;
					
					sliderObj = modComponents.CreateSliderType2(interface, {
						MaxValue = math.clamp(levelVal / upgradeData.MaxLevel, 0, 1);
						DefaultValue = sliderVal;

						SliderBar = newBar;
						SetFunc = function(newVal, refresh)
							levelVal = (modifierStorageItem.Values[upgradeData.DataTag] or 0);
							
							local valToLvl = math.clamp(math.round(newVal * upgradeData.MaxLevel +0.475), 0, levelVal);

							modifierStorageItem.Values[upgradeData.SliderTag] = valToLvl;
							descTag.Text = binds.ListMods.UpdateModDesc(modifierStorageItem, modLib, equipmentStorageItem)
							
							if refresh == true and sliderObj.Disabled ~= true then
								sliderObj.Disabled = true;
								
								local setValuePacket = {
									StorageItemID=itemModifierSiid;
									DataTag=upgradeData.SliderTag;
									Value=valToLvl;
									Key=modLib.Module.Name;
								}
								
								remoteItemModAction:InvokeServer("setvalue", setValuePacket);
								modifierStorageItem.Values[upgradeData.SliderTag] = valToLvl;
								
								self.Update();
								if self.RefreshEquippedMods then self.RefreshEquippedMods() end;
								sliderObj.Disabled = false;
							end
						end;
					})

				end
				
				
				local purchaseUpgradeDebounce = false;
				newLevelButton.MouseButton1Click:Connect(function()
					if dataUpgradeLevel >= upgradeMaxLevel then return end;
					if purchaseUpgradeDebounce then return end;
					purchaseUpgradeDebounce = true;
					binds:PlayUpgradeSound();
					local playerStats = modData.GetStats();
					
					if currencyType == "Perks" and (playerStats[currencyType] or 0) < upgradeCost then
						newLevelButton.Text = "Not enough Perks";
						wait(1);
						interface:ToggleWindow("GoldMenu", true, "PerksPage");
						return;
					end
					
					local serverReply = remotePurchaseUpgrade:InvokeServer(binds.InteractObject, itemModifierSiid, upgradeData.DataTag);
					if serverReply == modWorkbenchLibrary.PurchaseReplies.Success then
						local newLevel = dataUpgradeLevel+1;
						
						local pointFrame =  LevelSlotTemplate:Clone();
						if itemLib.Tier then
							pointFrame.ImageColor3 = tierColor;
							
						end
						
						pointFrame.LayoutOrder = newLevel;
						pointFrame.Size = UDim2.new(0, newPointSize, 1, 0);
						
						pointFrame.Parent = newLevelList;
						newLevelButton.Text = "Upgrade Successful!";
						
						modifierStorageItem.Values[upgradeData.DataTag] = newLevel;
						dataUpgradeLevel = modifierStorageItem.Values[upgradeData.DataTag];
						
						if dataUpgradeLevel >= upgradeMaxLevel then
							newLevelButton.Text = upgradeData.Syntax.." Maxed";
							if newLevelList:FindFirstChild("EmptyLevelSlot") then newLevelList.EmptyLevelSlot:Destroy() end;
							
						end
						
						if sliderObj then
							if upgradeData.SliderTag then
								modifierStorageItem.Values[upgradeData.SliderTag] = nil;
							end
							
							sliderObj.MaxValue = math.clamp(newLevel / upgradeData.MaxLevel, 0, 1);
							sliderObj.Update(sliderObj.MaxValue);
						end
						
						self.Update();
						
						wait(0.45);
						if dataUpgradeLevel < upgradeMaxLevel then
							upgradeCost = modWorkbenchLibrary.CalculateCost(upgradeData, dataUpgradeLevel);
							newLevelButton.Text = upgradeData.Syntax.." ("..upgradeCost.." "..currencyType..")";
						end
						
						self.Update();
						if self.RefreshEquippedMods then self.RefreshEquippedMods() end;
						
					else
						Debugger:Warn("Upgrade Purchase>> Error Code:"..serverReply);
						newLevelButton.Text = string.gsub(modWorkbenchLibrary.PurchaseReplies[serverReply] or ("Error Code: "..serverReply), "$Currency", currencyType);
						wait(1);
						newLevelButton.Text = upgradeData.Syntax.." ("..upgradeCost.." "..currencyType..")";
						
					end
					purchaseUpgradeDebounce = false;
				end)
				
				
				LevelObject[b].Update = function()
					for _, c in pairs(newLevelList:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end; end
					dataUpgradeLevel = math.min(modifierStorageItem.Values[upgradeData.DataTag] or 0, upgradeMaxLevel);
					upgradeCost = modWorkbenchLibrary.CalculateCost(upgradeData, dataUpgradeLevel);
					
					local itemLib = modItemLibrary:Find(modifierStorageItem.ItemId);
				
					for c=1, dataUpgradeLevel do
						local slotImg = LevelSlotTemplate;
						if c <= 1 then
							slotImg = LevelSlotTemplateStart;

						end
						
						local levelSlot = slotImg:Clone();
						
						if itemLib.Tier then
							levelSlot.ImageColor3 = tierColor;
							
							if tierOfItem and tierOfItem < tierOfMod then
								local disabledImageLabel = levelSlot:WaitForChild("Disabled");
								local tierDiff = (tierOfMod-tierOfItem);
								local disablePoint = upgradeMaxLevel-tierDiff;
								
								if c > disablePoint then
									disabledImageLabel.Visible = true;
								else
									disabledImageLabel.Visible = false;
								end
							end
						end

						levelSlot.Size = UDim2.new(0, newPointSize, 1, 0);
						levelSlot.LayoutOrder = c;
						
						levelSlot.Parent = newLevelList;
					end
					
					newLevelButton.LayoutOrder = 5+b*5;
					newLevelList.LayoutOrder = b*2-1;
					newLevelList.Visible = true;
					
					if dataUpgradeLevel < upgradeMaxLevel then
						local slotImg = LevelSlotTemplate;
						
						if dataUpgradeLevel <= 0 then
							slotImg = LevelSlotTemplateStart;
							
						end
						
						local emptyLevelSlot = slotImg:Clone();
						emptyLevelSlot.Name = "EmptyLevelSlot";
						emptyLevelSlot.ImageColor3 = Color3.fromRGB(25, 25, 25);
						
						if itemLib.Tier then
							emptyLevelSlot.ImageColor3 = Color3.fromRGB(
								tierColor.R*255 *0.4,
								tierColor.G*255 *0.4,
								tierColor.B*255 *0.4
							);
						end

						emptyLevelSlot.Size = UDim2.new(0, newPointSize, 1, 0);
						emptyLevelSlot.LayoutOrder = 99;
						emptyLevelSlot.Parent = newLevelList;
						
						newLevelButton.Text = upgradeData.Syntax.." ("..upgradeCost.." "..currencyType..")";
						
					else
						newLevelButton.Text = upgradeData.Syntax.." Maxed";
						
					end
				end
				
				LevelObject[b].Update();
			end
		end
		
		self.Destroy = function()
			upgradeFrame:Destroy();
			table.clear(self);
		end
		
		self.Update();
		
		return self;
	end

	local equipmentModCapacity = 5;
	function WorkbenchClass.new(itemId, library, storageItem)
		local listMenu = binds.List.create();
		listMenu.Menu.Name = "upgradeMenu";
		listMenu:SetEnableScrollBar(false);
		listMenu:SetEnableSearchBar(false);
		
		upgradesGuiTable = {};
		local _itemValues = storageItem.Values;
		local itemLib = modItemLibrary:Find(itemId);

		local equipmentSiid = storageItem.ID;
		
		if itemLib.Type == modItemLibrary.Types.Mod then
			listMenu:SetListPadding(UDim2.new(1, 0, 1, 0));
			
			local modLib = modItemModsLibrary.Get(itemId);
			local upgrader = ModUpgrader.new(modLib, storageItem);
			upgrader.UpgradeFrame.Size = UDim2.new(1, 0, 1, 0);
			upgrader.DetachButton.Visible = false;
			upgrader.Clickable = false;
			
			upgrader.Expand();
			listMenu:Add(upgrader.UpgradeFrame);
			
		else
			local equipmentClass = shared.modPlayers.get(localPlayer).WieldComp:GetEquipmentClass(equipmentSiid);
			
			interface:ToggleWindow("WeaponStats", true, storageItem);
			
			local capacityFrame = capacityFrameTemplate:Clone();
			local modsAttached = 0;
			local titleTag = capacityFrame:WaitForChild("TitleTag");
			local bar = capacityFrame:WaitForChild("frameBar"):WaitForChild("Bar");
			bar.BackgroundColor3 = modBranchConfigs.BranchColor;
			capacityFrame.Visible = true;
			listMenu:Add(capacityFrame, 1);
			
			local function refreshCapcityLabel()
				titleTag.Text = ("Mod Capacity: $a/$b"):gsub("$a", modsAttached):gsub("$b", equipmentModCapacity);
				pcall(function()
					bar:TweenSize(
						UDim2.new(math.clamp((modsAttached or 0)/equipmentModCapacity, 0, 1), 0, 1, 0),
						Enum.EasingDirection.InOut,
						Enum.EasingStyle.Quad,
						0.5,
						true
					)
				end)
			end
			
			local function refreshEquippedMods()
				modsAttached = 0;
				
				local itemStorage = modData.GetItemStorage(equipmentSiid);
				if itemStorage then
					local pModOrder = {};
					
					for modId, modifierStorageItem in pairs(itemStorage.Container) do
						modsAttached = modsAttached +1;
						
						local modLib = modItemModsLibrary.Get(modifierStorageItem.ItemId);
						if modLib == nil then Debugger:Warn("Mod ("..tostring(modifierStorageItem.ItemId)..") does not exist in library."); continue end;
						
						if upgradesGuiTable[modId] == nil then
							local upgrader = ModUpgrader.new(modLib, modifierStorageItem, storageItem);
							upgrader.RefreshEquippedMods = refreshEquippedMods;
							
							listMenu:Add(upgrader.UpgradeFrame); --, modifierStorageItem.Index
							upgradesGuiTable[modId] = upgrader;
						end
						
						pModOrder[modLib.Id] = modifierStorageItem.Index;
						upgradesGuiTable[modId].Update(modifierStorageItem);
					end
					
					for id, upgradeObject in pairs(upgradesGuiTable) do
						if itemStorage.Container[id] == nil then
							upgradeObject.Destroy();
							upgradesGuiTable[id] = nil;
						end
					end
				end;
				refreshCapcityLabel();

				interface:ToggleWindow("WeaponStats", true, storageItem);
				--modInventoryInterface.UpdateHotbarSize();
			end
			refreshEquippedMods();
			
			local addFrame = addModuleFrameTemplate:Clone();
			local moduleTypeTitle = addFrame:WaitForChild("TitleTag");
			local addModuleButton = addFrame:WaitForChild("AddModuleButton");
			moduleTypeTitle.Text = "Add Mod";
			addFrame.Visible = true;
			listMenu:Add(addFrame, 999);
			
			addModuleButton.MouseButton1Click:Connect(function()
				interface:PlayButtonClick();
				local modsListMenu = binds.ListMods.new{UpgradeLib=library; ItemClass=equipmentClass;};
				
				local addModButtonDebounce = false;
				modsListMenu.OnItemButtonClick = function(itemMod)
					if addModButtonDebounce then return end;
					addModButtonDebounce = true;
					interface:PlayButtonClick();
					local success = remoteModHandler:InvokeServer(binds.InteractObject, 1, itemMod.ID, equipmentSiid);
					if type(success) ~= "number" then
						modStorageInterface.UpdateStorages(success);
						binds:PlayUpgradeSound();

						local equipmentClass = shared.modPlayers.get(localPlayer).WieldComp:GetEquipmentClass(equipmentSiid); 
						if equipmentClass then
							equipmentClass.Configurations:Calculate();
						end
						
					else
						if success == 1 then
							modClientGuis.promptWarning("Mod capacity is full!");
							
						elseif success == 2 then
							modClientGuis.promptWarning("Mod already equiped!");
							
						elseif success == 3 then
							modClientGuis.promptWarning("Failed to attach non-mod item!");
							
						elseif success == 4 then
							modClientGuis.promptWarning("Unknown compatibility for "..itemLib.Name.."!");
							
						elseif success == 5 then
							modClientGuis.promptWarning("Mod incompatible for "..itemLib.Name.."!");
							
						elseif success == 6 then
							modClientGuis.promptWarning("An elemental mod already exist!");
							
						else
							modClientGuis.promptWarning("Unknown error ("..tostring(success)..").");
						end
					end
					
					for a=1, 2 do
						refreshEquippedMods();
						task.wait(0.1);
					end

					addModButtonDebounce = false;
					modsListMenu:Destroy();
					binds.SetPage(listMenu.Menu);
				end
				binds.SetPage(modsListMenu.Menu);
			end)
			
		end
		
		return listMenu;
	end

	return WorkbenchClass
end

return WorkbenchClass;