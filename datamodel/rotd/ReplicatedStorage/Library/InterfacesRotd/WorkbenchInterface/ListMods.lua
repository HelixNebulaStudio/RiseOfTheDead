local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local localPlayer = game.Players.LocalPlayer;

local modItemModsLibrary = shared.require(game.ReplicatedStorage.Library.ItemModsLibrary);
local modWorkbenchLibrary = shared.require(game.ReplicatedStorage.Library.WorkbenchLibrary);
local modItem = shared.require(game.ReplicatedStorage.Library.ItemsLibrary);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modToolTweaks = shared.require(game.ReplicatedStorage.Library.ToolTweaks);

local WorkbenchClass = {};
--==

function WorkbenchClass.init(interface: InterfaceInstance, workbenchWindow: InterfaceWindow)
	local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);

	local modData = shared.require(localPlayer:WaitForChild("DataModule"));

	local wieldComp: WieldComp = shared.modPlayers.get(localPlayer).WieldComp;

	local binds = workbenchWindow.Binds;

	function WorkbenchClass.UpdateModDesc(storageItem, modLib, containerStorageItem)
		local upgradeLib, tierOfItem, tweakValues
		if containerStorageItem then
			upgradeLib = modWorkbenchLibrary.ItemUpgrades[containerStorageItem.ItemId];
			tierOfItem = (upgradeLib and upgradeLib.Tier);
			tweakValues = containerStorageItem and containerStorageItem.Values and containerStorageItem.Values.TweakValues or {};
		end
		
		if modLib.Desc then
			local desc = modLib.Desc;

			for a=1, #modLib.Upgrades do
				if a==1 then desc = desc .."\n" end;

				local upgradeInfo = modLib.Upgrades[a];
				local layerInfo = modItemModsLibrary.GetLayer(upgradeInfo.DataTag, {
					ModStorageItem = storageItem;
					StorageItem = containerStorageItem;
					ItemTier = tierOfItem or modLib.BaseTier;
					TweakStat = tweakValues and tweakValues[storageItem.Index];
				});

				
				local upgradeLvl = (storageItem.Values[upgradeInfo.DataTag] or 0);
				local maxLvl = layerInfo.MaxLevel; --modLib.Upgrades[a].MaxLevel;

				local upgradeValue = layerInfo.Value;

				desc = desc .."\n"
				desc = desc ..'<font size="16"><b>'..upgradeInfo.Name..":  "..'</b></font>';
				
				local _valueType = upgradeInfo.ValueType;
				local dP = upgradeInfo.ValueDp or 2;
				
				local dPV = math.pow(10, dP);
				local statStr = math.round(upgradeValue*dPV*100)/dPV;
				
				if upgradeInfo.ValueType == "Normal" then
					statStr = math.round(upgradeValue*dPV)/dPV;
					
					if upgradeInfo.Suffix == nil then
						upgradeInfo.Suffix = "";
					end

				end
				desc = desc ..(upgradeInfo.Prefix or "+").. statStr ..(upgradeInfo.Suffix or "%");
				
				--Tweaks
				local tweakBonusValue = layerInfo.TweakValue or 0;
				if containerStorageItem then
					local tweakValue = tweakValues[storageItem.Index];

					if tweakValue and upgradeInfo.TweakBonus then
						local tierColor = modToolTweaks.GetTierColor(tweakValue);
						local tweakStr = upgradeInfo.Prefix or "+";
						
						local tweakAlpha = math.abs(tweakValue/100);
						if upgradeInfo.ValueType == "Normal" then
							tweakStr = tweakStr .. math.round(upgradeInfo.TweakBonus * tweakAlpha *dPV)/dPV;
						else
							tweakStr = tweakStr .. math.round(upgradeInfo.TweakBonus * tweakAlpha *dPV*100)/dPV;
						end
						tweakStr = tweakStr .. (upgradeInfo.Suffix or "%");
						
						desc = desc..' <font color="#'.. tierColor:ToHex() ..'">'..tweakStr.."</font>";
					end

					local equipmentClass: EquipmentClass = wieldComp:GetEquipmentClass(containerStorageItem.ID);
					if equipmentClass and equipmentClass.Configurations.PreModDamage then
						local pmd = equipmentClass.Configurations.PreModDamage;

						if upgradeInfo.Name == "Damage" then
							desc = desc ..`    <b>≈</b>   +{math.round((pmd * (upgradeValue + tweakBonusValue))*100)/100}`;
						end
					end

				end
				
				
				-- Slider;
				if upgradeInfo.SliderTag then
					desc = desc .."\n"
					desc = desc ..'<font size="16"><b>Active '..upgradeInfo.Name..":  "..'</b></font>';
					
					local activeLvl = storageItem.Values[upgradeInfo.SliderTag] or upgradeLvl;
					
					local activeValue;
					if upgradeInfo.Scaling == modItemModsLibrary.ScalingStyle.NaturalCurve then
						activeValue = modItemModsLibrary.NaturalInterpolate(upgradeInfo.BaseValue, upgradeInfo.MaxValue, activeLvl, maxLvl, upgradeInfo.Rate);
					elseif upgradeInfo.Scaling == modItemModsLibrary.ScalingStyle.Linear then
						activeValue = modItemModsLibrary.Linear(upgradeInfo.BaseValue, upgradeInfo.MaxValue, activeLvl, maxLvl);
					end

					local statActiveStr = math.round(activeValue*dPV*100)/dPV;

					if upgradeInfo.ValueType == "Normal" then
						statActiveStr = math.round(activeValue*dPV)/dPV;
					end
					desc = desc ..(upgradeInfo.Prefix or "+").. statActiveStr ..(upgradeInfo.Suffix or "%");
				end
				
			end

			--Tier Damage
			local modifier: ItemModifierInstance? = wieldComp:GetOrDefaultItemModifier(storageItem.ID);
			if modifier then
				local additionalDmg, scale = modItemModifierClass.AddTierDamage(modifier);
				
				if additionalDmg then
					if #modLib.Upgrades <= 0 then
						desc = desc .."\n";
					end
					desc = desc ..`\n<font size="16"><b>Tier {modLib.BaseTier} Mod Damage:  </b></font>`;
					desc = desc ..`+{math.round(scale*100)}%`;
					desc = desc ..`    <b>≈</b>   +{math.round(additionalDmg*100)/100}`;
				end
			end
			
			return desc;
		end
		return;
	end

	function WorkbenchClass.new(paramPacket)
		local compatTypes = paramPacket.UpgradeLib.Type;
		
		local itemHandlerClass = paramPacket.ItemClass;
		local compatElement = itemHandlerClass.Configurations.Element;
		
		
		binds.ClearPages("modsList");
		local listMenu = binds.List.create();
		listMenu.Menu.Name = "modsList";
		
		local categories = {};
			
		local modsStorage = modData.GetAllMods(); -- Equipped mods aren't listed.
		local compatibleMods = 0;
		for a=1, #modsStorage do
			-- storageItem = {ID; ItemId; Values;};
			local storage = modsStorage[a].Storage;
			local storageItem = modsStorage[a].Item;
			
			local modLib = modItemModsLibrary.Get(storageItem.ItemId);
			if modLib then
				local compatible = false;
				for b=1, #modLib.Type do
					for c=1, #compatTypes do
						if modLib.Type[b] == compatTypes[c] then
							compatible = true;
							break;
						end
					end
				end;
				if modLib.Element and compatElement and modLib.Element ~= compatElement then
					compatible = false;
				end
				
				if modConfigurations.IgnoreModCompatibility then
					compatible = true;
				end
				
				if compatible then
					compatibleMods = compatibleMods +1;
					if categories[modLib.Category] == nil then categories[modLib.Category] = {}; end;
					table.insert(categories[modLib.Category], {Item=storageItem; Storage=storage; Lib=modLib});
				end
			end
		end
		
		for category, modsList in pairs(categories) do
			local newGridList = listMenu:NewGridList();
			newGridList.Name = category.."list";
			local newCateTab = listMenu:NewTab(newGridList);
			newCateTab.Name = category.."tab";
			newCateTab.titleLabel.Text = category;
			
			for a=1, #modsList do
				local mod = modsList[a];
				local newListing = listMenu:NewItemButton(mod.Lib.Id, mod.Item);
				
				newListing.Name = mod.Lib.Name;
				newListing.Image = mod.Lib.Icon;
				newListing.ImageColor3 = modItem.TierColors[mod.Lib.Tier];
				newListing.LayoutOrder = mod.Lib.Order;
				newListing.Parent = newGridList.list;
				
				newListing.MouseButton1Click:Connect(function()
					if listMenu.OnItemButtonClick then
						interface:PlayButtonClick();
						listMenu.OnItemButtonClick(mod.Item, mod.Storage);
					end
				end)
				
				listMenu:AddSearchIndex(newListing, {mod.Item.ItemId; mod.Lib.Name;});
			end
			
			local order = modWorkbenchLibrary.CategorySorting[category] or 999;
			listMenu:Add(newCateTab, order);
			listMenu:Add(newGridList, order+1);
		end
		
		if compatibleMods <= 0 then
			listMenu:NewLabel("No compatible mods available.");
		elseif #modsStorage <= 0 then
			listMenu:NewLabel("No mods available.");
		end
		
		return listMenu;
	end

	return WorkbenchClass
end

return WorkbenchClass;