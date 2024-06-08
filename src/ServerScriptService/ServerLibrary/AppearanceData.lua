local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modPlayers = require(game.ReplicatedStorage.Library.Players);
local modAppearanceLibrary = require(game.ReplicatedStorage.Library.AppearanceLibrary);
local modCustomizeAppearance = require(game.ReplicatedStorage.Library.CustomizeAppearance);
local modClothingLibrary = require(game.ReplicatedStorage.Library.ClothingLibrary);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modItemUnlockablesLibrary = require(game.ReplicatedStorage.Library.ItemUnlockablesLibrary);
local modStatusEffects = require(game.ReplicatedStorage.Library.StatusEffects);

local modPrefabManager = require(game.ServerScriptService.ServerLibrary.PrefabManager);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);

--== Variables;
local AppearanceData = {};
AppearanceData.__index = AppearanceData;

local remoteBodyEquipmentsSync = modRemotesManager:Get("BodyEquipmentsSync");

--== Script;
function AppearanceData.new(player, saveData)
	local meta = {};
	meta.__index = meta;
	meta.Player = player;
	meta.SaveData = saveData;
	
	local self = {
		Equipped={};	
	};
	
	setmetatable(meta, AppearanceData);
	setmetatable(self, meta);
	return self;
end

function AppearanceData:Update(storage)
	local modProfile = shared.modProfile;
	local profile = modProfile:Get(self.Player);
	local classPlayer = modPlayers.Get(self.Player);
	local bodyEquipmentsTable = {
		ActiveProperties = {};
	};
	
	local wardrobeStorage = modStorage.Get("Wardrobe", self.Player);
	
	local updated = {};
	local sortedContainer = {};
	for storageItemID, _ in pairs(storage.Container) do
		local storageItem = storage.Container[storageItemID];
		table.insert(sortedContainer, storageItem);
	end
	table.sort(sortedContainer, function(a, b) return (a.Index or 99) < (b.Index or 99) end)

	for a=1, #sortedContainer do
		local storageItem = sortedContainer[a];
		local storageItemID = storageItem.ID;
		
		local vanityItem;
		if storageItem.Vanity then
			vanityItem = wardrobeStorage:Find(storageItem.Vanity);
			if vanityItem == nil then
				storageItem:SetVanity();
				storageItem:Sync();
				
			else
				modStorage.RefreshItem(self.Player, storageItem.Vanity);
				
				storageItem.VanityItemId = vanityItem.ItemId;
				storageItem.VanitySkinId = vanityItem.Values.ActiveSkin;
				storageItem.VanityMeta = storageItem.VanitySkinId or storageItem.VanityItemId;
			end
		end
		
		local newAccessoryPrefabs;
		
		local vanityItemId = vanityItem and vanityItem.ItemId
		local finalClothingLib = modClothingLibrary:Find(vanityItemId or storageItem.ItemId);
		
		if finalClothingLib then
			local noWearTag = storageItem:GetValues("NoWear");
			if noWearTag ~= true then
				local packageId = finalClothingLib.Name;
				
				local itemUnlock = storageItem.VanitySkinId or storageItem:GetValues("ActiveSkin");
				if itemUnlock then
					local unlockableItemLib = modItemUnlockablesLibrary:Find(itemUnlock);
					
					if unlockableItemLib and unlockableItemLib.PackageId and table.find(finalClothingLib.Varients, unlockableItemLib.PackageId) then
						packageId = unlockableItemLib.PackageId;
					end
				end

				if updated[finalClothingLib.GroupName] == nil then
					updated[finalClothingLib.GroupName] = {};
				end;
				table.insert(updated[finalClothingLib.GroupName], packageId);
				
				local accessoryData = finalClothingLib.AccessoryData[packageId];
				local list = self:SetEquip(finalClothingLib.GroupName, accessoryData, storageItem);
				if list and vanityItemId == nil then
					newAccessoryPrefabs = list;
				end
				
			end
		end
		
		--== Clothing Functions
		local clothingPackage = modClothingLibrary:Find(storageItem.ItemId);
		if clothingPackage and clothingPackage.NewToolLib then
			local clothingClass = profile:GetItemClass(storageItemID);
			local _clothingClassMeta = getmetatable(clothingClass);

			local maxHealth = storageItem:GetValues("MaxHealth");
			if maxHealth ~= nil and (storageItem:GetValues("Health") or maxHealth) <= 0 then
				continue;
			end
			
			if clothingClass then
				classPlayer.ClothingPropertiesCache[storageItemID] = clothingClass;

				if clothingClass.ActiveProperties then -- Equip statuses;
					for k, v in pairs(clothingClass.ActiveProperties) do
						local newStatusTable = modGlobalVars.CloneTable(v);
						
						if modStatusEffects[k] then
							modStatusEffects[k](self.Player, newStatusTable);
						else
							classPlayer:SetProperties(k, newStatusTable);
						end
					end
				end

				for k, _ in clothingClass:GetKeys() do
					local v = clothingClass[k];
					if k == "ActiveProperties" then
						local finalValue = v;
						for propertyK, propertyV in pairs(finalValue) do
							bodyEquipmentsTable.ActiveProperties[propertyK] = propertyV;
						end

					elseif k ~= "__index" and typeof(v) ~= "function" then

						local statInfo = modClothingLibrary.StatStruct[k] or {};
						
						local currentStatVal = bodyEquipmentsTable[k];
						local finalValue = v;

						if statInfo.MergeType then
							if statInfo.MergeType == modClothingLibrary.MergeTypes.Add then
								currentStatVal = (currentStatVal or 0);
								
								finalValue = currentStatVal + v;
								
							elseif statInfo.MergeType == modClothingLibrary.MergeTypes.Multiply then
								currentStatVal = (currentStatVal or 1);
								
								finalValue = currentStatVal * v;

							elseif statInfo.MergeType == modClothingLibrary.MergeTypes.Largest then
								currentStatVal = (bodyEquipmentsTable[k] or -math.huge);
								
								if v > currentStatVal then
									finalValue = v;
								else
									finalValue = currentStatVal;
								end

							elseif statInfo.MergeType == modClothingLibrary.MergeTypes.Smallest then
								currentStatVal = (bodyEquipmentsTable[k] or math.huge);
								if v < currentStatVal then
									finalValue = v;
								else
									finalValue = currentStatVal;
								end
								
							end

						else
							if currentStatVal ~= nil then
								finalValue = currentStatVal
							end

						end

						bodyEquipmentsTable[k] = finalValue;
					end
				end

				if newAccessoryPrefabs and clothingClass.OnAccesorySpawn then
					clothingClass:OnAccesorySpawn(classPlayer, storageItem, newAccessoryPrefabs);
				end
				
				if clothingClass.OnEquip then
					clothingClass:OnEquip(classPlayer, storageItem);
					storageItem:Sync();
					
				end
				
				
			end
			
		end
	end
	
	local character = self.Player.Character;
	if character then
		for _, accessory in pairs(character:GetChildren()) do
			local storageItemID = accessory:GetAttribute("StorageItemId");
			local storageItem = storageItemID and storage.Container[storageItemID];
			
			if storageItem then
				if accessory:GetAttribute("StorageIndex") then
					accessory:SetAttribute("StorageIndex", storageItem.Index);
				end
				
				if storageItem.VanityMeta then
					modItemUnlockablesLibrary.UpdateSkin(accessory, storageItem.VanityMeta);
					
				elseif storageItem.Values and storageItem.Values.ActiveSkin then
					local itemUnlock = storageItem.VanitySkinId or storageItem:GetValues("ActiveSkin");

					local unlockableItemLib = modItemUnlockablesLibrary:Find(itemUnlock);

					if unlockableItemLib and unlockableItemLib.ItemId == storageItem.ItemId then
						modItemUnlockablesLibrary.UpdateSkin(accessory, itemUnlock);
					end

				else
					modItemUnlockablesLibrary.UpdateSkin(accessory, storageItem.ItemId);
				end
			end
			
		end
	end;
	
	classPlayer:SetProperties("BodyEquipments", bodyEquipmentsTable);
	remoteBodyEquipmentsSync:FireClient(self.Player);
	
	-- Clear unequipped statuses
	for oId, _ in pairs(classPlayer.ClothingPropertiesCache) do
		local clothingClass = classPlayer.ClothingPropertiesCache[oId];

		if clothingClass.RegisteredProperties then
			for k, v in pairs(clothingClass.RegisteredProperties) do
				if storage.Container[oId] then
					-- Clothing still equipped;
					if clothingClass.ActiveProperties[k] == nil then -- Active Properties no longer active; e.g. mod removable;
						classPlayer:SetProperties(k, nil);
					end

					continue;
				end; 
				
				classPlayer:SetProperties(k, nil);
			end
		end
		
		if storage.Container[oId] == nil then
			classPlayer.ClothingPropertiesCache[oId] = nil;
		end
	end
	
	for group, _ in pairs(self.Equipped) do
		local new = updated[group] or {};
		local list = self.Equipped[group] or {};
		
		for packageId, _ in pairs(list) do
			local exist = false;
			for b=1, #new do
				if packageId == new[b] then
					exist = true;
					break;
				end
			end
			
			if not exist then
				self:SetUnequip(group, packageId);
			end
		end
	end
	
	if character == nil then return end;
	
	local accessoryPrefabs = modCustomizeAppearance.RefreshIndex(character);
	
	for storageItemID, prefabsList in pairs(accessoryPrefabs) do
		local clothingClass = classPlayer.ClothingPropertiesCache[storageItemID];
		
		if clothingClass and clothingClass.RefreshPrefabs then
			clothingClass:RefreshPrefabs(storageItemID, prefabsList);
		end
	end
