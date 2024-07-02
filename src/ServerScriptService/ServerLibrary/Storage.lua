local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local customNameMaxLen = 30;

--== Variables;
local HttpService = game:GetService("HttpService");
local RunService = game:GetService("RunService");
local TextService = game:GetService("TextService");

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local StorageItem = require(game.ReplicatedStorage.Library.StorageItem);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modClothingLibrary = require(game.ReplicatedStorage.Library.ClothingLibrary);
local modEventSignal = require(game.ReplicatedStorage.Library.EventSignal);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modUsableItems = require(game.ReplicatedStorage.Library.UsableItems);
local modStorageItem = require(game.ReplicatedStorage.Library.StorageItem); 

local modProfile = shared.modProfile;
local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);
local modStorageHandler = require(game.ServerScriptService.ServerLibrary.StorageHandler);

local remotes = game.ReplicatedStorage.Remotes;
local remoteStorageService = modRemotesManager:Get("StorageService");
local remoteStorageSync = modRemotesManager:Get("StorageSync");
local remoteStorageDestroy = modRemotesManager:Get("StorageDestroy");
local remoteStorageItemSync = modRemotesManager:Get("StorageItemSync");

local remoteCombine = modRemotesManager:Get("StorageCombine");
local remoteRemoveItem = modRemotesManager:Get("StorageRemoveItem");
local remoteSetSlot = modRemotesManager:Get("StorageSetSlot");
local remoteSplit = modRemotesManager:Get("StorageSplit");
local remoteSwapSlot = modRemotesManager:Get("StorageSwapSlot");
local remoteUseStorageItem = modRemotesManager:Get("UseStorageItem");
local remoteToggleClothing = modRemotesManager:Get("ToggleClothing");
local remoteItemActionHandler = modRemotesManager:Get("ItemActionHandler");
local remoteRenameItem = modRemotesManager:Get("RenameItem");

local bindServerUnequipPlayer = remotes.Inventory.ServerUnequipPlayer;

local itemHandlerModule = game.ServerScriptService.ServerLibrary.ItemHandler;

local PublicStorages = {};
local InvocationCooldown = {};

local QueueEvents = {
	Success="Success";
	Remainding="Remainding";	
	Full="Full";
	NotEnough="NotEnough";
	Missing="Missing";
}

local Storage = {
	Get=nil;
	RefreshItem=nil;
	FindIdFromStorages=nil;
};
Storage.__index = Storage;
Storage.ClassType = "Storage";
Storage.PublicStorages = PublicStorages;
Storage.RegisteredItemNames = {};

modStorageItem.Storage = Storage;
-- Global Events;
Storage.OnItemSourced = modEventSignal.new("OnItemSourced"); --Fired when player sourced an item.
Storage.OnItemSunk = modEventSignal.new("OnItemSunk"); --Fired when player sunk an item.

local random = Random.new();
local publicIdCount = 0;
--== Script;
local function newPublicID()
	publicIdCount=publicIdCount+1;
	return "s:"..publicIdCount;
end

-- !outline: Storage.new(id, name, size, owner);
function Storage.new(id, name, size, owner)
	if type(id) ~= "string" then error("Invalid storage id!"); end;
	local queue = {};
	local storageMeta = setmetatable({}, Storage);
	storageMeta.__index = storageMeta;
	storageMeta.Queue = setmetatable({}, queue);
	storageMeta.Debounce = false;
	storageMeta.OnChangeConnections = {};
	storageMeta.OnDestroyConnections = {};
	storageMeta.Player = owner;
	storageMeta.Locked = false;
	storageMeta.Initialized = false;
	storageMeta.OnChanged = modEventSignal.new("OnStorageChanged");
	storageMeta.OnAccess = modEventSignal.new("OnStorageAccess");
	storageMeta.OnItemAdded = modEventSignal.new("OnStorageItemAdded");
	storageMeta.AuthList = {};
	
	function storageMeta:SetOwner(player)
		rawset(storageMeta, "Player", player);
	end
	
	local storage = setmetatable({}, storageMeta);
	storage.Id = id;
	storage.Name = name;
	storage.Size = size;
	storage.PremiumStorage = 100;
	
	storage.Expandable = false;
	storage.LinkedStorages = {};

	storage.MaxSize = size; -- Don't make minSize because of shrink index collision
	storage.Container = {};
	storage.Settings = {
		DepositOnly=false;
		WithdrawalOnly=false;
		DestroyOnEmpty=false;
		ScaleByContent=false;
		Rental=0;
		CustomFrame=false;
	}
	storage.Values = {};
	
	storage.RentalUnlockTime = 0;
	
	storage.LastRemote = {};
	
	if owner == nil then PublicStorages[storage.Id] = storage; end
	queue.__index = queue;
	queue.flushing = false;
	
	function queue:flush(bypass)
		if bypass == nil and queue.flushing then return end;
		queue.flushing = true;
		
		if #storage.Queue > 0 and storage.Queue[1] ~= nil then
			local firstInQueue = storage.Queue[1];
			if firstInQueue.Type == 1 then -- Add;
				local function newItemToStorage(a)
					local event, insert = storage:Insert(a or firstInQueue);
					if a.Callback ~= nil then
						task.spawn(function()
							a.Callback(event, insert);
						end)
					end
				end
				
				if firstInQueue.Stackable then
					local quantityLeftover = tonumber(firstInQueue.Data.Quantity);
					local compatibleItems = storage:ListStackable(firstInQueue);
					table.sort(compatibleItems, function(A, B) return A.Index < B.Index end);
					
					for a=1, #compatibleItems do
						local compatibleItem = compatibleItems[a];
						if compatibleItem.Values.UniqueID == firstInQueue.Data.Values.UniqueID then
							local newQuantity = firstInQueue.Stackable-compatibleItem.Quantity;
							if newQuantity > 0 then
								if quantityLeftover < newQuantity  then newQuantity = quantityLeftover end;
								
								compatibleItem.Quantity = compatibleItem.Quantity + newQuantity; -- Stack item with existing.
								compatibleItem:Sync();
								
								storage.OnItemAdded:Fire(compatibleItem, newQuantity);
								
								if firstInQueue.Callback ~= nil then 
									task.spawn(function()
										firstInQueue.Callback(newQuantity == quantityLeftover and QueueEvents.Success or QueueEvents.Remainding, compatibleItem:Clone({Quantity=newQuantity;}));
									end)
								end
								
								quantityLeftover = quantityLeftover - newQuantity;
							end
						end
						if quantityLeftover <= 0 then break end;
					end
					
					-- Quantity remains but no more stackable.
					if quantityLeftover > 0 then
						local newCount = math.ceil(quantityLeftover/firstInQueue.Stackable);
						for a=1, newCount do
							local newQuantity = (quantityLeftover-firstInQueue.Stackable) <= 0 and quantityLeftover or firstInQueue.Stackable;
							local event, insert = storage:Insert({ItemId=firstInQueue.ItemId; Data={
								CustomName=firstInQueue.Data.CustomName;
								Quantity=newQuantity; 
								Values=firstInQueue.Data.Values;
							};});
							-- Insert new item;
							
							if firstInQueue.Callback ~= nil then
								task.spawn(function()
									firstInQueue.Callback(event, insert);
								end)
							end
							
							quantityLeftover = quantityLeftover - newQuantity;
						end
					end
				else
					for a=1, firstInQueue.Data.Quantity do
						-- Insert new non-stackable items.
						newItemToStorage({ItemId=firstInQueue.ItemId; Data={
							CustomName=firstInQueue.Data.CustomName;
							Values=firstInQueue.Data.Values;
						}; Callback=firstInQueue.Callback;});
					end
				end
				
			elseif firstInQueue.Type == 2 then
				local event, insert = storage:Insert(firstInQueue);
				
				if firstInQueue.Callback ~= nil then
					task.spawn(function()
						firstInQueue.Callback(event, insert);
					end)
				end
				
				
			elseif firstInQueue.Type == -1 then -- Remove;
				storage:Delete(firstInQueue.ID, firstInQueue.Quantity, firstInQueue.Callback);
				
				
			end
			table.remove(storage.Queue, 1);
		end
		if #storage.Queue > 0 and storage.Queue[1] ~= nil then
			queue:flush(true);
		else
			queue.flushing = false;
		end
		
		storage:Changed();
		storage:Sync();
	end
	
	if modStorageHandler.OnNewStorage then
		modStorageHandler:OnNewStorage(storage);
	end
	
	storageMeta.__newindex = function(self, key, value) if rawget(storage, key) == nil then storageMeta[key] = value; end; end;
	return storage;
end

