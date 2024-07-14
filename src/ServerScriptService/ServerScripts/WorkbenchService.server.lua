local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
repeat task.wait() until shared.MasterScriptInit == true;

--== Variables;
local modWeapons = require(game.ReplicatedStorage.Library.Weapons);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modWorkbenchLibrary = require(game.ReplicatedStorage.Library.WorkbenchLibrary);
local modColorsLibrary = require(game.ReplicatedStorage.Library.ColorsLibrary);
local modSkinsLibrary = require(game.ReplicatedStorage.Library.SkinsLibrary);
local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);
local modBlueprintLibrary = require(game.ReplicatedStorage.Library.BlueprintLibrary) :: any;
local modSyncTime = require(game.ReplicatedStorage.Library:WaitForChild("SyncTime"));
local modRemotesManager = require(game.ReplicatedStorage.Library:WaitForChild("RemotesManager"));
local modItemUnlockablesLibrary = require(game.ReplicatedStorage.Library.ItemUnlockablesLibrary);
local modToolTweaks = require(game.ReplicatedStorage.Library.ToolTweaks);
local modItemSkinWear = require(game.ReplicatedStorage.Library.ItemSkinWear);
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
local modGlobalVars = require(game.ReplicatedStorage.GlobalVariables);

local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);
local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);
local modSkillTree = require(game.ServerScriptService.ServerLibrary.SkillTree);
local modAnalyticsService = require(game.ServerScriptService.ServerLibrary.AnalyticsService);

local remotes = game.ReplicatedStorage.Remotes;
local remotePurchaseUpgrade = remotes.Workbench.PurchaseUpgrade;
local remoteModHandler = remotes.Workbench.ModHandler;
local remoteSetAppearance = remotes.Workbench.SetAppearance;

local remoteBlueprintHandler = modRemotesManager:Get("BlueprintHandler");
local remoteDeconstruct = modRemotesManager:Get("DeconstructItem");
local remoteTweakItem = modRemotesManager:Get("TweakItem");
local remotePolishTool = modRemotesManager:Get("PolishTool");

local Interactables = workspace:WaitForChild("Interactables");
local debounceCache = {};
--== Script;
for itemId, modLib in pairs(modModsLibrary.Library) do
	if modLib.Module == nil then continue end;
	task.spawn(function()
		require(modLib.Module);
	end)
end

local function clearDebounceCaches() for n, c in pairs(debounceCache) do if tick()-c > 1 then debounceCache[n]=nil; end; end; end

function IsInWorkbenchRange(player, interactPart)
	local profile = modProfile:Get(player);
	if profile.GamePass.PortableWorkbench then return true end;
	if interactPart and interactPart:IsDescendantOf(Interactables) and player:DistanceFromCharacter(interactPart.Position) <= 17 then
		return true;
	end
	return false;
end

function CheckBlueprintCost(player, bpId)
	local library = modBlueprintLibrary.Get(bpId);
	if library then
		local profile = modProfile:Get(player);
		local activeSave = profile:GetActiveSave();
		
		local requirements = library.Requirements;
		
		local done = false;
		local fulfillment = {};
		for a=1, #requirements do
			coroutine.wrap(function()
				local rndex = a;
				local requirement = requirements[rndex];
				fulfillment[rndex] = setmetatable({Fulfilled=false;},{__index=function(s,k) return requirement[k]; end});
				if requirement.Type == "Stat" then
					if activeSave and activeSave:GetStat(requirement.Name) >= requirement.Amount then
						fulfillment[rndex].Fulfilled = true;
					end
					
				elseif requirement.Type == "Item" then
					if profile and profile.ActiveInventory then
						local quantityNeed = requirement.Amount;
						if requirement.ItemId == nil then Debugger:Warn("Blueprint ("..bpId..") does not have ItemId for:",requirement); end;
						local itemsList = profile.ActiveInventory:ListByItemId(requirement.ItemId);
						table.sort(itemsList, function(a,b) return a.Quantity < b.Quantity; end);
						for a=1, #itemsList do
							if fulfillment[rndex].ReferenceId == nil then fulfillment[rndex].ReferenceId = {}; end;
							table.insert(fulfillment[rndex].ReferenceId, itemsList[a].ID);
							quantityNeed = quantityNeed - itemsList[a].Quantity;
							if quantityNeed <= 0 then break; end;
						end
						if quantityNeed > 0 then
							fulfillment[rndex].Requires = math.clamp(quantityNeed, 0, requirement.Amount);
						else
							fulfillment[rndex].Fulfilled = true;
						end;
					else
						Debugger:Warn("Player(",player.Name,") does not have an active inventory.");
					end
					
				end
				if #fulfillment >= #requirements then done = true; end;
			end)();
		end
		if #fulfillment < #requirements then
			for a=0, 5, 0.5 do
				if done then break; end;
				wait(0.5);
			end
		end;
		return fulfillment;
	else
		Debugger:Warn("Library does not exist for blueprint(",bpId,").");
	end
	return;
end

function ConsumeBlueprintCost(player, fulfillment)
	local profile = modProfile:Get(player);
	local playerSave = profile:GetActiveSave();
	local inventory = profile.ActiveInventory;
	
	for _, r in pairs(fulfillment) do
		r.Amount = r.Amount or 1;
		if r.Type == "Stat" and r.Name ~= "Level" then
			if r.Name == "Money" then
				shared.Notify(player, ("-$Amount."):gsub("$Amount", "$"..r.Amount), "Negative");
			else
				shared.Notify(player, ("-$Amount $Stat."):gsub("$Amount", r.Amount):gsub("$Stat", r.Name), "Negative");
			end
			playerSave:AddStat(r.Name, -r.Amount);

			if r.Name == "Perks" or r.Name == "Money" then
				modAnalytics.RecordResource(player.UserId, r.Amount, "Sink", r.Name, "Gameplay", "BuildCost");

				modAnalyticsService:Sink{
					Player=player;
					Currency=modAnalyticsService.Currency[r.Name];
					Amount=r.Amount;
					EndBalance=playerSave:GetStat(r.Name);
					ItemSKU="BuildCost";
				};

			end

		elseif r.Type == "Item" then
			local itemLib = modItemsLibrary:Find(r.ItemId);
			local storageItem = inventory:FindByItemId(r.ItemId);
			if storageItem then
				inventory:Remove(storageItem.ID, r.Amount);
				shared.Notify(player, ("$Amount$Item removed from your Inventory."):gsub("$Item", itemLib.Name):gsub("$Amount", r.Amount > 1 and r.Amount.." " or ""), "Negative");
			end
		end
	end
end

modBlueprintLibrary.ConsumeBlueprintCost = ConsumeBlueprintCost;
modBlueprintLibrary.CheckBlueprintFulfilment = CheckBlueprintCost;

