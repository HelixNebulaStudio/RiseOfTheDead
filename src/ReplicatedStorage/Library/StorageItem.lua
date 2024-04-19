local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;

--== Variables;
local StorageItem = {};
StorageItem.__index = StorageItem;
StorageItem.ClassType = "StorageItem";
StorageItem.Storage = nil;

local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modGoldShopLibrary = require(game.ReplicatedStorage.Library.GoldShopLibrary);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);

local remoteStorageItemSync = modRemotesManager:Get("StorageItemSync");

--== Script;
function StorageItem.new(index, itemId, data, player)
	local itemMeta = setmetatable({}, StorageItem);
	itemMeta.__index = itemMeta;
	itemMeta.Properties = itemId and modItemsLibrary:Find(itemId) or nil;
	itemMeta.Player = player;
	itemMeta.Name = itemMeta.Properties and itemMeta.Properties.Name or "Unknown";
	itemMeta.StorageId = nil;
	
	local item = setmetatable({}, itemMeta);
	item.Index = index;
	item.ItemId = itemId;
	item.Quantity = itemMeta.Properties and math.clamp(data and tonumber(data.Quantity) or 1, 1, itemMeta.Properties.Stackable == false and 1 or itemMeta.Properties.Stackable) or 1;
	item.ID = data and data.ID;
	item.Fav = data and data.Fav;
	item.Vanity = data and data.Vanity;
	
	if data and data.Name and data.Name ~= "nil" then
		item.Name = tostring(data.Name);
	end
	
	
	local metaValues = {};
	metaValues.__index = metaValues;
	
	item.Values = setmetatable(modGlobalVars.CloneTable(itemMeta.Properties and itemMeta.Properties.BaseValues or {}), metaValues);
	
	function itemMeta:SetItemId(itemId)
		itemMeta.Properties = modItemsLibrary:Find(itemId);
		itemMeta.Name = itemMeta.Properties and itemMeta.Properties.Name or "Unknown";
		
		item.ItemId = itemId;
	end
	
	function itemMeta:Shrink()
		local compressedItem = {};
		compressedItem.ID = item.ID;
		compressedItem.ItemId = item.ItemId;
		compressedItem.Index = item.Index;
		compressedItem.Quantity = item.Quantity;
		compressedItem.Values = item.Values;
		compressedItem.Fav = item.Fav;
		compressedItem.Vanity = item.Vanity;
		compressedItem.Name = item.Name;
		compressedItem.DisplayName = item.DisplayName;
		compressedItem.NonTradeable = item.NonTradeable;
		
		return compressedItem;
	end
	
	
	function itemMeta:SetStorageId(storageId)
		rawset(itemMeta, "StorageId", storageId);
	end
	
	function itemMeta:Sync(keys)
		if self.StorageId == nil then
			Debugger:Warn("Missing storageItem storageId", self:Shrink());
			return;
		end
		
		local packet = {};
		packet.StorageId = self.StorageId;
		packet.ID = self.ID;
		packet.ItemId = self.ItemId;
		
		if keys then
			keys = typeof(keys) == "table" and keys or {keys};
			packet.Action = "synckeys";
			
			local properties = {};
			local values = {};
			
			for _, k in pairs(keys) do
				if self[k] then
					properties[k] = self[k];
				end
				if self.Values[k] then
					values[k] = self.Values[k];
				end
			end
			
			packet.Properties = properties;
			packet.Values = values;
			
		else
			packet.Action = "fullsync";
			packet.Data = self:Shrink();
		end
		
		if self.Player == nil then

			local storage = self.Storage.Get(self.StorageId);
			if storage and storage.Player then
				remoteStorageItemSync:FireClient(storage.Player, packet);
				return;
			end

			remoteStorageItemSync:FireAllClients(packet);
			--Debugger:Warn("Missing StorageItem.Player", self:Shrink());
			
		else
			remoteStorageItemSync:FireClient(self.Player, packet);
			
		end
	end
	
	function itemMeta:UpdatePlayer(player)
		rawset(itemMeta, "Player", player);
		self.Player = nil;
	end

	function itemMeta:GetValues(key)
		return item.Values[key];
	end
	
	function itemMeta:SetValues(key, value, syncFunc)
		rawset(item.Values, key, value);
		if syncFunc then syncFunc(); end
		return self;
	end
	
	function itemMeta:DeleteValues(key, syncFunc)
		rawset(item.Values, key, nil);
		if syncFunc then syncFunc(); end
		return self;
	end
	
	function itemMeta:SetFav(v)
		if item.Fav == nil then
			item.Fav = true;
		else
			item.Fav = nil;
		end
		if v ~= nil then
			if v == true then
				item.Fav = true;
			else
				item.Fav = nil;
			end
		end
	end
	
	function itemMeta:SetVanity(v)
		if v == item.Vanity or v == nil then
			rawset(item, "Vanity", nil);
			rawset(item, "VanityItemId", nil);
			rawset(item, "VanitySkinId", nil);
			rawset(item, "VanityMeta", nil);
			return;
		end
		rawset(item, "Vanity", v);
	end
	
	function itemMeta:SetDisplayName(v)
		rawset(item, "DisplayName", v);
	end
	
	function itemMeta:SetNonTradeable(v)
		if v ~= nil then
			rawset(item, "NonTradeable", v);
		else
			local shopLib = modGoldShopLibrary.Products:Find(itemId);
			if shopLib then return end;
			rawset(item, "NonTradeable", v);
			
		end
	end
	
	if itemMeta.Properties and itemMeta.Properties.OnInstantiate then
		itemMeta.Properties.OnInstantiate(item, data);
	end
	
	if data then
		if data.Values and data.Values.Name then
			item.Name = data.Values.Name
			data.Values.Name = nil;
		end
		for valuesKey, valuesData in pairs(data.Values or {}) do 
			rawset(item.Values, valuesKey, valuesData); 
		end
		
		item:SetNonTradeable();
	end
	itemMeta.__newIndex = function(self, key, value)
		if rawget(item, key) == nil then
			itemMeta[key] = value;
		end;
	end;
	
	return item;
end

function StorageItem:Clone()
	local data = {
		Values = nil;
	};
	for k,v in pairs(self.Values) do
		if data.Values == nil then data.Values = {}; end;
		data.Values[k] = v;
	end
	data.Quantity = self.Quantity;
	
	local clone = StorageItem.new(self.Index, self.ItemId, data);
	return clone;
end

function StorageItem.IsStackable(storageItemA, storageItemB)
	if storageItemA.ItemId ~= storageItemB.ItemId then return false end;
	local itemLibA = modItemsLibrary:Find(storageItemA.ItemId);
	local stackable = itemLibA.Stackable;
	
	if stackable == false then return false end;
	if storageItemA.Quantity == stackable or storageItemB.Quantity == stackable then return false end;
	
	local stackMatchList = itemLibA.StackMatch;
	if stackMatchList then
		for a=1, #stackMatchList do
			local key = stackMatchList[a];

			if storageItemA.Values[key] ~= storageItemB.Values[key] then
				stackable = false;
				break;
			end
		end
	end

	return stackable;
end

return StorageItem;