local function logRemoteUse(storage, remoteId)
	pcall(function()
		table.insert(storage.LastRemote, 1, remoteId);
		if #storage.LastRemote > 6 then
			table.remove(storage.LastRemote, #storage.LastRemote);
		end
	end)
end

-- !outline: OnServerInvoke SetSlot
function remoteSetSlot.OnServerInvoke(player, storageId, id, targetData)
	if remoteSetSlot:Debounce(player) then return end;
	local storage = Storage.Get(storageId, player);
	
	if storage == nil then Debugger:Warn("Storage unknown.", storageId); return {storage:Shrink();}; end;
	if storage.Locked then Debugger:Warn("Storage (",storage.Id,") locked."); return {storage:Shrink();}; end;
	
	local targetStorage = Storage.Get(targetData.Id, player);
	if targetStorage == nil then storage:Notify("red", "Missing target storage."); return {storage:Shrink();}; end;
	if targetStorage.Locked then Debugger:Warn("Storage (",targetStorage.Id,") locked."); return {storage:Shrink();}; end;
	if targetStorage.ViewOnly then Debugger:Warn("Storage (",targetStorage.Id,") is view-only."); return {storage:Shrink();}; end;

	if storage:RentalCheck() then Debugger:Warn("Storage (",storage.Id,") rent not paid."); return {storage:Shrink();}; end;
	if targetStorage:RentalCheck() then Debugger:Warn("Storage (",targetStorage.Id,") rent not paid."); return {storage:Shrink(); targetStorage:Shrink();}; end;
	
	local storageItem = storage:Find(id);
	if storageItem == nil then storage:Notify("red", "Missing storage item."); return {storage:Shrink();}; end;
	
	local checkPacket = targetStorage:Check{
		DragStorageItem = storageItem;
		DragStorage = storage;
		TargetStorageItem = nil;
		TargetIndex = targetData.Index;
	};
	if checkPacket.Allowed == false then
		storage:Notify("red", checkPacket.FailMsg or "That item move is not allowed.");
		return {storage:Shrink();};
	end
	
	logRemoteUse(storage, "remoteSetSlot");
	return storage:SetIndex(player, id, targetData);
end

-- !outline: OnServerInvoke SwapSlot
function remoteSwapSlot.OnServerInvoke(player, storageId, itemA, itemB)
	if remoteSwapSlot:Debounce(player) then return end;
	local storageA = Storage.Get(storageId, player);
	local storageB = Storage.Get(itemB.Id, player);
	
	if storageA == nil then Debugger:Warn("StorageA unknown.", storageId); return {storageB:Shrink();}; end;
	if storageB == nil then Debugger:Warn("StorageB unknown.", storageId); return {storageA:Shrink();}; end;
	
	if storageA.Locked then Debugger:Warn("Storage (",storageA.Id,") locked."); return {storageB:Shrink();}; end;
	if storageB.Locked then Debugger:Warn("Storage (",storageB.Id,") locked."); return {storageA:Shrink();}; end;
	
	if storageA.ViewOnly then Debugger:Warn("Storage (",storageA.Id,") is view-only."); return {storageB:Shrink();}; end;
	if storageB.ViewOnly then Debugger:Warn("Storage (",storageB.Id,") is view-only."); return {storageA:Shrink();}; end;
	
	if storageA == nil then storageB:Notify("red", "Missing target storage A."); return {storageB:Shrink();}; end;
	if storageB == nil then storageA:Notify("red", "Missing target storage B."); return {storageA:Shrink();}; end;
	local storageItemA = storageA:Find(itemA.ID);
	local storageItemB = storageB:Find(itemB.ID);
	
	if storageItemA == nil then storageB:Notify("red", "Missing storage item."); return {storageB:Shrink();}; end;
	if storageItemB == nil then storageA:Notify("red", "Missing storage item."); return {storageA:Shrink();}; end;

	if storageA:RentalCheck() then Debugger:Warn("Storage (",storageA.Id,") rent not paid."); return {storageA:Shrink();}; end;
	if storageB:RentalCheck() then Debugger:Warn("Storage (",storageB.Id,") rent not paid."); return {storageB:Shrink();}; end;

	local checkPacketA = storageA:Check{
		DragStorageItem = storageItemB;
		DragStorage = storageB;
		TargetStorageItem = storageItemA;
		TargetIndex = itemA.Index;
	};
	if checkPacketA.Allowed == false then
		storageA:Notify("red", checkPacketA.FailMsg or "That item move is not allowed.");
		return {storageA:Shrink(); storageB:Shrink()};
	end

	local checkPacketB = storageB:Check{
		DragStorageItem = storageItemA;
		DragStorage = storageA;
		TargetStorageItem = storageItemB;
		TargetIndex = itemB.Index;
	};
	if checkPacketB.Allowed == false then
		storageB:Notify("red", checkPacketB.FailMsg or "That item move is not allowed.");
		return {storageA:Shrink(); storageB:Shrink()};
	end

	logRemoteUse(storageA, "remoteSwapSlot");
	return storageA:SwapIndex(player, itemA, itemB);
end

-- !outline: OnServerInvoke Combine
function remoteCombine.OnServerInvoke(player, storageId, itemA, itemB)
	if remoteCombine:Debounce(player) then return end;
	local storageA = Storage.Get(storageId, player);
	local storageB = Storage.Get(itemB.Id, player);
	
	if storageA == nil then Debugger:Warn("StorageA unknown.", storageId); return end;
	if storageB == nil then Debugger:Warn("StorageB unknown.", storageId); return end;
	
	if storageA.Locked then Debugger:Warn("Storage (",storageA.Id,") locked."); return end;
	if storageB.Locked then Debugger:Warn("Storage (",storageB.Id,") locked."); return end;
	
	if storageA.ViewOnly then Debugger:Warn("Storage (",storageA.Id,") is view-only."); return end;
	if storageB.ViewOnly then Debugger:Warn("Storage (",storageB.Id,") is view-only."); return end;
	
	if storageA == nil then storageB:Notify("red", "Missing target storage A."); return {storageB:Shrink();}; end;
	if storageB == nil then storageA:Notify("red", "Missing target storage B."); return {storageA:Shrink();}; end;
	
	local storageItemA = storageA:Find(itemA.ID);
	local storageItemB = storageB:Find(itemB.ID);
	if storageItemA == nil then storageA:Notify("red", "Missing storage item."); return {storageA:Shrink();}; end;	
	if storageItemB == nil then storageB:Notify("red", "Missing storage item."); return {storageB:Shrink();}; end;	

	if storageA:RentalCheck() then Debugger:Warn("Storage (",storageA.Id,") rent not paid."); return {storageA:Shrink();}; end;
	if storageB:RentalCheck() then Debugger:Warn("Storage (",storageB.Id,") rent not paid."); return {storageB:Shrink();}; end;

	local checkPacketA = storageA:Check{
		DragStorageItem = storageItemB;
		DragStorage = storageB;
		TargetStorageItem = storageItemA;
		TargetIndex = itemA.Index;
	};
	if checkPacketA.Allowed == false then
		storageA:Notify("red", checkPacketA.FailMsg or "That item move is not allowed.");
		return {storageA:Shrink(); storageB:Shrink()};
	end

	local checkPacketB = storageB:Check{
		DragStorageItem = storageItemA;
		DragStorage = storageA;
		TargetStorageItem = storageItemB;
		TargetIndex = itemB.Index;
	};
	if checkPacketB.Allowed == false then
		storageB:Notify("red", checkPacketB.FailMsg or "That item move is not allowed.");
		return {storageA:Shrink(); storageB:Shrink()};
	end

	logRemoteUse(storageA, "remoteCombine");
	return storageA:Combine(player, itemA, itemB);
end

-- !outline: OnServerInvoke Split 
function remoteSplit.OnServerInvoke(player, storageId, id, quantity, target)
	if remoteSplit:Debounce(player) then return end;
	local storageA = Storage.Get(storageId, player);
	local storageB = Storage.Get(target.Id, player);
	
	if storageA == nil then Debugger:Warn("StorageA unknown.", storageId); return end;
	if storageB == nil then Debugger:Warn("StorageB unknown.", storageId); return end;
	
	if storageA.Locked then Debugger:Warn("Storage (",storageA.Id,") locked."); return end;
	if storageB.Locked then Debugger:Warn("Storage (",storageB.Id,") locked."); return end;
	
	if storageA.ViewOnly then Debugger:Warn("Storage (",storageA.Id,") is view-only."); return end;
	if storageB.ViewOnly then Debugger:Warn("Storage (",storageB.Id,") is view-only."); return end;
	
	if storageB == nil then storageA:Notify("red", "Missing target storage."); return {storageA:Shrink();}; end;
	
	local storageItem = storageA:Find(id);
	if storageItem == nil then storageA:Notify("red", "Missing storage item."); return {storageA:Shrink();}; end;	

	if storageA:RentalCheck() then Debugger:Warn("Storage (",storageA.Id,") rent not paid."); return {storageA:Shrink();}; end;
	if storageB:RentalCheck() then Debugger:Warn("Storage (",storageB.Id,") rent not paid."); return {storageB:Shrink();}; end;
	
	if shared.IsNan(target.Index) then return {storageB:Shrink();} end;

	local checkPacketB = storageB:Check{
		DragStorageItem = storageItem;
		DragStorage = storageA;
		TargetStorageItem = nil;
		TargetIndex = target.Index;
	};
	if checkPacketB.Allowed == false then
		storageB:Notify("red", checkPacketB.FailMsg or "That item move is not allowed.");
		return {storageA:Shrink(); storageB:Shrink()};
	end

	logRemoteUse(storageA, "remoteSplit");
	return storageA:Split(player, id, quantity, target);
end

-- !outline: OnServerInvoke RemoveItem
function remoteRemoveItem.OnServerInvoke(player, storageId, id, quantity)
	if remoteRemoveItem:Debounce(player) then return end;
	local storage = Storage.Get(storageId, player);
	
	if storage == nil then Debugger:Warn("Storage unknown.", storageId); return end;
	
	if storage.Locked then Debugger:Warn("Storage (",storage.Id,") locked."); return end;
	
	if storage.ViewOnly then Debugger:Warn("Storage (",storage.Id,") is view-only."); return end;
	
	local storageOfItem = Storage.Get(id, player);
	if storageOfItem and storageOfItem:Loop() > 0 then
		Debugger:WarnClient(player, "Can not delete item with mods.");
		return;
	end
	
	local storageItem = storage:Find(id);
	if storageItem == nil then Debugger:Warn("StorageItem unknown."); return end;
	
	quantity = shared.IsNan(quantity) and 1 or quantity;
	quantity = math.clamp(quantity, 1, storageItem.Library.Stackable == false and 1 or storageItem.Library.Stackable);

	logRemoteUse(storage, "remoteRemoveItem");
	return storage:Remove(id, quantity);
end

-- !outline: OnServerEvent ItemActionHandler
remoteItemActionHandler.OnServerEvent:Connect(function(player, storageId, id, action, ...)
	local storage = Storage.Get(storageId, player);

	if storage == nil then Debugger:Warn("Storage (",storageId,") does not exist for remoteItemActionHandler."); return end;
	if storage.ViewOnly then Debugger:Warn("Storage (",storage.Id,") is view-only."); return end;
	
	local storageItem = storage:Find(id);
	
	if storageItem then
		Storage.RefreshItem(player, id);
		
		if action == "setfav" then
			storageItem:SetFav();
			
		elseif action == "setvanity" then
			local vanityItem = storageItem;
			local targetStorageItem = ...;
			
			local clothingStorage = Storage.Get("Clothing", player);
			local clothingItem = clothingStorage:Find(targetStorageItem);

			Storage.RefreshItem(player, clothingItem.ID);
			
			if clothingItem.Vanity == vanityItem.ID then
				clothingItem:SetVanity(nil);
				
			else
				
				if clothingItem and clothingItem.Library.Type == "Clothing" then
					local clothingLibA = modClothingLibrary:Find(clothingItem.ItemId);
					local clothingLibB = modClothingLibrary:Find(vanityItem.ItemId);

					local canSetVanity = true;

					if clothingLibB.CanVanity == false then 
						canSetVanity = false;
					end;
					if clothingLibA.GroupName ~= clothingLibB.GroupName and clothingLibB.UniversalVanity ~= true then
						canSetVanity = false;
					end
					
					if canSetVanity then
						clothingItem:SetVanity(vanityItem.ID);
					end
				end
			end

			clothingStorage.OnChanged:Fire();
			
		elseif action == "delpat" then
			storageItem:SetValues("ActiveSkin", nil);
			storageItem:Sync({"ActiveSkin"});
			
		end
		storageItem:Sync();
		
	else
		Debugger:Warn("remoteItemActionHandler.OnServerEvent: Could not find storageItem", id, storage);
	end
end)

function Storage.RefreshItem(player, storageItemID, sync)
	local storageItem, storage = Storage.FindIdFromStorages(storageItemID, player);
	if storageItem and storage then
		local itemValues = storageItem.Values;

		local itemLib = storageItem.Library;

		if itemLib.DestroyOnExpire and itemValues.Expire and workspace:GetServerTimeNow() > itemValues.Expire then
			storage:Remove(storageItemID);
			storage:Sync();
			return;
		end

		if sync == true then
			if storageItem.Changed then
				storageItem.Changed(storage);
			end
		end
	end
end

-- !outline: OnServerEvent StorageItemSync
remoteStorageItemSync.OnServerEvent:Connect(function(player, action, storageItemId)
	if action == "update" then
		Storage.RefreshItem(player, storageItemId, true);
	end
end)

-- !outline: OnServerInvoke UseStorageItem
function remoteUseStorageItem.OnServerInvoke(player, storageId, id, ...)
	if remoteUseStorageItem:Debounce(player) then return end;
	local storage = Storage.Get(storageId, player);
	
	if storage == nil then Debugger:Warn("Storage unknown.", storageId); return end;
	if storage.Locked then Debugger:Warn("Storage (",storage.Id,") locked."); return end;
	if storage.ViewOnly then Debugger:Warn("Storage (",storage.Id,") is view-only."); return end;
	
	logRemoteUse(storage, "remoteUseStorageItem");
	return storage:Use(player, id, ...);
end

-- !outline: OnServerInvoke ToggleClothing
function remoteToggleClothing.OnServerInvoke(player, storageId, id)
	if remoteToggleClothing:Debounce(player) then return end;
	local storage = Storage.Get(storageId, player);
	
	if storage == nil then Debugger:Warn("Storage unknown.", storageId); return end;
	if storage.Locked then Debugger:Warn("Storage (",storage.Id,") locked."); return end;
	if storage.ViewOnly then Debugger:Warn("Storage (",storage.Id,") is view-only."); return end;
	
	local storageItem = storage:Find(id);
	if storageItem == nil then Debugger:Warn("Use>> Item (",id,") does not exist."); return end;
	
	local noWearKey = "NoWear";
	local noWearTag = storageItem:GetValues(noWearKey);
	if noWearTag == nil then
		storageItem:SetValues(noWearKey, true);
	else
		storageItem:SetValues(noWearKey, nil);
	end
	storageItem:Sync({noWearKey});
	storage:Changed();
	
	return storageItem.Values.NoWear;
end

-- !outline: OnServerInvoke RenameItem
function remoteRenameItem.OnServerInvoke(player, action, id, customName)
	if action == nil or id == nil or customName == nil then return end;
	customName = tostring(customName):sub(1,customNameMaxLen);
	
	local filterName = shared.modAntiCheatService:Filter(customName, player, false, false);
	if type(filterName) ~= "string" then return 4 end; 
	
	if action == "test" then
		return filterName;
		
	elseif action == "set" then
		local storageItem, storage = Storage.FindIdFromStorages(id, player);
		
		if storage == nil then Debugger:Warn("Storage unknown.", action, id); return end;
		if storage.Locked then Debugger:Warn("Storage (",storage.Id,") locked."); return end;
		if storage.ViewOnly then Debugger:Warn("Storage (",storage.Id,") is view-only."); return end;
		
		if storageItem and storage then
			
			local profile = shared.modProfile:Get(player);
			local traderProfile = profile and profile.Trader;
			local playerGold = traderProfile and traderProfile.Gold;
			
			if #customName <= 0 then
				storageItem.CustomName = nil;
				storageItem:SetDisplayName(nil);
				storageItem:Sync();
				
				return 1;
				
			else
				if playerGold >= 50 then
					storageItem.CustomName = filterName;
					storage:Filter(storageItem.ID);

					traderProfile:AddGold(-50);
					modAnalytics.RecordResource(player.UserId, 50, "Sink", "Gold", "Usage", "Rename Item");
					storageItem:Sync();
					
					return 1;
					
				else
					return 2;
				end
			end
		end
	end
	return 3;	
end


-- MARK: Storage:InitStorage()
--[[
	Initialize storage when instantiated and when loaded from save.

	@returns nil
]]
function Storage:InitStorage()
	local storageId = self.Id;
	local storageValues = self.Values;

	local usableItemLib = modUsableItems:Find(storageId);
	if usableItemLib then 
		if usableItemLib.PortableStorage then
			self:ConnectCheck(function(packet)
				if usableItemLib.StorageCheck then
					packet = usableItemLib.StorageCheck(packet);
					return packet;
				end
	
				local psItemLib = modUsableItems:Find(packet.DragStorageItem.ItemId);
				if psItemLib and psItemLib.PortableStorage then
					
					packet.Allowed = false;
					packet.FailMsg = "You can't put storage("..packet.DragStorageItem.ItemId..") into another storage."
					
					return packet;
				end
	
				packet.Allowed = true;
				return packet;
			end)
		end
		
		if usableItemLib.ConnectChanged then
			self.OnChanged:Connect(usableItemLib.ConnectChanged);
		end
		
		if usableItemLib.InitStorage then
			task.spawn(usableItemLib.InitStorage, self);
		end
		
	end;

	if storageValues == nil then return end;
end

function Storage:RentalCheck()
	if self.Settings.Rental <= 0 then return false end;
	
	if modSyncTime.GetTime() <= self.RentalUnlockTime then
		return false;
	end

	self:Notify("red", "Storage rent needs to be paid: ".. self.Name);
	return true;
end

-- !outline: Storage:ConnectSort(func)
function Storage:ConnectSort(func)
	local storageMeta = getmetatable(self);
	storageMeta.CustomSort = func;
end

-- !outline: Storage:Sort()
function Storage:Sort()
	if self.CustomSort then
		self:CustomSort();
	end
end

-- !outline: Storage:ConnectCheck(func)
function Storage:ConnectCheck(func)
	local storageMeta = getmetatable(self);
	storageMeta.CustomCheck = func;
end

-- !outline: Storage:Check(packet)
function Storage:Check(packet)
	packet.TargetStorage = self;
	packet.Allowed = true;
	
	if self.CustomCheck then
		packet = self.CustomCheck(packet);
	end
	
	-- Overrule custom check;
	local dragItemLib = packet.DragStorageItem.Library;
	if dragItemLib.StorageIncludeList then
		if table.find(dragItemLib.StorageIncludeList, self.Id) == nil then
			packet.Allowed = false;
			packet.FailMsg = dragItemLib.Name.." cannot be in "..self.Name;
		end
	end
	
	return packet;
end

--[[**
	Get list of all private storages that belongs to player.
	@param player Player player
	@returns list storages
**--]]
function Storage.GetPrivateStorages(player)
	local profile = shared.modProfile:Get(player);
	local playerSave = profile and profile:GetActiveSave();
	local storages = {};
	if playerSave then
		for sId, s in pairs(playerSave.Storages) do
			storages[sId] = playerSave.Storages[sId];
		end
		storages.Inventory = playerSave.Inventory;
		storages.Clothing = playerSave.Clothing;
		storages.Wardrobe = playerSave.Wardrobe;
		

		for a=1, #storages.Inventory.LinkedStorages do
			local linkStorageInfo = storages.Inventory.LinkedStorages[a];
			local storageId = linkStorageInfo.StorageId;
			if PublicStorages[storageId] then
				storages[storageId] = PublicStorages[storageId];
			end
		end
	end
	return storages;
end


-- Storage auth
function Storage:RefreshAuth(player, duration)
	for k, v in pairs(self.AuthList) do
		if tick()-v >= 120 then
			self.AuthList[k] = nil;
		end
	end
	
	self.AuthList[player] = tick()+duration;
end

function Storage:HasAuth(player)
	local authTick = self.AuthList[player];
	if authTick and tick() <= authTick then
		return true;
	end

	if self.Virtual then
		local containerStorageItem, storage = Storage.FindIdFromStorages(self.Id, player);

		if containerStorageItem then
			return true;
		else
			Debugger:Log("Container storage (",self.Id,") does not exist for player (",player.Name,").");
		end
	end
	
	local storagePart = self.Physical;
	if storagePart and player:DistanceFromCharacter(storagePart.Position) <= 20 then
		return true;
	end
	
	return false;
end

function Storage.GetAuthorisedStorages(player)
	local storages = {};
	local storageIds = {};
	
	for storageId, storage in pairs(PublicStorages) do
		if storage:HasAuth(player) then
			storages[storageId] = storage;
			table.insert(storageIds, storageId);
		end
	end
	
	Debugger:Log("Get auth storages:", storageIds);
	return storages;
end

--[[
	Get player's storage of Id.
	@param id string Id
	@param player Player player
	@returns Storage storage
]]
function Storage.Get(id, player)
	if player == nil then 
		return PublicStorages[id] 
	end;
	
	--local playerSave = profile:GetActiveSave();
	
	--if id == "Inventory" then
	--	return playerSave and playerSave.Inventory;
		
	--elseif id == "Clothing" then
	--	return playerSave and playerSave.Clothing;
		
	--elseif id == "Wardrobe" then
	--	return playerSave and playerSave.Wardrobe;
		
	--end

	local storages = Storage.GetPrivateStorages(player); -- Player storages;
	if storages and storages[id] then
		return storages[id];
	end
	
	local profile = shared.modProfile:Get(player);
	local cacheStorages = profile:GetCacheStorages(); -- Temp storages;
	if cacheStorages and cacheStorages[id] then
		return cacheStorages[id];
	end
	
	local authStorages = Storage.GetAuthorisedStorages(player);
	if authStorages and authStorages[id] then
		return authStorages[id];
	end
	
	return nil;
end


function Storage.Validate(player, storageId, storageItemId)
	local storage = Storage.Get(storageId, player);

	local storageItem = storage:Find(storageItemId);
	if storageItem == nil then
		return false, ("Non-existing item: ".. storageItemId);
	end

	if storage.Virtual then
		local containerStorageItem, storage = Storage.FindIdFromStorages(storageId, player);

		if containerStorageItem == nil then
			return false, ("Container storage (".. storageId ..") does not exist for player (".. player.Name..").");
		end
		
	elseif storage.Physical then
		local storagePart = storage.Physical;
		
		local classPlayer = shared.modPlayers.Get(player);
		local rootCFrame = classPlayer.RootPart.CFrame;
		
		local distance = (rootCFrame.Position - storagePart.Position).Magnitude;
		if distance >= 20 then
			return false, ("Storage (".. storage.Id ..") too far from player (".. player.Name ..").")
		end
	end
	
	return true;
end

--[[
	Find item with id from storages.
	@param id string Id
	@param player Player player

	@returns StorageItem storageItem, Storage storage
]]
function Storage.FindIdFromStorages(id, player)
	local storageList = player == nil and PublicStorages or Storage.GetPrivateStorages(player);
	--Debugger:StudioWarn("FindIdFromStorages(",id,player,") storageList", storageList);
	for storageId, storage in pairs(storageList) do
		local storageItem = storage:Find(id);
		if storageItem then
			return storageItem, storage;
		end
	end
	return nil;
end

--[[
	Find item with itemId from storages.
	@param itemId string itemId
	@param player Player player

	@returns StorageItem storageItem, Storage storage
]]
function Storage.FindItemIdFromStorages(itemId, player)
	local storageList = player == nil and PublicStorages or Storage.GetPrivateStorages(player);
	if player == nil then Debugger:Log("Finding itemId(",itemId,") from public storages."); end
	for storageId, storage in pairs(storageList) do
		local storageItem = storage:FindByItemId(itemId);
		if storageItem then
			return storageItem, storage;
		end
	end
	return;
end

--[[
	List item with itemId from storages.
	@param itemId string itemId
	@param player Player player

	@returns StorageItem storageItem, Storage storage
]]
function Storage.ListItemIdFromStorages(itemId, player, customStorages)
	local storageList = player == nil and PublicStorages or Storage.GetPrivateStorages(player);
	if player == nil then Debugger:Log("Listing itemId(",itemId,") from public storages."); end
	local list = {};
	
	if customStorages then
		local profile = shared.modProfile:Get(player);
		local playerSave = profile and profile:GetActiveSave();
		
		storageList = {};
		if playerSave then
			for _, storageId in pairs(customStorages) do
				if storageId == "Inventory" then
					storageList.Inventory = playerSave.Inventory;
					
				elseif storageId == "Clothing" then
					storageList.Clothing = playerSave.Clothing;
					
				elseif storageId == "Wardrobe" then
					storageList.Wardrobe = playerSave.Wardrobe;
					
				else
					storageList[storageId] = playerSave.Storages[storageId];
					
				end
			end
		end
	end
	
	for storageId, storage in pairs(storageList) do
		local items = storage:ListByItemId(itemId);
		for a=1, #items do
			table.insert(list, {Item=items[a]; Storage=storage});
		end
	end
	return list;
end

function Storage.RemoveItemIdFromStorages(itemId, player, amount, customStorages)
	local itemsList = Storage.ListItemIdFromStorages(itemId, player, customStorages);
	
	local seperate = {};
	for a=1, #customStorages do
		local storageId = customStorages[a];
		
		seperate[storageId] = {};
		
		for b=1, #itemsList do
			if itemsList[b].Storage.Id == storageId then
				table.insert(seperate[storageId], itemsList[b]);
			end
		end
	end
	
	local removedAmt = amount;
	
	for a=1, #customStorages do
		local storageId = customStorages[a];
		
		table.sort(seperate[storageId], function(a,b) 
			return a.Item.Quantity < b.Item.Quantity; 
		end);
		
		for b=1, #seperate[storageId] do
			local tItem = seperate[storageId][b].Item;
			local tStorage = seperate[storageId][b].Storage;
			
			local tAmt = math.min(tItem.Quantity, removedAmt);
			tStorage:Remove(tItem.ID, tAmt);
			
			removedAmt = removedAmt - tAmt;
			
			if removedAmt <= 0 then
				break;
			end
		end
		if removedAmt <= 0 then
			break;
		end
	end
	
end

function Storage.FulfillList(player, list)
	local fulfill = true;
	
	local chosenList = {};
	local needList = {};
	
	for a=1, #list do
		local needItemId = list[a].ItemId;
		local needAmount = list[a].Amount;
		
		local storageItemList = Storage.ListItemIdFromStorages(needItemId, player);
		table.sort(storageItemList, function(a,b) return a.Item.Quantity < b.Item.Quantity; end);
		
		local availableTotal = 0;
		for b=1, #storageItemList do
			availableTotal = availableTotal + storageItemList[b].Item.Quantity;
		end
		
		if availableTotal >= needAmount then
			
			for b=1, #storageItemList do
				local oStorageItem = storageItemList[b].Item;
				
				if oStorageItem.Quantity >= needAmount then
					storageItemList[b].Amount = needAmount;
					table.insert(chosenList, storageItemList[b]);
					needAmount = 0;
					
				else
					storageItemList[b].Amount = oStorageItem.Quantity;
					table.insert(chosenList, storageItemList[b]);
					needAmount = needAmount - storageItemList[b].Amount;
					
				end
				if needAmount <= 0 then
					break;
				end
			end
		else
			fulfill = false;
			table.insert(needList, {ItemId=needItemId; Amount=(needAmount-availableTotal)});
		end
	end
	
	if fulfill then
		return true, chosenList;
	else
		return false, needList;
	end
end

function Storage.ConsumeList(list)
	-- {{Item=storageItem; Amount=1};}
	local syncStorages = {};
	for a=1, #list do
		if list[a].Amount == nil then Debugger:Warn("ConsumeList missing item: (",list[a].Item, ")") continue end;
		
		local storageItem = list[a].Item;
		local storage = list[a].Storage; -- or Storage.FindIdFromStorages(storageItem.ID, player)
		
		local itemLib = modItemsLibrary:Find(storageItem.ItemId);
		
		storage:Remove(storageItem.ID, list[a].Amount);
		syncStorages[storage.Id] = storage;
		
		if storage.Player then
			shared.Notify(storage.Player, (("$Amount$Item removed from ".. storage.Name ..".")
				:gsub("$Item", itemLib.Name)
				:gsub("$Amount", list[a].Amount > 1 and list[a].Amount.." " or "")), "Negative");
		end
	end
end

function Storage:SetContainerItem(storageItem)
	self.Container[storageItem.ID] = storageItem;
	storageItem:SetStorageId(self.Id);
	storageItem:UpdatePlayer(self.Player);
	self:Filter(storageItem.ID);
end

-- !outline Storage:Load(rawData)
function Storage:Load(rawData)
	if rawData == nil then error("Storage>>  Load is missing data."); end;
	for key, value in pairs(self) do
		local data = rawData[key] or self[key];
		if self[key] == nil then continue end;
		
		if key == "Container" then
			local indexClaimed = {};
			local reAddItem = {};

			for _, valueData in pairs(data) do
				local itemLib = modItemsLibrary:Find(valueData.ItemId);
				if itemLib == nil then Debugger:Warn("Failed to load (",valueData.ItemId,")"); continue end;
				
				if valueData.Values and valueData.Values.IsEquipped then
					valueData.Values.IsEquipped = nil;
				end
				if valueData.Index and indexClaimed[valueData.Index] == nil then
					if valueData.ID ~= nil then
						indexClaimed[valueData.Index] = true;
						
						if valueData.Name then
							valueData.CustomName = valueData.Name;
						end
						local storageItem = StorageItem.new(valueData.Index, valueData.ItemId, valueData, self.Player);
						self:SetContainerItem(storageItem);

					else
						table.insert(reAddItem, {ValueData=valueData; Err="1"});

					end
				else
					table.insert(reAddItem, {ValueData=valueData; Err="2"});

				end
				
			end
			for a=1, #reAddItem do
				local valueData = reAddItem[a].ValueData;
				if valueData.ItemId then
					local emptyIndex = self:FindEmpty();
					if emptyIndex then
						local storageItem = StorageItem.new(emptyIndex, valueData.ItemId, valueData, self.Player);
						if storageItem.ID == nil then storageItem.ID = 10000+random:NextInteger(1,999) end;
						storageItem:SetValues("Err", reAddItem[a].Err);
						self:SetContainerItem(storageItem);

					end
				end
			end
			
		elseif key == "Settings" then
			for sK, sV in pairs(data) do
				if self.Settings[sK] ~= nil then
					self.Settings[sK] = sV;
				end
			end
			
		else
			self[key] = data;
		end
	end
	return self;
end

function Storage:Loop(callback)
	local c=0;
	for _,storageItem in pairs(self.Container) do
		if callback then
			local r = callback(storageItem);
			if r ~= nil then break; end;
		end
		storageItem.Quantity = math.clamp(storageItem.Quantity, 1, storageItem.Library.Stackable == false and 1 or storageItem.Library.Stackable);
		c=c+1;
	end
	return c;
end

function Storage:IsEmpty(index)
	for _, storageItem in pairs(self.Container) do
		if storageItem.Index == index then
			return storageItem;
		end
	end
	return true;
end

function Storage:FindEmpty()
	local occupied = {};
	local containerSize = self:Loop(function(storageItem)
		occupied[storageItem.Index] = storageItem;
	end);
	local storageSize = (self.Settings and self.Settings.ScaleByContent and 100) or self.Size;
	if containerSize < storageSize then
		local isPremium = self.Player and shared.modProfile:IsPremium(self.Player);
		for index=1, isPremium and storageSize or self.PremiumStorage do
			if occupied[index] == nil then return index; end
		end
	end
	return nil;
end

--[[**
	Get storageItem of id.
	@param id int Id
	@returns StorageItem item
**--]]
function Storage:Find(id)
	return self.Container[id];
end

--[[**
	Get storageItem of index.
	@param index int Index
	@returns StorageItem item
**--]]
-- !outline Storage:FindByIndex
function Storage:FindByIndex(index)
	local r = nil;
	self:Loop(function(storageItem)
		 if storageItem.Index == index then
			r = self.Container[storageItem.ID];
			return r;
		end
	end)
	return r;
end

--[[
	Get storageItem of name.
	@param name string Name
	@returns StorageItem item
]]
function Storage:FindByItemId(itemId)
	local list = self:ListByItemId(itemId);
	local r = nil;
	if #list > 0 then
		table.sort(list, function(a,b) return a.Quantity > b.Quantity; end);
		r = list[1];
	end
	return r;
end

--[[
	Storage:ListStackable(matchStorageItem)
	@param matchStorageItem StorageItem
]]
function Storage:ListStackable(matchStorageItem: modStorageItem.StorageItem) : {[number]: modStorageItem.StorageItem}
	local list = {};
	self:Loop(function(loopStorageItem)
		if modStorageItem.IsStackable(matchStorageItem, loopStorageItem) then
			table.insert(list, self.Container[loopStorageItem.ID]);
		end
	end)
	return list;
end


-- !outline: Storage:ListByItemId(itemId, listFunc)
function Storage:ListByItemId(itemId, listFunc)
	local l = {};
	self:Loop(function(storageItem)
		if storageItem.ItemId == itemId and (listFunc == nil or listFunc(storageItem) == true) then
			table.insert(l, self.Container[storageItem.ID]);
		end
	end)
	return l;
end

function Storage:ListOrderedByIndex()
	local l = {};
	for _, storageItem in pairs(self.Container) do
		table.insert(l, storageItem);
	end
	table.sort(l, function(a, b) return a.Index < b.Index end);
	return l;
end


-- !outline: Storage:CountItemId(itemId, countFunc)
function Storage:CountItemId(itemId, countFunc)
	local c = 0;
	self:Loop(function(storageItem)
		if storageItem.ItemId == itemId then
			if countFunc == nil or countFunc(storageItem) == true then
				c = c + storageItem.Quantity;
			end
		end
	end)
	return c;
end

--[[**
	Creates a sorted list of items with itemId by quantity. Returns the total quantity of itemId and if it matches quantityNeeded, returns a table.
	@param itemId string ItemId
	@param quantityNeeded int The quantity needed
	@returns tuple total, table
**--]]
function Storage:ListQuantity(itemId, quantityNeeded)
	local total = 0;
	local items = {};
	local enough = false;
	local matchingItems = self:ListByItemId(itemId);
	table.sort(matchingItems, function(a,b) return a.Quantity < b.Quantity; end);
	for a=1, #matchingItems do
		local storageItem = matchingItems[a];
		if quantityNeeded ~= nil then
			local quantity = storageItem.Quantity > (quantityNeeded-total) and (quantityNeeded-total) or storageItem.Quantity;
			total = total + quantity;
			table.insert(items, {ID=storageItem.ID; Quantity=quantity});
			if total >= quantityNeeded then
				enough = true;
				break;
			end
		else
			total = total + storageItem.Quantity;
		end
	end
	return total, enough and items or nil;
end

function Storage:RemoveItemId(itemId, quantity)
	local total, itemList = self:ListQuantity(itemId, quantity);
	if itemList then
		for a=1, #itemList do
			self:Remove(itemList[a].ID, itemList[a].Quantity);
		end
		return true;
	end
	return false;
end

function Storage:GetValues(id, key)
	return self.Container[id] and self.Container[id]:GetValues(key) or nil;
end

function Storage:SetValues(id, data)
	if id == "MockStorageItem" then return end;
	
	local storageItem = self.Container[id];
	if storageItem then
		local keys = {};
		for key, value in pairs(data) do
			table.insert(keys, key);
			storageItem:SetValues(key, value);
		end
		storageItem:Sync(keys);
		
	else
		warn("SetValues>> "..self.Id.." does not contain item id: "..(id or "nil"));
	end
end

function Storage:DeleteValues(id, keys)
	if id == "MockStorageItem" then return end;

	local storageItem = self.Container[id];
	if storageItem then
		keys = type(keys) == "table" and keys or {keys};
		for a=1, #keys do
			storageItem:DeleteValues(keys[a]);
		end
		storageItem:Sync(keys);
		
	else
		warn("DeleteValues>> "..self.Id.." does not contain item id: "..(id or "nil"));
	end
end

function Storage.RegisterItemName(name)
	if table.find(Storage.RegisteredItemNames, name) ~= nil then return name end;
	table.insert(Storage.RegisteredItemNames, name);
	return name;
end

function Storage:Filter(id)
	local storageItem = self.Container[id];
	if storageItem == nil then return end;

	if storageItem.CustomName == storageItem.Library.Name then
		storageItem.CustomName = nil;
		storageItem:SetDisplayName(nil);
		return;
	end

	if table.find(Storage.RegisteredItemNames, storageItem.CustomName) ~= nil then
		storageItem:SetDisplayName(storageItem.CustomName);
		return;
	end
	
	if storageItem.CustomName then
		storageItem.CustomName = tostring(storageItem.CustomName):sub(1,customNameMaxLen);
		
		local filterName = shared.modAntiCheatService:Filter(storageItem.CustomName, self.Player, false, false);
		
		if modItemsLibrary.ItemNames[string.lower(filterName)] then
			filterName = string.rep("#", #filterName);
		end
		
		storageItem:SetDisplayName(filterName);
	end
end


function Storage:Transfer(player, packageA, packageB) -- A to B;
	local storageB = Storage.Get(packageB.Id, player);
	if storageB == nil then Debugger:Warn("Storage B does not exist."); return; end
	
	local profile = self.Player and shared.modProfile:Get(self.Player);
	if self.Id ~= storageB.Id and profile and profile.EquippedTools.ID == packageA.ID then
		bindServerUnequipPlayer:Invoke(player);
	end

	local storageItemA = self.Container[packageA.ID];
	if packageB.ID then -- Swap items
		local storageItemB = storageB.Container[packageB.ID];
		
		self:SetContainerItem(storageItemB);
		storageB:SetContainerItem(storageItemA);
		
		if self.Id ~= storageB.Id then
			self.Container[packageA.ID], storageB.Container[packageB.ID] = nil, nil;
		end
		if self.Container[packageB.ID] then
			self.Container[packageB.ID].Index = packageA.Index;
		end;
		if storageB.Container[packageA.ID] then
			storageB.Container[packageA.ID].Index = packageB.Index;
			
			if self.ItemSpawn then
				Storage.OnItemSourced:Fire(self, storageItemA, storageItemA.Quantity);
			end
		end;
		
		
	else -- Place on empty slot;
		if storageB:FindByIndex(packageB.Index) == nil then
			--storageB.Container[packageA.ID] = storageItemA;
			storageB:SetContainerItem(storageItemA);
			storageB.Container[packageA.ID].Index = packageB.Index;
			self.Container[packageA.ID] = nil;
			
			local newStorageItem = storageB.Container[packageA.ID];
			
			storageB.OnItemAdded:Fire(newStorageItem, newStorageItem.Quantity);

			if self.ItemSpawn then
				Storage.OnItemSourced:Fire(self, newStorageItem, newStorageItem.Quantity);
			end
		end
	end
	
	
	self:Changed();
	storageB:Changed();
	
	self:Sync(player);
	storageB:Sync(player);
end


--[[**
	Insert item into storage.
	@param item StorageItem item
	@param emptyIndex int index
	@returns Tuple: QueueEvents eventType, StorageItem item
**--]]
function Storage:Insert(item, emptyIndex)
	self.Debounce = true;
	
	local profile = self.Player and shared.modProfile:Get(self.Player);
	emptyIndex = emptyIndex or self:FindEmpty();
	if emptyIndex == nil then
		Debugger:Print("Storage "..self.Id.." is full to insert "..item.ItemId.."("..(item.Data and item.Data.Quantity or 1)..")!");
		self.Debounce = false;

		return QueueEvents.Full, {ItemId=item.ItemId; Quantity=0;};
	end
	
	local new;
	if item.ClassType == "StorageItem" then
		new = item:Clone();
		new.Index = emptyIndex;
	else
		new = StorageItem.new(emptyIndex, item.ItemId, item.Data, self.Player);
	end
		
	new.ID = profile and profile:NewID() or newPublicID();
	self:SetContainerItem(new);
	
	task.spawn(function()
		if profile and item then
			profile:UnlockItemCodex(item.ItemId);
		end
	end)
	
	if self.Player then
		if new.Library.SyncOnAdd then
			new:Sync();
		end
	end
	
	self:Sync();
	self:Changed();
	self.OnItemAdded:Fire(new, new.Quantity);
	
	self.Debounce = false;
	
	return QueueEvents.Success, new;
end

function Storage:SpaceCheck(items)
	local cacheContainer = {};
	
	local function listCacheItemId(itemId, itemValues)
		itemValues = itemValues or {};

		local itemLib = modItemsLibrary:Find(itemId);
		local matchingItems = self:ListStackable({
			ItemId = itemId;
			Name = itemLib.Name;
			Values = itemValues;
		});

		local list = {};
		for a=1, #matchingItems do
			local cacheItem = matchingItems[a];
			cacheContainer[cacheItem.Index] = cacheItem:Clone();
			table.insert(list, cacheContainer[cacheItem.Index]);
		end

		return list;
	end

	local function findEmpty()
		local occupied = {};
		local containerSize = self:Loop(function(storageItem)
			occupied[storageItem.Index] = storageItem;
		end);
		if containerSize < self.Size then
			local isPremium = self.Player and shared.modProfile:IsPremium(self.Player);
			for index=1, isPremium and self.Size or self.PremiumStorage do
				if occupied[index] == nil and cacheContainer[index] == nil then return index; end
			end
		end
		return nil;
	end
	
	for a=1, #items do
		local item = items[a];
		item.Data = item.Data or {};
		local itemQuantity = item.Data.Quantity or 1;
		local itemId = item.ItemId;
		local itemLib = modItemsLibrary:Find(itemId);
		
		if itemLib then
			if itemLib.Stackable then
				local quantityRemaining = itemQuantity;
				local matchingItems = listCacheItemId(itemId, item.Data.Values);
				for b=1, #matchingItems do
					local stackAvailable = itemLib.Stackable-matchingItems[b].Quantity;
					if stackAvailable > 0 then
						if quantityRemaining >= stackAvailable then
							matchingItems[b].Quantity = itemLib.Stackable;
							quantityRemaining = quantityRemaining-stackAvailable;
							
						else
							matchingItems[b].Quantity = matchingItems[b].Quantity + quantityRemaining;
							quantityRemaining = 0;
							
						end
					end
					if quantityRemaining <= 0 then break; end;
				end
				if quantityRemaining > 0 then
					repeat
						local index = findEmpty();
						if index == nil then return false; end;
						local deduction = quantityRemaining >= itemLib.Stackable and itemLib.Stackable or quantityRemaining;
						cacheContainer[index] = StorageItem.new(index, itemId, {Quantity=deduction});
						quantityRemaining = quantityRemaining - deduction;
						
					until quantityRemaining <= 0;
				end
			else
				for a=1, itemQuantity do
					local index = findEmpty();
					if index == nil then return false; end;
					
					cacheContainer[index] = StorageItem.new(index, itemId);
					
				end
			end
		else
			Debugger:Print("Itemid: ",itemId," does not exist.");
		end
	end
	
	return true;
end

function Storage:FitStackableItem(item)
	local cacheContainer = {};

	local function listCacheItemId(itemId, itemValues)
		itemValues = itemValues or {};

		local itemLib = modItemsLibrary:Find(itemId);
		local matchingItems = self:ListStackable({
			ItemId = itemId;
			Name = itemLib.Name;
			Values = itemValues;
		});

		local list = {};
		for a=1, #matchingItems do
			local cacheItem = matchingItems[a];
			cacheContainer[cacheItem.Index] = cacheItem:Clone();
			table.insert(list, cacheContainer[cacheItem.Index]);
		end
		
		return list;
	end

	local function findEmpty()
		local occupied = {};
		local containerSize = self:Loop(function(storageItem)
			occupied[storageItem.Index] = storageItem;
		end);
		if containerSize < self.Size then
			local isPremium = self.Player and shared.modProfile:IsPremium(self.Player);
			for index=1, isPremium and self.Size or self.PremiumStorage do
				if occupied[index] == nil and cacheContainer[index] == nil then return index; end
			end
		end
		return nil;
	end
	
	local fitList = {};
	
	item.Data = item.Data or {};
	local itemQuantity = item.Data.Quantity or 1;
	local itemId = item.ItemId;
	local itemLib = modItemsLibrary:Find(itemId);
	local quantityRemaining = itemQuantity;
	
	local function addFitItem(quantity)
		table.insert(fitList, {
			ItemId=itemId;
			Quantity=quantity;
		})
	end
	
	if itemLib then
		if itemLib.Stackable then
			local matchingItems = listCacheItemId(itemId, item.Data.Values);
			
			for b=1, #matchingItems do
				local stackAvailable = itemLib.Stackable-matchingItems[b].Quantity;
				if stackAvailable > 0 then
					if quantityRemaining >= stackAvailable then
						matchingItems[b].Quantity = itemLib.Stackable;
						addFitItem(stackAvailable);
						quantityRemaining = quantityRemaining-stackAvailable;
						
						
					else
						matchingItems[b].Quantity = matchingItems[b].Quantity + quantityRemaining;
						addFitItem(quantityRemaining);
						quantityRemaining = 0;

					end
				end
				if quantityRemaining <= 0 then break; end;
			end
			
			if quantityRemaining > 0 then
				repeat
					local index = findEmpty();
					if index then
						local deduction = quantityRemaining >= itemLib.Stackable and itemLib.Stackable or quantityRemaining;
						cacheContainer[index] = StorageItem.new(index, itemId, {Quantity=deduction});
						addFitItem(deduction);
						quantityRemaining = quantityRemaining - deduction;
						
					else
						break;
						
					end
				until quantityRemaining <= 0;
			end
			
			
		else
			for a=1, itemQuantity do
				local index = findEmpty();
				if index then 
					cacheContainer[index] = StorageItem.new(index, itemId);
					quantityRemaining = quantityRemaining-1;
					addFitItem();
				end;
			end
		end
	else
		Debugger:Print(itemId," does not exist.");
	end
	
	return fitList, quantityRemaining;
end

function Storage:Add(itemId, data, callback)
	data = data or {Quantity=1; Values={}};
	data.Quantity = data.Quantity or 1;
	data.Values = data.Values or {};
	
	local itemLib = modItemsLibrary:Find(itemId);
	if itemLib == nil then Debugger:StudioWarn(itemId," does not exist."); return; end;

	table.insert(self.Queue, {Type=1; ItemId=itemId; Name=itemLib.Name; Data=data; Values=data.Values; Callback=callback; Stackable=itemLib.Stackable;});
	self.Queue:flush();
end

-- !outline: Storage:Delete
function Storage:Delete(id, quantity, callback)
	local storageItem = self:Find(id);
	
	if storageItem then
		quantity = math.floor(quantity or storageItem.Quantity);
		if shared.IsNan(quantity) then quantity = 1; end
		local stackSize = storageItem.Library.Stackable or 1;
		
		if quantity <= storageItem.Quantity then
			if storageItem.Quantity > quantity then
				storageItem.Quantity = storageItem.Quantity - quantity;
				Debugger:Print("Removed -"..quantity.." of "..id.." from "..self.Id);
				storageItem:Sync();
				
				if callback then task.spawn(callback, QueueEvents.Success); end
				
			else
				Debugger:Print("Removed "..storageItem.ID.." from "..self.Id);
				self.Container[id] = nil;
				storageItem.Quantity = 0;
				storageItem:Sync();
				
				if callback then task.spawn(callback, QueueEvents.Success); end
				
			end

			if self.ItemSpawn ~= true then
				Storage.OnItemSunk:Fire(self, storageItem, quantity);
			end
			
		else
			local total, list = self:ListQuantity(storageItem.ItemId, quantity);
			Debugger:Log("Search quantity:",quantity," total:",total,". Will be removing:",list);
			
			if list then
				for a=1, #list do
					self:Delete(list[a].ID, list[a].Quantity);
				end
				if callback then task.spawn(callback, QueueEvents.Success); end
				
			else
				if callback then task.spawn(callback, QueueEvents.NotEnough); end
				
			end
		end
		
		local profile = self.Player and shared.modProfile:Get(self.Player);
		if profile and profile.EquippedTools.ID == id and self:Find(id) == nil then
			bindServerUnequipPlayer:Invoke(self.Player);
		end
		self:Changed();
		
	else
		Debugger:Print("Unable to remove non existing "..id.." from "..self.Id);
		if callback then task.spawn(callback, QueueEvents.Missing); end
		
	end
end


function Storage:InsertRequest(storageItem, ruleset)
	-- Failed; (1) Inv full;
	local rPacket = {};
	ruleset = ruleset or {};
	
	if ruleset.CancelIfCantFitAll == nil then ruleset.CancelIfCantFitAll=false; end;
	
	rPacket.StorageItem = storageItem;
	
	local itemId = storageItem.ItemId;
	local itemLib = modItemsLibrary:Find(itemId);
	
	local linkedStorages = self.LinkedStorages;
	
	if storageItem.ClassType == "StorageItem" then -- Insert unqiue items; --storageItem.ID or 
		local function findAndInsert(storage)
			local emptyIndex = storage:FindEmpty();

			if emptyIndex then
				local _, storageItem = storage:Insert(storageItem, emptyIndex);
				rPacket.Success = true;
				
				return true;
			end
			return false;
		end
		
		findAndInsert(self);
		
		if rPacket.Success ~= true then
			for a=1, #linkedStorages do
				local storageId = linkedStorages[a].StorageId;
				
				local linkedStorage = Storage.Get(storageId);
				if linkedStorage and findAndInsert(linkedStorage) then
					break;
				end
			end
			
			if rPacket.Success ~= true then
				rPacket.Failed = 1;
			end
		end
		
	else -- Insert by fitting non-unqiue items;
		
		local quantity = storageItem.Quantity or 1;
		
		local storages = {self;};

		for a=1, #linkedStorages do
			local storageId = linkedStorages[a].StorageId;

			local linkedStorage = Storage.Get(storageId);
			if linkedStorage then
				table.insert(storages, linkedStorage);
			end
		end
		
		local fitAll = false;
		local totalRemaining = quantity;
		local fitListFinal = {};
		
		for a=1, #storages do
			local storage = storages[a];

			local fitList, quantityRemaining = storage:FitStackableItem({ItemId=itemId; Data={Quantity=totalRemaining};});
			--Debugger:Log("fitList", fitList, quantityRemaining);
			totalRemaining = quantityRemaining;
			
			table.insert(fitListFinal, {
				FitList=fitList;
				Storage=storage;
			})

			if totalRemaining <= 0 then
				fitAll = true;
				break;
			end
		end
		if totalRemaining < quantity then
			rPacket.Success = true;
			
		elseif totalRemaining == quantity then
			rPacket.Failed = 1;
			
		end
		
		for a=1, #fitListFinal do
			local fitStorageList = fitListFinal[a];
			local storage = fitStorageList.Storage;
			
			for b=1, #fitStorageList.FitList do
				local fitItem = fitStorageList.FitList[b];
				
				storage:Add(fitItem.ItemId, {Quantity=fitItem.Quantity;});
			end
		end
		
		if not fitAll then
			rPacket.QuantityRemaining = totalRemaining;
		end
		
	end
	
	--Debugger:Log("rPacket", rPacket);
	
	if self.InsertRequestHandler then
		local newRPacket = self:InsertRequestHandler(rPacket);
		if newRPacket then
			rPacket = newRPacket;
		end
	end
	
	return rPacket;
end


function Storage:Notify(color, message)
	if self.Player ~= nil then
		if color == "red" then
			Debugger:Print(message);
			shared.Notify(self.Player, message, "Negative");
		elseif color == "green" then
			Debugger:Print(message);
		else
			Debugger:Print(message);
		end
	end
end

--[[**
	Set item into storage.
	@param player Player Storage owner.
	@param id string StorageItem ID.
	@param target table Target data.
	@returns compressed storage data.
**--]]
-- !outline: Storage:SetIndex
function Storage:SetIndex(player, id, target)
	local isPremium = self.Player and shared.modProfile:IsPremium(self.Player);
	local storageItem = self:Find(id);
	local targetStorage = Storage.Get(target.Id, player);
	
	if target.Index == nil or shared.IsNan(target.Index) then self:Notify("red", "Missing slot."); return {self:Shrink();}; end;
	if storageItem == nil then self:Notify("red", "Missing storage item."); return {self:Shrink();}; end;
	if targetStorage == nil then self:Notify("red", "Missing target storage."); return {self:Shrink();}; end;
	
	if targetStorage.Settings.WithdrawalOnly then self:Notify("red", "Target storage is withdrawal only."); return {self:Shrink(); (self.Id ~= targetStorage.Id and targetStorage:Shrink() or nil);}; end;
	if self.Settings.DepositOnly then self:Notify("red", "This storage is deposit only."); return {self:Shrink(); (self.Id ~= targetStorage.Id and targetStorage:Shrink() or nil);}; end;
	
	if self.Debounce then self:Notify("red", "Not ready to move item."); return {self:Shrink();}; end;
	self.Debounce = true;
	
	local targetSize = (isPremium and targetStorage.Size or targetStorage.PremiumStorage);
	if target.Index > 0 and target.Index <= targetSize then
		if storageItem then
			if self.Id == target.Id then --Move within same storage;
				local storageItemB = self:FindByIndex(target.Index);
				
				if storageItemB == nil then
					storageItem.Index = target.Index;
					self:Changed();
					self:Sync(player);
					
				else
					self.Debounce = false;
					return self:SwapIndex(player, {ID=storageItem.ID;}, {Id=self.Id; ID=storageItemB.ID;});
					
				end
				
			else -- Move to another storage;
				local storageB = Storage.Get(target.Id, player);
				if storageB then
					local storageItemB = storageB:FindByIndex(target.Index);

					if storageItem.Library.StorageWhitelist and storageItem.Library.StorageWhitelist[storageB.Id] == nil then
						self:Notify("red", "Cannot move item to storage: "..storageB.Name);
						self.Debounce = false;
						return {self:Shrink(); (self.Id ~= targetStorage.Id and targetStorage:Shrink() or nil);};
					end
					
					if storageItemB == nil then -- Empty slot;
						self:Transfer(player, {ID=id; Index=storageItem.Index}, {Player=player; Id=target.Id; Index=target.Index});
						
					else
						self.Debounce = false;
						return storageB:SwapIndex(player, {ID=storageItem.ID;}, {Id=target.Id; ID=storageItemB.ID;});
					end
				end
				
			end
		else
			self:Notify("red", "Failed to move non existing item.");
		end
	else
		self:Notify("red", "Moving item out of bounds. "..targetSize);
		Debugger:Log("Attempt to set index ",target.Index," of ",targetStorage.Id," for ",storageItem.ItemId);
	end
	
	self.Debounce = false;
	return {self:Shrink(); (self.Id ~= targetStorage.Id and targetStorage:Shrink() or nil);};
end

-- !outline: Storage:SwapIndex
function Storage:SwapIndex(player, itemA, itemB)
	local storageB = Storage.Get(itemB.Id, player);
	local storageItemA = self:Find(itemA.ID);
	local storageItemB = storageB and storageB:Find(itemB.ID);
	
	if storageItemA == nil then self:Notify("red", "Missing storage item."); return {self:Shrink();}; end;
	if storageItemB == nil then self:Notify("red", "Missing target item."); return {self:Shrink();}; end;
	if storageB == nil then self:Notify("red", "Missing target storage."); return {self:Shrink();}; end;
	
	if storageB.Settings.WithdrawalOnly then self:Notify("red", "Target storage is withdrawal only."); return {self:Shrink(); (storageB and self.Id ~= storageB.Id and storageB:Shrink() or nil);}; end;
	if storageB.Settings.DepositOnly then self:Notify("red", "Target storage is deposit only."); return {self:Shrink(); (storageB and self.Id ~= storageB.Id and storageB:Shrink() or nil);}; end;
	if self.Settings.WithdrawalOnly then self:Notify("red", "This storage is withdrawal only."); return {self:Shrink(); (storageB and self.Id ~= storageB.Id and storageB:Shrink() or nil);}; end;
	if self.Settings.DepositOnly then self:Notify("red", "This storage is deposit only."); return {self:Shrink(); (storageB and self.Id ~= storageB.Id and storageB:Shrink() or nil);}; end;

	if storageItemA.Library.StorageWhitelist and storageItemA.Library.StorageWhitelist[storageB.Id] == nil then
		self:Notify("red", "Cannot move item to storage: "..storageB.Name);
		return {self:Shrink(); (storageB and self.Id ~= storageB.Id and storageB:Shrink() or nil);};
	end
	
	if storageItemB.Library.StorageWhitelist and storageItemB.Library.StorageWhitelist[self.Id] == nil then
		self:Notify("red", "Cannot move item to storage: "..self.Name);
		return {self:Shrink(); (storageB and self.Id ~= storageB.Id and storageB:Shrink() or nil);};
	end
	
	if self.Debounce then self:Notify("red", "Failed to swap items."); return {self:Shrink();}; end;
	self.Debounce = true;
	
	self:Transfer(player, {ID=storageItemA.ID; Index=storageItemA.Index}, {Id=itemB.Id; ID=storageItemB.ID; Index=storageItemB.Index});
	
	self.Debounce = false;
	return {self:Shrink(); self.Id ~= storageB.Id and storageB:Shrink() or nil;};
end

-- !outline: Storage:Combine
function Storage:Combine(player, itemA, itemB)
	local storageB = Storage.Get(itemB.Id, player);
	
	local storageItemA = self:Find(itemA.ID);
	local storageItemB = storageB and storageB:Find(itemB.ID);
	
	if storageItemA == nil then self:Notify("red", "Missing storage item."); return {self:Shrink();}; end;
	if storageItemB == nil then self:Notify("red", "Missing target item."); return {self:Shrink();}; end;
	if storageB == nil then self:Notify("red", "Missing target storage."); return {self:Shrink();}; end;
	
	if storageItemA.ItemId ~= storageItemB.ItemId then self:Notify("red", "Failed to combine different items."); return {self:Shrink();}; end;
	
	if storageB.Settings.WithdrawalOnly then self:Notify("red", "Target storage is withdrawal only."); return {self:Shrink(); (storageB and self.Id ~= storageB.Id and storageB:Shrink() or nil);}; end;
	if storageB.Settings.DepositOnly then self:Notify("red", "Target storage is deposit only."); return {self:Shrink(); (storageB and self.Id ~= storageB.Id and storageB:Shrink() or nil);}; end;
	if self.Settings.DepositOnly then self:Notify("red", "This storage is deposit only."); return {self:Shrink(); (storageB and self.Id ~= storageB.Id and storageB:Shrink() or nil);}; end;
	
	if self.Debounce then self:Notify("red", "Not available to combine items."); return {self:Shrink();}; end;
	self.Debounce = true;
	
	if storageItemA and storageItemB and modStorageItem.IsStackable(storageItemA, storageItemB) then
			
		if storageItemB.Quantity+storageItemA.Quantity > storageItemB.Library.Stackable then
			-- Quantity transfer;
			local remainder = (storageItemB.Library.Stackable-storageItemB.Quantity);
			storageItemB.Quantity = storageItemB.Library.Stackable;
			storageItemA.Quantity = storageItemA.Quantity-remainder;
			
			if self.ItemSpawn then
				Storage.OnItemSourced:Fire(self, storageItemB, remainder); -- When item is taken from a reward crate
			end
			
		else
			-- Combine;
			storageItemB.Quantity = storageItemB.Quantity+storageItemA.Quantity;
			self:Delete(storageItemA.ID);

			if self.ItemSpawn then
				Storage.OnItemSourced:Fire(self, storageItemB, storageItemA.Quantity); -- When item is taken from a reward crate
			end
			
		end
		self:Changed();
		storageB.OnChanged:Fire(storageB);
		self:Sync(player);
		storageB:Sync(player);
	end
	self.Debounce = false;
	return {self:Shrink(); (storageB and self.Id ~= storageB.Id and storageB:Shrink() or nil);};
end

--[[**
	Add id into queue to be removed.
	@param id string id
	@param quantity Int quantity
	@param callback Function callback
	@returns table CompressedStorage
**--]]
-- !outline: Storage:Remove
function Storage:Remove(id, quantity, callback)
	local storageItem = self:Find(id);
	if storageItem == nil then
		if callback ~= nil then
			task.spawn(function()
				callback(QueueEvents.Missing);
			end)
		end
		return {self:Shrink();};
	end;
	
	quantity = math.floor(quantity or 1);
	if shared.IsNan(quantity) or quantity <= 0 then self:Notify("red", "Failed to remove item."); return {self:Shrink();}; end;
	
	table.insert(self.Queue, {Type=-1; ID=id; Stackable=storageItem.Library.Stackable; Quantity=quantity; Callback=callback;});
	
	self.Queue:flush();
	return {self:Shrink();};
end

-- !outline: Storage:Use
function Storage:Use(player, id, ...)
	if self.Locked then Debugger:Warn("Storage (",self.Id,") locked."); return end;
	local storageItem = self:Find(id);
	if storageItem == nil then Debugger:Warn("Use>> Item (",id,") does not exist."); return end;
	
	self:Changed();
	
	local itemId = storageItem.ItemId;
	local handlerModule = itemHandlerModule:FindFirstChild(itemId);
	
	local usableItemLib = modUsableItems:Find(storageItem.ItemId);
	if handlerModule == nil and usableItemLib and usableItemLib.Use then
		return usableItemLib:Use(player, storageItem, ...);
	end
	
	if handlerModule == nil then Debugger:Warn("Attempt to use (",itemId,")."); return end;
	
	local itemHandler = require(handlerModule);
	return itemHandler:Use(player, storageItem, ...);
end	

-- !outline: Storage:Split(player, id, quantity, target)
function Storage:Split(player, id, quantity, target)
	quantity = math.floor(quantity or 0);
	
	if target.Index == nil or shared.IsNan(target.Index) or shared.IsNan(quantity) or quantity <= 0 then
		self:Notify("red", "Failed to split item."); 
		return {self:Shrink();}; 
	end;
	
	local isPremium = self.Player and shared.modProfile:IsPremium(self.Player);
	local storageItem = self:Find(id);
	local storageB = Storage.Get(target.Id, player);
	
	if storageItem == nil then self:Notify("red", "Missing storage item."); return {self:Shrink();}; end;
	if storageB == nil then self:Notify("red", "Missing target storage."); return {self:Shrink();}; end;
	
	if storageB.Settings.WithdrawalOnly then self:Notify("red", "Target storage is withdrawal only."); return {self:Shrink(); (storageB and self.Id ~= storageB.Id and storageB:Shrink() or nil);}; end;
	if self.Settings.DepositOnly then self:Notify("red", "This storage is deposit only."); return {self:Shrink(); (storageB and self.Id ~= storageB.Id and storageB:Shrink() or nil);}; end;
	
	if self.Debounce then self:Notify("red", "Not ready to split item."); return {self:Shrink();}; end;
	self.Debounce = true;
	if target.Index > (isPremium and storageB.Size or storageB.PremiumStorage) then self:Notify("red", "You are not premium to put that there."); return {self:Shrink();}; end;
	
	if storageB and quantity < storageItem.Quantity then
		quantity = math.clamp(quantity, 1, storageItem.Quantity);
		
		if target.ID == nil then -- new item from split;
			storageItem.Quantity = storageItem.Quantity-quantity;
			local insertStatus, newStorageItem = storageB:Insert({ItemId=storageItem.ItemId; Stackable=true; Data={Quantity=quantity; Values=storageItem.Values};}, target.Index);

			if self.ItemSpawn and newStorageItem then
				Storage.OnItemSourced:Fire(self, newStorageItem, quantity);
			end
			
		else
			local storageItemB = storageB:Find(target.ID);
			if storageItemB and modStorageItem.IsStackable(storageItem, storageItemB) and storageItemB.Quantity+quantity <= storageItemB.Library.Stackable then
				quantity = math.clamp(quantity, 1, storageItem.Quantity);
				storageItem.Quantity = storageItem.Quantity-quantity;
				storageItemB.Quantity = storageItemB.Quantity+quantity;
				

				if self.ItemSpawn then
					Storage.OnItemSourced:Fire(self, storageItemB, quantity);
				end
				
			end
		end
		self:Sync(player);
		storageB:Sync(player);
		self:Changed();
		storageB.OnChanged:Fire(storageB);
	end
	
	self.Debounce = false;
	return {self:Shrink(); (storageB and self.Id ~= storageB.Id and storageB:Shrink() or nil);};
end

-- !outline: Storage:Changed
function Storage:Changed()
	self:Sort();
	self.OnChanged:Fire(self);
	
	local itemsCount = self:Loop();
	
	if self.Settings == nil then return end;

	if self.Settings.ScaleByContent then
		self.Size = math.max(itemsCount, self.Size);
		self.MaxSize = math.max(self.Size, self.MaxSize);
	end
	
	if self.Settings.WithdrawalOnly and self.Settings.DestroyOnEmpty then
		task.delay(0.1, function()
			itemsCount = self:Loop();
			if itemsCount <= 0 then
				self:Destroy();
			end
		end)
	end
end

-- MARK: Storage:Shrink()
function Storage:Shrink()
	local compressed = {};
	compressed.Id = self.Id;
	compressed.Name = self.Name;
	compressed.Container = {};
	compressed.Size = self.Size;
	compressed.PremiumStorage = self.PremiumStorage;
	
	compressed.Expandable = self.Expandable;
	compressed.LinkedStorages = self.LinkedStorages;
	
	compressed.MaxSize = self.MaxSize;
	
	compressed.Settings = self.Settings;
	compressed.Page = self.Page;
	compressed.MaxPages = self.MaxPages;
	compressed.Virtual = self.Virtual;
	compressed.Values = self.Values;

	compressed.RentalUnlockTime = self.RentalUnlockTime;

	for id, sI in pairs(self.Container) do
		local storageItem = sI:Shrink();

		if self.Values.HideSeeds then
			storageItem.Values.Seed = nil;
		end

		compressed.Container[id] = storageItem;
	end
	return compressed;
end

function Storage:OnDestroyConnect(func)
	table.insert(self.OnDestroyConnections, func);
end

function Storage:Destroy()
	self.Destroyed = true;
	local player, storageId = self.Player, self.Id;
	
	if player then
		local profile = shared.modProfile:Get(player);
		local playerSave = profile:GetActiveSave();

		remoteStorageDestroy:FireClient(player, storageId);
		playerSave.Storages[storageId] = nil;
		
	else
		remoteStorageDestroy:FireAllClients(storageId);
		
	end
	
	for a, _ in pairs(self.OnDestroyConnections) do
		coroutine.wrap(function()
			self.OnDestroyConnections[a](self);
			self.OnDestroyConnections[a] = nil;
		end)()
	end
	
	self.OnChanged:Destroy();
	self.OnAccess:Destroy();
	self.OnItemAdded:Destroy();
	
	self:Wipe();
	PublicStorages[self.Id] = nil;
end

function Storage:Wipe()
	table.clear(self.Container);
	self.OnChanged:Fire(self);
end

function Storage:SwapContainer(storageB)
	if self.Size ~= storageB.Size then Debugger:Warn("SwapContainer failed, size mismatch."); return end;
	local containerA = self.Container;
	local containerB = storageB.Container;

	local profile = self.Player and shared.modProfile:Get(self.Player);
	
	local cacheA = {};
	for oldId, _ in pairs(containerB) do
		local newId = profile and profile:NewID() or newPublicID();
		local storageItem = containerB[oldId];
		storageItem.ID = newId;
		storageItem:UpdatePlayer(self.Player);
		cacheA[newId] = storageItem;
	end
	rawset(self, "Container", cacheA);
	
	local cacheB = {};
	local profileB = storageB.Player and shared.modProfile:Get(storageB.Player);
	
	for oldId, _ in pairs(containerA) do
		local newId = profileB and profileB:NewID() or newPublicID();
		local storageItem = containerA[oldId];
		storageItem.ID = newId;
		storageItem:UpdatePlayer(storageB.Player);
		cacheB[newId] = storageItem;
	end
	rawset(storageB, "Container", cacheB);
end

-- !outline Storage:SyncValues
function Storage:SyncValues()
	local storage = self:Shrink();
	remoteStorageSync:FireAllClients("syncvalues", storage.Id, storage.Values);
end

-- !outline Storage:Sync
function Storage:Sync(player)
	local storage = self:Shrink();

	player = player or self.Player;
	
	if player then
		if RunService:IsStudio() then
			Debugger:Warn("[Studio] Sync Storage:",storage.Id,"(",modRemotesManager.PacketSizeCounter.GetPacketSize{PacketData={storage};},")");
		end
		remoteStorageSync:FireClient(player, "sync", storage);
	end

end

function Storage:GetIndexDictionary()
	local indexList = {};
	for id, storageItem in self.Container do
		indexList[storageItem.Index] = storageItem;
	end
	return indexList;
end

function Storage:ListByIndexOrder()
	local indexList = {};
	for id, storageItem in self.Container do
		table.insert(indexList, storageItem);
	end
	table.sort(indexList, function(a, b) return a.Index < b.Index end);
	return indexList;
end

function Storage:OpenStorage(player, storageId, storageConfig, packet)
	packet = packet or {};
	
	local profile = shared.modProfile:Get(player);
	local activeSave = profile:GetActiveSave();
	if activeSave == nil then return; end;

	local storage = Storage.Get(storageId, player);

	--modOnGameEvents:Fire("OnStorageOpen", player, storageId);

	local storageName = storageConfig.Name;
	local defaultSize = storageConfig.Size;
	local storagePage = packet.StoragePage or 1;
	
	if storage == nil then
		if activeSave.Storages[storageId] == nil then
			activeSave.Storages[storageId] = Storage.new(storageId, storageName, defaultSize, player);
			storage = activeSave.Storages[storageId];

			storage:InitStorage();
		end
		storage = activeSave.Storages[storageId];

	end
	
	storage.Name = storageName;
	storage.MaxPages = storageConfig.MaxPages;
	storage.Page = storagePage;
	storage.MaxSize = storageConfig.MaxSize;
	storage.Size = math.clamp(activeSave.Storages[storageId].Size, defaultSize, storageConfig.MaxSize or activeSave.Storages[storageId].Size);
	storage.Expandable = storageConfig.Expandable;
	storage.Virtual = storageConfig.Virtual;

	storage.Values.OwnerNpc = storageConfig.OwnerNpc;

	if storageConfig.InitStorage then
		if storage.Initialized ~= true then
			storage.Initialized = true;
			storageConfig.InitStorage(storage);
		end
	end

	return storage;
end


local daySecs = 3600 * 24;
function remoteStorageService.OnServerInvoke(player, packet)
	local rPacket = {
		Storages=nil;
	};
	
	local profile = shared.modProfile:Get(player);
	
	local action = packet.Action;
	local storageId = packet.StorageId;
	
	local function process(storageId)
		if storageId == nil then rPacket.Error = 1; return rPacket; end;
		
		local storage = Storage.Get(storageId, player);
		
		if storage == nil then
			Debugger:StudioWarn("Request for Storage (",storageId,") does not exist.");
			return;
		end;
		
		if action == "OpenStorage" then
			storage.OnAccess:Fire(true);
			
		elseif action == "CloseStorage" then
			storage.OnAccess:Fire(false);

		elseif action == "Rental" then
			local traderProfile = profile and profile.Trader;
			local playerGold = traderProfile.Gold;

			local itemCount = storage:Loop();
			
			local rentalPrice = storage.Settings.Rental or 5;
			local cost = (itemCount * rentalPrice);
			
			if playerGold >= cost then
				traderProfile:AddGold(-cost);
				shared.Notify(player, "Unlocked Rat Storage with ".. cost .." Gold", "Positive");
				
				profile:AddPlayPoints(cost/100, "Sink:Gold");
				modAnalytics.RecordResource(player.UserId, cost, "Sink", "Gold", "Purchase", "RatStorage");
				
				storage.RentalUnlockTime = modSyncTime.GetTime() + daySecs;
				
				local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
				if modBranchConfigs.CurrentBranch.Name == "Dev" then 
					storage.RentalUnlockTime = modSyncTime.GetTime() + 30;
				end;
				
				rPacket.Success = true;
				
			else
				shared.Notify(player, "Insufficient Gold!", "Negative");
				
			end
			
		elseif action == "RequestStorage" then
			Debugger:StudioWarn("Requesting Storage(",storageId,")");
		end
		
		if packet.Request == true then
			if rPacket.Storages == nil then rPacket.Storages = {}; end
			rPacket.Storages[storageId] = storage:Shrink();
			
		end
		return;
	end
	
	if packet.StorageIds then
		for _, sId in pairs(packet.StorageIds) do
			process(sId);
		end
		
	else
		process(storageId);
		
	end
	
	return rPacket;
end

local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
local moddedSelf = modModEngineService:GetServerModule(script.Name);
if moddedSelf then moddedSelf:Init(Storage); end

shared.modStorage = Storage;
return Storage;