function remoteBlueprintHandler.OnServerInvoke(player, action, packet)
	local rPacket = {};
	if remoteBlueprintHandler:Debounce(player) then return rPacket; end
	
	if action == "build" or action == "cancelbuild" or action == "claim" then
		local workbenchPart = packet.WorkbenchPart;
		if not IsInWorkbenchRange(player, workbenchPart) then
			rPacket.FailCode = modWorkbenchLibrary.BlueprintReplies.TooFar;
			return rPacket;
		end;
	end
	
	
	local profile = modProfile:Get(player);
	local playerSave = profile:GetActiveSave();
	local inventory = profile.ActiveInventory;
	local userBlueprints = playerSave.Blueprints;
	local userWorkbench = playerSave.Workbench;
	
	
	if action == "check" then
		local itemId = packet.ItemId;

		local fulfillment = CheckBlueprintCost(player, itemId);
		modOnGameEvents:Fire("OnCheckBlueprintCost", player, fulfillment);

		rPacket.Success = true;
		rPacket.Fulfillment = fulfillment;

		return rPacket;

	elseif action == "build" then
		local storageItemId = packet.StorageItemId; -- Is bp item if exist.
		local itemId = packet.ItemId;

		local bpStorageItem = storageItemId and inventory:Find(storageItemId) or nil;
		local bpLib;
		
		if bpStorageItem then
			itemId = bpStorageItem.ItemId;
			bpLib = modBlueprintLibrary.Get(itemId);
			
		else
			bpLib = modBlueprintLibrary.Get(itemId);
			
			if userBlueprints:IsUnlocked(itemId) ~= true then
				rPacket.FailCode = modWorkbenchLibrary.BlueprintReplies.BlueprintLocked;
				return rPacket;
			end
			
		end
		
		if bpLib == nil or bpLib.Disabled == true then 
			rPacket.FailCode = modWorkbenchLibrary.BlueprintReplies.Disabled;
			return rPacket;
		end;
		if not userWorkbench:CanNewProcess() then 
			rPacket.FailCode = modWorkbenchLibrary.BlueprintReplies.WorkbenchFull;
			return rPacket;
		end;

		local fulfillment = CheckBlueprintCost(player, itemId);
		if fulfillment == nil then
			rPacket.FailCode = modWorkbenchLibrary.BlueprintReplies.InvalidBlueprint;
			return rPacket;
		end
		for _, r in pairs(fulfillment) do
			if not r.Fulfilled then 
				rPacket.FailCode = modWorkbenchLibrary.BlueprintReplies.InsufficientCurrency;
				return rPacket;
			end;
		end;
		
		ConsumeBlueprintCost(player, fulfillment);
		if bpStorageItem then
			inventory:Remove(storageItemId, 1, function()
				shared.Notify(player, string.gsub("$Item removed from your Inventory.", "$Item", bpStorageItem.Library.Name), "Negative");
			end);
		end
		
		local buildDuration = bpLib.Duration;
		modSkillTree:TriggerSkills(player, "OnBlueprintBuild", buildDuration, function(newDuration) buildDuration = newDuration; end);

		local processPacket = {
			Type=userWorkbench.ProcessTypes.Building;
			ItemId=itemId;
			BT=modSyncTime.GetTime()+buildDuration;
			Blueprint=bpStorageItem ~= nil;

			PlayProcessSound=true;
		};
		userWorkbench:NewProcess(processPacket);
		
		modOnGameEvents:Fire("OnBlueprintBuild", player, userWorkbench, processPacket);
		
		rPacket.Success = true;
		return rPacket;
		
		
	elseif action == "cancelbuild" then
		local buildIndex = packet.Index;
		
		local buildingData = userWorkbench:GetProcess(buildIndex);
		if buildingData == nil then 
			rPacket.FailCode = modWorkbenchLibrary.BlueprintReplies.InvalidBlueprint;
			return rPacket;
		end
		
		local itemId = buildingData.ItemId;
		local blueprintLibrary = modBlueprintLibrary.Get(itemId);
		local itemsRefund = {};

		if buildingData.Blueprint then table.insert(itemsRefund, {ItemId=itemId}) end;
		for a=1, #blueprintLibrary.Requirements do
			local requirement = blueprintLibrary.Requirements[a];
			if requirement.Type == "Item" then
				table.insert(itemsRefund, {ItemId=requirement.ItemId; Data={Quantity=(requirement.Amount or 1)}; CostAmount=(requirement.Amount or 1)})
			end
		end
		
		if not inventory:SpaceCheck(itemsRefund) then
			rPacket.FailCode = modWorkbenchLibrary.BlueprintReplies.InventoryFull;
			return rPacket;
		end

		for a=1, #blueprintLibrary.Requirements do
			local requirement = blueprintLibrary.Requirements[a];
			if requirement.Type == "Stat" then
				if requirement.Name == "Perks" or requirement.Name == "Money" then
					playerSave:AddStat(requirement.Name, requirement.Amount);
				end
			end
		end
		for a=1, #itemsRefund do
			local item = itemsRefund[a];
			local itemLib = modItemsLibrary:Find(item.ItemId);
			inventory:Add(item.ItemId, {Quantity=(item.Data and item.Data.Quantity or 1);}, function(event, storageItem)
				shared.Notify(player, (item.CostAmount) > 1 and itemLib.Name.." ("..item.CostAmount..")" or itemLib.Name, "PickUp");
				modStorage.OnItemSourced:Fire(nil, storageItem,  storageItem.Quantity);
			end);
		end
		userWorkbench:RemoveProcess(buildIndex);
		
		rPacket.Success = true;
		return rPacket;
		
		
	elseif action == "claimbuild" then
		local buildIndex = packet.Index;
		
		local activeBp = userWorkbench:GetProcess(buildIndex);
		if activeBp == nil or activeBp.BT-modSyncTime.GetTime() > 0 then
			rPacket.FailCode = modWorkbenchLibrary.BlueprintReplies.TooFrequentRequest;
			return rPacket;
		end

		local itemId = activeBp.ItemId;
		local bpLib = modBlueprintLibrary.Get(itemId);

		if not inventory:SpaceCheck{{ItemId=bpLib.Product; Data={Quantity=(bpLib.Amount or 1)};}} then
			rPacket.FailCode = modWorkbenchLibrary.BlueprintReplies.InventoryFull;
			return rPacket;
		end
		
		local itemLib = modItemsLibrary:Find(bpLib.Product);
		inventory:Add(bpLib.Product, {Quantity=(bpLib.Amount or 1);}, function(event, storageItem)
			shared.Notify(player, string.gsub("You recieved a $Item.", "$Item", itemLib.Name), "Reward");
			modStorage.OnItemSourced:Fire(nil, storageItem,  storageItem.Quantity);
		end);

		modOnGameEvents:Fire("OnItemBuilt", player, bpLib);

		userWorkbench:RemoveProcess(buildIndex);
		userBlueprints:UnlockBlueprint(itemId);
		profile:AddPlayPoints(bpLib.Duration or 60, "Gameplay:Workbench");
		
		rPacket.Success = true;
		return rPacket;
		
	elseif action == "skipbuild" then
		local buildIndex = packet.Index;

		local activeBp = userWorkbench:GetProcess(buildIndex);
		
		if activeBp == nil or activeBp.BT-modSyncTime.GetTime() <= 0 then
			rPacket.FailMsg = "Invalid process";
			return rPacket;
		end

		local itemId = activeBp.ItemId;
		local bpLib = modBlueprintLibrary.Get(itemId);

		local skipCost = modWorkbenchLibrary.GetSkipCost(activeBp.BT-modSyncTime.GetTime());
		if playerSave:GetStat("Perks") < skipCost then
			rPacket.GoldShop = true;
			return rPacket;
		end
		
		playerSave:AddStat("Perks", -skipCost);
		modAnalytics.RecordResource(player.UserId, skipCost, "Sink", "Perks", "Gameplay", "SkipBuild");
		
		modAnalyticsService:Sink{
			Player=player;
			Currency=modAnalyticsService.Currency.Perks;
			Amount=skipCost;
			EndBalance=playerSave:GetStat("Perks");
			ItemSKU="SkipBuild";
		};

		shared.Notify(player, bpLib.Name.." has finished building.", "Reward");

		activeBp.BT = modSyncTime.GetTime()-1;
		userWorkbench:Sync();
		
		rPacket.Success = true;
		return rPacket;
		
	end
	
	rPacket.FailCode = 10;
	return rPacket;