end

function AppearanceData:SetUnequip(group, packageId)
	if self.Equipped[group] == nil then self.Equipped[group] = {} end;
	local groupEquips = self.Equipped[group];
	groupEquips[packageId] = nil;
	
	local character = self.Player.Character;
	if character == nil then return end;
	
	modCustomizeAppearance.RemoveAccessory(character, packageId);
end

function AppearanceData:SetEquip(group, accessoryData, storageItem)
	if self.Equipped[group] == nil then self.Equipped[group] = {} end;
	local groupEquips = self.Equipped[group];
	
	assert(accessoryData, "Missiong accessoryData, maybe package is missing PackageVariant attribute.");
	local packageId = accessoryData.Name;

	local exist = groupEquips[packageId] == true;
	groupEquips[packageId] = true;
	
	if exist then return end;
	
	local prefabGroup = modAppearanceLibrary:GetPrefabGroup(group, packageId);
	if prefabGroup then
		modPrefabManager:LoadPrefab(prefabGroup, game.ReplicatedStorage.Prefabs:FindFirstChild("Cosmetics"));
	end

	local accessories = modCustomizeAppearance.LoadAccessory(accessoryData);
	
	task.spawn(function()
		local character = self.Player.Character;
		while character == nil and game.Players:IsAncestorOf(self.Player) do
			character = self.Player.Character;
			task.wait();
		end

		for a=1, #accessories do
			local accessoryPrefab = accessories[a];

			if character == nil then
				Debugger:Warn("Missing character to setequip ", group, packageId, storageItem);
				game.Debris:AddItem(accessoryPrefab, 0);
				continue;
			end;
			
			modCustomizeAppearance.AttachAccessory(character, accessoryPrefab, accessoryData, group, storageItem);
		end
	end)
	
	return accessories;
end

function AppearanceData:GetAccessories(storageItemID)
	local character = self.Player.Character;
	while character == nil and game.Players:IsAncestorOf(self.Player) do
		character = self.Player.Character;
		task.wait();
	end
	
	local list = {};
	if character == nil then return list end;
	
	for _, accessory in pairs(character:GetChildren()) do
		if accessory:GetAttribute("StorageItemId") == storageItemID then
			table.insert(list, accessory);
		end
	end
	
	return list;
end

return AppearanceData;