end

function remoteModHandler.OnServerInvoke(player, interactPart, action, modId, id) -- modId = (mod's) StorageItem.ID; (tool's) id = StorageItem.ID;
	if not IsInWorkbenchRange(player, interactPart) then return modWorkbenchLibrary.PurchaseReplies.TooFar; end;
	if debounceCache[player.Name] and tick()-debounceCache[player.Name]<0.1 then return modWorkbenchLibrary.PurchaseReplies.TooFrequentRequest end;
	debounceCache[player.Name]=tick();
	local profile = modProfile:Get(player);
	local activeSave = profile:GetActiveSave();
	local inventory = profile.ActiveInventory;

	local mod, storageOfMod = activeSave:FindItemFromStorages(modId);
	if mod == nil then return 3; end
	
	local modLib = modModsLibrary.Get(mod.ItemId);
	
	local function sortModsFunc(self)
		local sortedList = {};
		for _, storageItemMod in pairs(self.Container) do
			local modLib = modModsLibrary.Get(storageItemMod.ItemId);

			table.insert(sortedList, {
				StorageItem=storageItemMod;
				Lib=modLib;
				Index=(modLib.Tier or 1)*10000 + (modLib.Layer or 1)*1000 + (modLib.Order or 1);
			});
		end
		table.sort(sortedList, function(a, b) return a.Index < b.Index; end);
		
		local prtList = {};
		for a=1, #sortedList do
			local storageItem = sortedList[a].StorageItem;
			storageItem.Index = a;
			table.insert(prtList, {I=a; N=storageItem.ItemId});
		end
	end
	
	if action == 1 then --== Equip;
		if modLib == nil then return 3; end
		local item, _itemStorage = activeSave:FindItemFromStorages(id);
		
		local toolWorkbenchLib = modWorkbenchLibrary.ItemUpgrades[item.ItemId];
		local toolCompatType = toolWorkbenchLib and toolWorkbenchLib.Type or nil;
		if toolCompatType == nil then return 4; end
		
		local compatible = false;
		for a=1, #modLib.Type do
			for b=1, #toolCompatType do
				if modLib.Type[a] == toolCompatType[b] then
					compatible = true;
					break;
				end
			end
		end
		

		if modConfigurations.IgnoreModCompatibility then
			compatible = true;
		end
		
		if compatible ~= true then return 5 end;
		
		local storageForMod = activeSave.Storages[id];
		if storageForMod == nil then
			local newModsContainer = modStorage.new(id, id, 5, player);
			activeSave.Storages[id] = newModsContainer;
			activeSave.Storages[id].MaxSize = 5;
			
			storageForMod = activeSave.Storages[id];
		end
		storageForMod:ConnectSort(sortModsFunc);
		storageForMod.Expandable = false;
		
		if modLib.Element then
			local elementalModExist = false;
			storageForMod:Loop(function(storageItem)
				local oModLib = modModsLibrary.Get(storageItem.ItemId);
				
				if oModLib and oModLib.Element then
					elementalModExist = true;
					return 6;
				end
				return;
			end)
			if elementalModExist then
				return 6;
			end
		end
		
		if item and mod and storageOfMod.Id ~= id then
			local emptyIndex = storageForMod:FindEmpty();
			if emptyIndex then
				modOnGameEvents:Fire("OnModEquipped", player, mod, item);
				storageOfMod:SetIndex(player, modId, {Id=id; Index=emptyIndex;});
				
				local refreshStorages = {
					storageOfMod:Shrink();
					storageForMod:Shrink();
				};
				activeSave.AppearanceData:Update(activeSave.Clothing);
				
				return refreshStorages;
			else
				return 1;
			end
		else
			Debugger:Warn("Missing item/mod or attempt to equip equipped mod.");
			return 2;
		end

	elseif action == 2 then --== Unequip;
		local item = activeSave:FindItemFromStorages(storageOfMod.Id);
		
		if mod and item then
			local emptyIndex = inventory:FindEmpty();
			if emptyIndex then
				local refreshStorages = storageOfMod:SetIndex(player, modId, {Id=inventory.Id; Index=emptyIndex;});
				if storageOfMod:Loop() <= 0 then
					storageOfMod:Destroy();
				else
					storageOfMod:ConnectSort(sortModsFunc);
				end

				table.insert(refreshStorages, storageOfMod:Shrink());
				activeSave.AppearanceData:Update(activeSave.Clothing);
				return refreshStorages;
			else
				return 4;
			end
		else
			return 3;
		end
	end
	return;
end

function remotePurchaseUpgrade.OnServerInvoke(player, interactPart, id, dataTag)
	if debounceCache[player.Name] and tick()-debounceCache[player.Name]<0.3 then return modWorkbenchLibrary.PurchaseReplies.TooFrequentRequest end;
	debounceCache[player.Name] = tick();
	if not IsInWorkbenchRange(player, interactPart) then return modWorkbenchLibrary.PurchaseReplies.TooFar; end;
	
	local profile = modProfile:Get(player);
	local playerSave = profile:GetActiveSave();
	local storageItem, storage = playerSave:FindItemFromStorages(id);
	local weaponId = storage.Id;
	local modLib = modModsLibrary.Get(storageItem.ItemId);
	
	if storageItem and modLib then
		local upgradeInfo = nil;
		for a=1, #modLib.Upgrades do if modLib.Upgrades[a].DataTag == dataTag then upgradeInfo = modLib.Upgrades[a] end end;
		if upgradeInfo then
			local currencyType = upgradeInfo.Currency or "Perks";
			local upgradeLevel = storageItem.Values[upgradeInfo.DataTag] or 0;
			local upgradeCost = modWorkbenchLibrary.CalculateCost(upgradeInfo, upgradeLevel);
			
			if upgradeLevel+1 <= upgradeInfo.MaxLevel then
				if playerSave and playerSave:GetStat(currencyType) >= upgradeCost then
					playerSave:AddStat(currencyType, -upgradeCost);
					
					storageItem.Values[upgradeInfo.DataTag] = upgradeLevel + 1;
					if upgradeInfo.SliderTag then
						storageItem.Values[upgradeInfo.SliderTag] = nil;
						--storage:SyncValues(id, upgradeInfo.SliderTag);
						storageItem:Sync({upgradeInfo.SliderTag});
					end
					
					playerSave:AwardAchievement("titoup");
					modOnGameEvents:Fire("OnItemUpgraded", player, storageItem);
					
					if weaponId ~= "Inventory" then profile:GetItemClass(weaponId); end
					--storage:SyncValues(id, upgradeInfo.DataTag);
					storageItem:Sync({upgradeInfo.DataTag});
					playerSave.AppearanceData:Update(playerSave.Clothing);
					
					modAnalytics.RecordResource(player.UserId, upgradeCost, "Sink", "Perks", "Gameplay", "ModUpgrade");
					
					modAnalyticsService:Sink{
						Player=player;
						Currency=modAnalyticsService.Currency.Perks;
						Amount=upgradeCost;
						EndBalance=playerSave:GetStat("Perks");
						ItemSKU="ModUpgrade";
					};
					
					return modWorkbenchLibrary.PurchaseReplies.Success;
				else
					return modWorkbenchLibrary.PurchaseReplies.InsufficientCurrency;
				end
			else
				return modWorkbenchLibrary.PurchaseReplies.InvalidUpgrade;
			end
		else
			return modWorkbenchLibrary.PurchaseReplies.InvalidUpgrade;
		end
	end
	
	debounceCache[player.Name]=nil;
	spawn(function() clearDebounceCaches() end);
	return;
end


remoteSetAppearance.OnServerEvent:Connect(function(player, interactPart, action, id, partKey, appearId)
	if debounceCache[player.Name] and tick()-debounceCache[player.Name]<0.3 then return end;
	debounceCache[player.Name]=tick();
	if not IsInWorkbenchRange(player, interactPart) then return end;
	local profile = modProfile:Get(player);
	local activeSave = profile:GetActiveSave();
	local storageItem, _storage = activeSave:FindItemFromStorages(id);
	
	if storageItem == nil then return end;

	local itemId = storageItem.ItemId;
	local modelName = string.find(itemId, "dual") ~= nil and (string.gsub(itemId, "dual", "")) or itemId;
	local itemPrefabs = game.ReplicatedStorage.Prefabs.Items;
	local baseItemModel = itemPrefabs:FindFirstChild(modelName);
	
	--local itemLib = modItemsLibrary:Find(itemId);

	local customizeLib = modWorkbenchLibrary.ItemAppearance[itemId];
	local partName;
	
	if action ~= 9 then
		partName = partKey;
		if partKey:sub(1,2) == "L-" then
			partName = partKey:sub(3, #partKey);
			customizeLib = customizeLib.LeftToolGrip;
		elseif partKey:sub(1,2) == "R-" then
			partName = partKey:sub(3, #partKey);
			customizeLib = customizeLib.RightToolGrip;
		else
			customizeLib = customizeLib.ToolGrip;
		end
		if baseItemModel:FindFirstChild(partName) == nil then Debugger:Warn("Player(",player.Name,") attempt to modify invalid part."); return end;
	end
	
	if storageItem == nil then return end;

	if action == 1 then --== Color;
		if appearId == 0 then
			local itemSkin = storageItem.Values.Colors or {};
			itemSkin[partKey] = nil;
			storageItem:SetValues("Colors", itemSkin);

		else
			Debugger:StudioWarn("Set appearid", appearId);
			local colorLibrary = modColorsLibrary.Get(appearId);
			local unlocked = false;

			local customColorsFlag = profile.Flags:Get("CustomColors");
			if appearId:sub(1,1) == "#" and customColorsFlag and customColorsFlag.Unlocked and customColorsFlag.Unlocked[(string.gsub(appearId, "#", ""))] then
				unlocked = true;
			elseif profile.ColorPacks[colorLibrary.Pack] then
				unlocked = true;
			end

			if colorLibrary and unlocked then
				local itemSkin = storageItem.Values.Colors or {};
				itemSkin[partKey] = appearId;
				storageItem:SetValues("Colors", itemSkin);
				profile:AddPlayPoints(2, "Gameplay:Workbench");

			else
				Debugger:Warn("Color does not exist or color pack is locked.");

			end
		end
		
	elseif action == 2 then --== Details;
	
		if appearId == 0 then
			local itemSkin = storageItem.Values.Textures or {};
			itemSkin[partKey] = storageItem.Values.ActiveSkin and 0 or nil;
			storageItem:SetValues("Textures", itemSkin);
			
		else
			local textureLibrary = modSkinsLibrary.Get(appearId);
			if textureLibrary and profile.SkinsPacks[textureLibrary.Pack] then
				local itemSkin = storageItem.Values.Textures or {};
				itemSkin[partKey] = appearId;
				storageItem:SetValues("Textures", itemSkin);
				profile:AddPlayPoints(2, "Gameplay:Workbench");
				
			else
				Debugger:Warn("Texture does not exist or color pack is locked.",textureLibrary == nil," Unlocked:",profile.SkinsPacks[textureLibrary.Pack]);
			end
		end

	elseif action == 6 then --== Toggle Visibility;
		local partAlpha = storageItem.Values.PartAlpha or {};
		if partAlpha[partKey] == true then
			partAlpha[partKey] = nil;
		else
			partAlpha[partKey] = true;
		end
		
		storageItem:SetValues("PartAlpha", partAlpha);
		profile:AddPlayPoints(2, "Gameplay:Workbench");
		
	elseif action == 3 then --== Clear Color;
		local itemSkin = storageItem.Values.Colors or {};
		itemSkin[partKey] = nil;
		storageItem:SetValues("Colors", itemSkin);
		profile:AddPlayPoints(2, "Gameplay:Workbench");
		
	elseif action == 4 then --== Clear Texture;
		local itemSkin = storageItem.Values.Textures or {};
		itemSkin[partKey] = nil;
		storageItem:SetValues("Textures", itemSkin);
		profile:AddPlayPoints(2, "Gameplay:Workbench");

	elseif action == 5 then --== Clear All;
		local itemColors = storageItem.Values.Colors or {};
		itemColors[partKey] = nil;
		
		local itemTextures = storageItem.Values.Textures or {};
		itemTextures[partKey] = nil;

		local partAlpha = storageItem.Values.PartAlpha or {};
		partAlpha[partKey] = nil;
		
		storageItem:SetValues("Colors", itemColors);
		storageItem:SetValues("Textures", itemTextures);
		storageItem:SetValues("PartAlpha", partAlpha);
		profile:AddPlayPoints(2, "Gameplay:Workbench");
		
		
	elseif action == 9 then --== UnlockableSet;
		if partKey == "UnlockableId" then
			if appearId and appearId ~= storageItem.ItemId then
				local unlockableItemLib = modItemUnlockablesLibrary:Find(appearId);
				if unlockableItemLib and unlockableItemLib.ItemId == storageItem.ItemId then
					local unlockedSkins = storageItem:GetValues("Skins") or {};
					local isUnlocked = table.find(unlockedSkins, unlockableItemLib.Id)

					if unlockableItemLib.Name == "Default" or unlockableItemLib.Unlocked == true then
						isUnlocked = true;
					elseif typeof(unlockableItemLib.Unlocked) == "string" and table.find(unlockedSkins, unlockableItemLib.Unlocked) then
						isUnlocked = true;
					end
					
					if isUnlocked == nil then
						if profile.ItemUnlockables and profile.ItemUnlockables[itemId] and profile.ItemUnlockables[itemId][unlockableItemLib.Id] then
							profile.ItemUnlockables[itemId][unlockableItemLib.Id] = profile.ItemUnlockables[itemId][unlockableItemLib.Id] -1;
							isUnlocked = true;
							
							table.insert(unlockedSkins, unlockableItemLib.Id);

							for a=1, #unlockedSkins do
								unlockedSkins[a] = tostring(unlockedSkins[a]);
							end
							storageItem:SetValues("Skins", unlockedSkins);
						end
					end

					if player.UserId == 16170943 then
						isUnlocked = true;
					end
					if isUnlocked then
						storageItem:SetValues("ActiveSkin", appearId);
					end
				else
					storageItem:DeleteValues("ActiveSkin");
				end

			else
				storageItem:DeleteValues("ActiveSkin");

			end
			
		elseif partKey == "WeaponSkinId" then
			local unlockedSkins = storageItem:GetValues("Skins") or {};

			if appearId == nil then
				storageItem:DeleteValues("ActiveSkin");
				return;
			end

			local isUnlocked = false;
			for a=1, #unlockedSkins do
				if tostring(unlockedSkins[a]) == tostring(appearId) then
					isUnlocked = true;
					break;
				end
			end
			
			if isUnlocked then
				storageItem:SetValues("ActiveSkin", appearId);
			end
			
		end
		
		activeSave.AppearanceData:Update(activeSave.Clothing);
	end
	activeSave:AwardAchievement("fimyst");
	
	storageItem:Sync();
	
	-- Refresh weapon skin;
	if player.Character and profile.OptInNewCustomizationMenu ~= true then
		for _, obj in pairs(player.Character:GetChildren()) do
			if obj:GetAttribute("StorageItemId") == id then
				modColorsLibrary.ApplyAppearance(obj, storageItem.Values);
			end
		end
	end

	debounceCache[player.Name]=nil;
end)

function remoteTweakItem.OnServerInvoke(player, interactPart, action, ...)
	if debounceCache[player.Name] and tick()-debounceCache[player.Name]<0.2 then return modWorkbenchLibrary.PurchaseReplies.TooFrequentRequest end;
	debounceCache[player.Name]=tick();
	if not IsInWorkbenchRange(player, interactPart) then return modWorkbenchLibrary.PurchaseReplies.TooFar; end;
	local profile = modProfile:Get(player);
	
	if profile == nil then return modWorkbenchLibrary.PurchaseReplies.Failed; end;
	
	local playerSave = profile:GetActiveSave();
	if playerSave == nil then return modWorkbenchLibrary.PurchaseReplies.Failed; end;
	
	local inventory = profile.ActiveInventory;
	local id = ...;
	local storageItem = inventory ~= nil and inventory:Find(id) or nil;
	
	if storageItem == nil then return modWorkbenchLibrary.PurchaseReplies.Failed; end;
	
	if action <= 2 then
		-- Tweak System 1
		if action == 1 then -- MARK: Tweak with TweakPoints;
			if playerSave:GetStat("TweakPoints") <= 0 then return modWorkbenchLibrary.PurchaseReplies.InsufficientCurrency; end;
			playerSave:AddStat("TweakPoints", -1);
			shared.Notify(player, "A tweak point has been consumed.", "Reward");
			modAnalytics.RecordResource(player.UserId, 1, "Sink", "TweakPoints", "Gameplay", "Tweak Item");
			
			modAnalyticsService:Sink{
				Player=player;
				Currency=modAnalyticsService.Currency.TweakPoints;
				Amount=1;
				EndBalance=playerSave:GetStat("TweakPoints");
				ItemSKU="TweakItem";
			};

		elseif action == 2 then -- MARK: Tweak with Perks;
			if playerSave:GetStat("Perks") >= 20 then
				playerSave:AddStat("Perks", -20);
				shared.Notify(player, "20 perks has been consumed.", "Reward");
				modAnalytics.RecordResource(player.UserId, 20, "Sink", "Perks", "Gameplay", "Tweak Item");
				
				modAnalyticsService:Sink{
					Player=player;
					Currency=modAnalyticsService.Currency.Perks;
					Amount=20;
					EndBalance=playerSave:GetStat("Perks");
					ItemSKU="TweakItem";
				};

			else
				return modWorkbenchLibrary.PurchaseReplies.InsufficientCurrency;
			end
		end

		modToolTweaks.Generate(player, storageItem);

		local traitInfo = modToolTweaks.LoadTrait(storageItem.ItemId, storageItem.Values.Tweak);
		if traitInfo.Title == "Nekronomical" then
			playerSave:AwardAchievement("nekron");
		end

		profile:AddPlayPoints(10, "Gameplay:Workbench");

		--inventory:SyncValues(id, "Tweak");
		storageItem:Sync({"Tweak"});
		
	else
		
		if action == 8 then -- debug;
			Debugger:Warn("Debug 8");
			if storageItem.Values.Tweak == nil then
				Debugger:Warn("No tweak seed");
			else
				if storageItem.Values.TweakPivot == nil then -- missing tweak pivot
					local traitInfo = modToolTweaks.LoadTrait(storageItem.ItemId, storageItem.Values.Tweak);
					Debugger:Warn("traitInfo", traitInfo);
				end
			end
			
		elseif action == 3 then -- MARK: Start Tweak
			local startTarget = 0.2;
			local rerollTp = false;
			
			if storageItem.Values.Tweak == nil then
				modToolTweaks.Generate(player, storageItem);
			else
				
				if storageItem.Values.TweakPivot == nil or storageItem.Values.TF1 == nil then
					local traitInfo = modToolTweaks.LoadTrait(storageItem.ItemId, storageItem.Values.Tweak);

					startTarget = (traitInfo.Tier-1) * 0.2;
					rerollTp = true;
					
				end
			end
			storageItem.Values.TF1 = true;
			
			local tweakSeed = storageItem.Values.Tweak;
			local graphData = modToolTweaks.LoadGraph(tweakSeed);
			
			if storageItem.Values.TweakPivot then
				local tweakValues = modToolTweaks.GetValuesFromGraph(graphData, storageItem.Values.TweakPivot);
				if #tweakValues >= 5 then
					rerollTp = false;
				end
			end
			
			if storageItem.Values.TweakPivot == nil or rerollTp then
				local loopCount = 0;
				local lowPickIndex = nil;
				local tier0Index = nil;

				repeat
					local index = math.random(1, #graphData);
					local pick = graphData[index];
					if math.abs(pick.Value) <= 5 then
						tier0Index = index;
					end
					local v = math.abs(pick.Value)/100;
					if v-0.1 <= startTarget and v >= startTarget-0.1 then
						lowPickIndex = index;
					end

					--Debugger:Warn("v",v, "lowPickIndex", lowPickIndex, "tier0Index", tier0Index);
					loopCount = loopCount +1;
				until lowPickIndex ~= nil or loopCount > 64;

				if lowPickIndex == nil then
					for a=1, #graphData do
						local pick = graphData[a];
						local v = math.abs(pick.Value)/100;
						if v <= startTarget and v >= startTarget-0.1 then
							lowPickIndex = a;
						end
					end
					if lowPickIndex == nil then
						lowPickIndex = tier0Index;
					end
				end
				
				storageItem.Values.TweakPivot = math.clamp((lowPickIndex/#graphData), 0.1, 0.9);
			end

			local tweakValues = modToolTweaks.GetValuesFromGraph(graphData, storageItem.Values.TweakPivot);
			storageItem.Values.TweakValues = tweakValues;
			
			if #tweakValues >= 5 then
				playerSave:AwardAchievement("nekron");
			end

			--inventory:SyncValues(id, "TweakValues");
			--inventory:SyncValues(id, "Tweak");
			--inventory:SyncValues(id, "TweakPivot");

			storageItem:Sync({"TweakValues"; "Tweak"; "TweakPivot";});
			
			
			profile:AddPlayPoints(10, "Gameplay:Workbench");
			
		elseif action == 4 then -- MARK: Tweak
			if storageItem.Values.Tweak == nil then return modWorkbenchLibrary.PurchaseReplies.Failed; end;
			
			local _, sliderValue = ...;
			
			if sliderValue == nil then return modWorkbenchLibrary.PurchaseReplies.Failed; end;
			
			sliderValue = math.clamp(sliderValue, -4, 4);
			
			storageItem.Values.TweakPivot = storageItem.Values.TweakPivot 
				+ 0.001*sliderValue 
				+ math.sign(sliderValue) * (math.random(1, 999)/1000000);
			
			if storageItem.Values.TweakPivot >= 1 then
				storageItem.Values.TweakPivot = 0.001;
			elseif storageItem.Values.TweakPivot <= 0 then
				storageItem.Values.TweakPivot = 0.999;
			end

			local tweakSeed = storageItem.Values.Tweak;
			local graphData = modToolTweaks.LoadGraph(tweakSeed);
			
			local tweakValues = modToolTweaks.GetValuesFromGraph(graphData, storageItem.Values.TweakPivot);
			storageItem.Values.TweakValues = tweakValues;
			
			if #tweakValues >= 5 then
				playerSave:AwardAchievement("nekron");
			end
			
			--inventory:SyncValues(id, "TweakValues");
			--inventory:SyncValues(id, "TweakPivot");
			storageItem:Sync({"TweakValues"; "TweakPivot";})
			
		elseif action == 5 then -- MARK: Calibrate
			
			local tweakPoints = playerSave:GetStat("TweakPoints");
			if tweakPoints <= 0 then return modWorkbenchLibrary.PurchaseReplies.InsufficientCurrency; end;
			playerSave:AddStat("TweakPoints", -1);

			local tweakSeed = storageItem.Values.Tweak;
			local graphData = modToolTweaks.LoadGraph(tweakSeed);
			
			local nekroIndex = 1;
			local function getNekroSign()
				for a=1, #graphData do
					local pick = graphData[a];
					local v = math.abs(pick.Value)/100;
					if v >= 0.9 then
						nekroIndex = a;
						break;
					end
				end
				
				local sign = (storageItem.Values.TweakPivot > math.clamp((nekroIndex/#graphData), 0.1, 0.9)) and -1 or 1;
				return sign;
			end
			
			if math.random(1, 600) == 1 then
				return modWorkbenchLibrary.PurchaseReplies.Success, 7 * getNekroSign(), (tweakPoints-1);

			elseif math.random(1, 300) == 1 then
				return modWorkbenchLibrary.PurchaseReplies.Success, 6 * getNekroSign(), (tweakPoints-1);
				
			elseif math.random(1, 100) == 1 then
				return modWorkbenchLibrary.PurchaseReplies.Success, 5 * getNekroSign(), (tweakPoints-1);

			elseif math.random(1, 50) == 1 then
				return modWorkbenchLibrary.PurchaseReplies.Success, 4 * getNekroSign(), (tweakPoints-1);
				
			end
			
			return modWorkbenchLibrary.PurchaseReplies.Success, (math.random(1, 4) * (math.random(0, 1) == 1 and 1 or -1)), (tweakPoints-1);
			
		end
		
	end
	
	return modWorkbenchLibrary.PurchaseReplies.Success, storageItem.Values;
end


function remoteDeconstruct.OnServerInvoke(player, interactPart, action, arg)
	if debounceCache[player.Name] and tick()-debounceCache[player.Name]<0.5 then return modWorkbenchLibrary.DeconstructModReplies.TooFrequentRequest end;
	debounceCache[player.Name]=tick();
	
	if not IsInWorkbenchRange(player, interactPart) then return modWorkbenchLibrary.DeconstructModReplies.TooFar; end;
	
	local profile = modProfile:Get(player);
	local playerSave = profile:GetActiveSave();
	local inventory = profile.ActiveInventory;
	local userWorkbench = playerSave.Workbench;
	
	if action == 1 then -- MARK: Start deconstruction
		local storageItemId = arg;
		local storageItem = inventory ~= nil and inventory:Find(storageItemId) or nil;
		local itemLib = storageItem and modItemsLibrary:Find(storageItem.ItemId) or nil;
		local modLib = storageItem and modModsLibrary.Get(storageItem.ItemId) or nil;
		
		local storageOfItem = modStorage.Get(storageItemId, player);
		if storageOfItem and storageOfItem:Loop() > 0 then
			Debugger:WarnClient(player, "Can not deconstruct item with mods.");
			return modWorkbenchLibrary.DeconstructModReplies.HasMods;
		end
		
		if itemLib then
			local itemId = storageItem.ItemId;
			if not userWorkbench:CanNewProcess() then return modWorkbenchLibrary.DeconstructModReplies.BenchFull end;
			
			if itemLib.Type == modItemsLibrary.Types.Mod and modLib then
				local perks, isMaxed = modWorkbenchLibrary.CalculatePerksSpent(storageItem, modLib, profile.Premium);
				inventory:Remove(storageItemId, 1, function()
					shared.Notify(player, string.gsub("$Item removed from your Inventory.", "$Item", storageItem.CustomName), "Negative");
				end);
				
				local duration = modSyncTime.GetTime()+900;
				if modBranchConfigs.CurrentBranch.Name == "Dev" then duration = modSyncTime.GetTime()+5; end;
				
				playerSave.Workbench:NewProcess{
					Type=playerSave.Workbench.ProcessTypes.DeconstructMod;
					ItemId=modLib.Id;
					T=duration;
					Perks=perks;
					Maxed=isMaxed;
					Values=storageItem.Values;

					PlayProcessSound=true;
				};
				
				profile:AddPlayPoints(10, "Gameplay:Workbench");
				
				return modWorkbenchLibrary.DeconstructModReplies.Success;
				
			elseif modWeapons[itemId] then
				local levels = storageItem.Values and storageItem.Values.L or 0;
				if levels < 5 then return modWorkbenchLibrary.DeconstructModReplies.InvalidItem; end
				
				--local rewardTiers = math.floor(levels/5);
				local duration = modSyncTime.GetTime()+60;
				if modBranchConfigs.CurrentBranch.Name == "Dev" then duration = modSyncTime.GetTime()+5; end;
				
				playerSave.Workbench:NewProcess{
					Type=playerSave.Workbench.ProcessTypes.DeconstructWeapon;
					ItemId=itemId;
					T=duration;
					Levels=levels;
					Values=storageItem.Values;
					ItemName=storageItem.CustomName;

					PlayProcessSound=true;
				};
				profile:AddPlayPoints(10, "Gameplay:Workbench");
				
				inventory:Remove(storageItemId, 1, function()
					shared.Notify(player, string.gsub("$Item removed from your Inventory.", "$Item", storageItem.Name), "Negative");
				end);
				
				return modWorkbenchLibrary.DeconstructModReplies.Success;
			else
				return modWorkbenchLibrary.DeconstructModReplies.InvalidItem;
			end
		else
			return modWorkbenchLibrary.DeconstructModReplies.InvalidItem;
		end
		
	elseif action == 2 then -- MARK: Claim deconstruction
		local index = arg;
		local processData = userWorkbench:GetProcess(index);
		if processData.T-modSyncTime.GetTime() > 0 then return modWorkbenchLibrary.DeconstructModReplies.TooFrequentRequest end;
		
		local itemId = processData.ItemId;
		local itemLib = modItemsLibrary:Find(itemId);
		
		if processData.Type == playerSave.Workbench.ProcessTypes.DeconstructMod then
			-- DeconstructMod
			local perks = processData.Perks;
			
			if perks > 0 then
				if playerSave.Stats.Perks >= modGlobalVars.MaxPerks then
					shared.Notify(player, "You perks is maxed!", "Negative");
					
				else
					playerSave:AddStat("Perks", perks);
					if processData.Maxed then playerSave:AwardAchievement("thedec"); end
					shared.Notify(player, (("You recieved $p Perks from deconstructing $name."):gsub("$p", perks):gsub("$name", itemLib.Name)), "Reward");
					
					modAnalyticsService:Source{
						Player=player;
						Currency=modAnalyticsService.Currency.Perks;
						Amount=perks;
						EndBalance=playerSave:GetStat("Perks");
						ItemSKU="DeconstructMod";
					};
				end
				
			end
			userWorkbench:RemoveProcess(index);
			return modWorkbenchLibrary.DeconstructModReplies.Success;
			
		elseif processData.Type == playerSave.Workbench.ProcessTypes.DeconstructWeapon then
			-- DeconstructWeapon
			local levels = processData.Levels;
			local rewardTiers = math.floor(levels/5);
			local itemName = itemLib.Name;
			local values = processData.Values;
			local customName = processData.ItemName;
			
			if not inventory:SpaceCheck{{ItemId=itemId; Data={Quantity=1};}} then return modWorkbenchLibrary.BlueprintReplies.InventoryFull; end

			values.L = nil;
			values.E = nil;
			values.EG = 0;
			values.OwnersList = nil;
			values.Owner = nil;
			values.IsEquipped = nil;
			
			inventory:Add(itemId, {Values=values}, function(event, newStorageItem)
				shared.Notify(player, "Your "..itemName.." has completed deconstructing.", "Reward");
				
				newStorageItem.CustomName = customName;
				inventory:Filter(newStorageItem.ID);
				newStorageItem:Sync();
			end);
			
			if rewardTiers >= 4 then

				if playerSave.Stats.TweakPoints >= modGlobalVars.MaxTweakPoints then
					shared.Notify(player, "You TweakPoints is maxed!", "Negative");
					
				else
					playerSave:AddStat("TweakPoints", 5);
					shared.Notify(player, "You recieved 5 Tweak Point from deconstructing a level "..levels.." "..itemName..".", "Reward");
					modAnalytics.RecordResource(player.UserId, 5, "Source", "TweakPoints", "Gameplay", "Deconstruct");

					modAnalyticsService:Source{
						Player=player;
						Currency=modAnalyticsService.Currency.TweakPoints;
						Amount=5;
						EndBalance=playerSave:GetStat("TweakPoints");
						ItemSKU="Deconstruct";
					};
					
				end
			end
			if rewardTiers >= 3 then
				if playerSave.Stats.Perks >= modGlobalVars.MaxPerks then
					shared.Notify(player, "You Perks is maxed!", "Negative");
					
				else
					playerSave:AddStat("Perks", 25);
					shared.Notify(player, "You recieved 25 Perks from deconstructing a level "..levels.." "..itemName..".", "Reward");
					modAnalytics.RecordResource(player.UserId, 25, "Source", "Perks", "Gameplay", "Deconstruct");
					
					modAnalyticsService:Source{
						Player=player;
						Currency=modAnalyticsService.Currency.Perks;
						Amount=25;
						EndBalance=playerSave:GetStat("Perks");
						ItemSKU="DeconstructWeapon";
					};

				end
				
				
			elseif rewardTiers >= 1 then
				if playerSave.Stats.Money >= modGlobalVars.MaxMoney then
					shared.Notify(player, "You Money is maxed!", "Negative");
					
				else
					playerSave:AddStat("Money", 5000);
					shared.Notify(player, "You recieved $5000 from deconstructing a level "..levels.." "..itemName..".", "Reward");
					modAnalytics.RecordResource(player.UserId, 5000, "Source", "Money", "Gameplay", "Deconstruct");
					
					modAnalyticsService:Source{
						Player=player;
						Currency=modAnalyticsService.Currency.Money;
						Amount=5000;
						EndBalance=playerSave:GetStat("Money");
						ItemSKU="Deconstruct";
					};

				end
				
				
			end
			if rewardTiers >= 2 then
				if playerSave.Stats.Money >= modGlobalVars.MaxMoney then
					shared.Notify(player, "You Money is maxed!", "Negative");
					
				else
					playerSave:AddStat("Money", 25000, true);
					shared.Notify(player, "You recieved $25'000 from deconstructing a level "..levels.." "..itemName..".", "Reward");
					modAnalytics.RecordResource(player.UserId, 25000, "Source", "Money", "Gameplay", "Deconstruct");
					
					modAnalyticsService:Source{
						Player=player;
						Currency=modAnalyticsService.Currency.Money;
						Amount=25000;
						EndBalance=playerSave:GetStat("Money");
						ItemSKU="Deconstruct";
					};


				end
			end
			
			userWorkbench:RemoveProcess(index);
			profile:AddPlayPoints(10, "Gameplay:Workbench");
			return modWorkbenchLibrary.DeconstructModReplies.Success;
		end
		
	elseif action == 3 then -- MARK: Cancel deconstruction
		local index = arg;
		local processData = userWorkbench:GetProcess(index);
		
		if processData.Type == playerSave.Workbench.ProcessTypes.DeconstructMod
			or processData.Type == playerSave.Workbench.ProcessTypes.DeconstructWeapon then

			if inventory:SpaceCheck{{ItemId=processData.ItemId; Data={Quantity=1;};}} then
				local productLib = modItemsLibrary:Find(processData.ItemId);
				inventory:Add(processData.ItemId, {Quantity=1; Values=processData.Values}, function(event, insert)
					if processData.ItemName then
						insert.Name = processData.ItemName;
					end
					shared.Notify(player, ("You recieved a $Item."):gsub("$Item", productLib.Name), "Reward");
				end);
				userWorkbench:RemoveProcess(index);
				
				return modWorkbenchLibrary.DeconstructModReplies.Success;
				
			else
				return modWorkbenchLibrary.DeconstructModReplies.InventoryFull;
				
			end
		end
	end
	
	debounceCache[player.Name]=nil;
	return;
end

function remotePolishTool.OnServerInvoke(player, interactPart, action, arg)
	if debounceCache[player.Name] and tick()-debounceCache[player.Name]<0.5 then return modWorkbenchLibrary.PolishToolReplies.TooFrequentRequest end;
	debounceCache[player.Name]=tick();
	if not IsInWorkbenchRange(player, interactPart) then return modWorkbenchLibrary.PolishToolReplies.TooFar; end;
	
	local profile = modProfile:Get(player);
	local playerSave = profile:GetActiveSave();
	local inventory = profile.ActiveInventory;
	local userWorkbench = playerSave.Workbench;

	if action == 1 then -- MARK: Start polish
		local storageItemId = arg;
		local storageItem = inventory ~= nil and inventory:Find(storageItemId) or nil;
		local itemLib = storageItem and modItemsLibrary:Find(storageItem.ItemId) or nil;
		
		local storageOfItem = modStorage.Get(storageItemId, player);
		if storageOfItem and storageOfItem:Loop() > 0 then
			Debugger:WarnClient(player, "Can not polish item with mods.");
			return modWorkbenchLibrary.PolishToolReplies.HasMods;
		end

		if itemLib then
			local itemId = storageItem.ItemId;
			if not userWorkbench:CanNewProcess() then return modWorkbenchLibrary.PolishToolReplies.BenchFull end;
			
			local itemValues = storageItem.Values;
			
			if itemValues.SkinWearId == nil then
				return modWorkbenchLibrary.PolishToolReplies.InvalidItem;
			end
			
			local lmqId = "liquidmetalpolish";
			local total, itemList = inventory:ListQuantity(lmqId, 1);
			if itemList == nil or total <= 0 then
				shared.Notify(player, "Unable to find Liquid Metal Polish from inventory.", "Negative");
				return modWorkbenchLibrary.PolishToolReplies.InsufficientResources;
			end

			for a=1, #itemList do
				inventory:Remove(itemList[a].ID, itemList[a].Quantity);
				shared.Notify(player, "Liquid Metal Polish removed from your Inventory.", "Negative");

			end
			
			local duration = modSyncTime.GetTime() + modWorkbenchLibrary.PolishDuration;
			
			local newSeed, changeFloat = modItemSkinWear.PolishTool(storageItem);
			
			playerSave.Workbench:NewProcess{
				Type=playerSave.Workbench.ProcessTypes.PolishItem;
				ItemId=itemId;
				T=duration;
				Values=storageItem.Values;
				ItemName=storageItem.CustomName;
				
				ChangeFloat=changeFloat;
				NewSeed=newSeed;
				
				PlayProcessSound=true;
			};
			profile:AddPlayPoints(30, "Gameplay:Workbench");

			inventory:Remove(storageItemId, 1, function()
				shared.Notify(player, string.gsub("$Item removed from your Inventory.", "$Item", storageItem.Name), "Negative");
			end);

			return modWorkbenchLibrary.PolishToolReplies.Success;
			
		else
			return modWorkbenchLibrary.PolishToolReplies.InvalidItem;
		end

	elseif action == 2 then -- MARK: Claim polished
		local index = arg;
		local processData = userWorkbench:GetProcess(index);
		if processData.T-modSyncTime.GetTime() > 0 then return modWorkbenchLibrary.PolishToolReplies.TooFrequentRequest end;

		local itemId = processData.ItemId;
		local itemLib = modItemsLibrary:Find(itemId);
		
		if processData.Type == playerSave.Workbench.ProcessTypes.PolishItem then
			
			local itemName = itemLib.Name;
			local values = processData.Values;
			local customName = processData.ItemName;
			
			local spaceCheckPacket = {
				{ItemId=itemId; Data={Quantity=1};};
			};
			
			local polishSuccessful = processData.ChangeFloat < 0;
			
			if not polishSuccessful then
				table.insert(spaceCheckPacket, {
					ItemId="liquidmetalpolish"; Data={Quantity=1};
				})
			end
			
			if not inventory:SpaceCheck(spaceCheckPacket) then return modWorkbenchLibrary.BlueprintReplies.InventoryFull; end
			
			values.TimesPolished = (values.TimesPolished or 0) +1
			values.IsEquipped = nil;
			values.SkinWearId = processData.NewSeed;
			
			inventory:Add(itemId, {Values=values}, function(event, newStorageItem)
				if polishSuccessful then
					local percent = math.round(math.abs(processData.ChangeFloat) * 1000)/10;
					shared.Notify(player, "Your "..itemName.." has been polished by ".. percent .."%.", "Reward");
					
				else
					shared.Notify(player, "Polishing "..itemName.." has been unsuccessful.\nYou recieved a Liquid Metal Polish.", "Reward");
					inventory:Add("liquidmetalpolish");
					
				end

				newStorageItem.CustomName = customName;
				inventory:Filter(newStorageItem.ID);
				newStorageItem:Sync();
			end);

			userWorkbench:RemoveProcess(index);
			profile:AddPlayPoints(10, "Gameplay:Workbench");
			return modWorkbenchLibrary.PolishToolReplies.Success;
		end

	elseif action == 3 then -- MARK: Cancel polish
		local index = arg;
		local processData = userWorkbench:GetProcess(index);

		if processData.Type == playerSave.Workbench.ProcessTypes.PolishItem then
			if inventory:SpaceCheck{{ItemId=processData.ItemId; Data={Quantity=1;};}} then
				if inventory:SpaceCheck{{ItemId="liquidmetalpolish"; Data={Quantity=1;};}} then
					local customName = processData.ItemName;
					local productLib = modItemsLibrary:Find(processData.ItemId);
					inventory:Add(processData.ItemId, {Quantity=1; Values=processData.Values}, function(event, newStorageItem)
						newStorageItem.CustomName = customName;
						inventory:Filter(newStorageItem.ID);
						shared.Notify(player, ("You recieved a $Item."):gsub("$Item", productLib.Name), "Reward");
					end);

					inventory:Add("liquidmetalpolish", {Quantity=1;}, function(event, insert)
						shared.Notify(player, "You recieved a Liquid Metal Polish.", "Reward");
					end);
					
					userWorkbench:RemoveProcess(index);
					return modWorkbenchLibrary.PolishToolReplies.Success;
				else
					return modWorkbenchLibrary.PolishToolReplies.InventoryFull;
				end
			else
				return modWorkbenchLibrary.PolishToolReplies.InventoryFull;
			end
		end

	elseif action == 4 then -- MARK: Skip polish

		local index = arg;
		local processData = userWorkbench:GetProcess(index);
		if processData.T-modSyncTime.GetTime() <= 5 then return modWorkbenchLibrary.PolishToolReplies.TooFrequentRequest end;

		local skipCost = modWorkbenchLibrary.GetSkipCost(processData.T-modSyncTime.GetTime());
		
		if playerSave:GetStat("Perks") < skipCost then
			return modWorkbenchLibrary.PolishToolReplies.InsufficientPerks;
		end
		
		playerSave:AddStat("Perks", -skipCost);

		modAnalytics.RecordResource(player.UserId, skipCost, "Sink", "Perks", "Gameplay", "SkipPolish");
		modAnalyticsService:Sink{
			Player=player;
			Currency=modAnalyticsService.Currency.Perks;
			Amount=skipCost;
			EndBalance=playerSave:GetStat("Perks");
			ItemSKU="SkipPolish";
		};

		processData.T = modSyncTime.GetTime()-1;
		userWorkbench:Sync();
		
		return modWorkbenchLibrary.PolishToolReplies.Success;
	end

	debounceCache[player.Name]=nil;

	return;
end
