local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));

local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modGoldShopLibrary = require(game.ReplicatedStorage.Library.GoldShopLibrary);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

local modTables = require(game.ReplicatedStorage.Library.Util.Tables);

local remoteStorageItemSync = modRemotesManager:Get("StorageItemSync");

--==
local StorageItem = {};
StorageItem.__index = StorageItem;
StorageItem.ClassType = "StorageItem";

type StorageItemObject = {
	ItemId: string;
	Name: string?;
	Quantity: number | boolean;
	Values: {[any]: any};
}
export type StorageItem = typeof(setmetatable({} :: StorageItemObject, StorageItem));

function StorageItem.new(index, itemId, data, player)
	local meta = setmetatable({}, StorageItem);
	meta.__index = meta;

	meta.Library = modItemsLibrary:Find(itemId);
	meta.Player = player;
	meta.StorageId = nil;

	local self = setmetatable({}, meta);
	self.Index = index;
	self.ItemId = itemId;
	
	self.ID = data and data.ID;
	self.Fav = data and data.Fav;
	self.Vanity = data and data.Vanity;

	if meta.Library then
		meta.Name = meta.Library.Name;

		self.Quantity = math.clamp(data and tonumber(data.Quantity) or 1, 1, meta.Library.Stackable == false and 1 or meta.Library.Stackable) or 1;
		self.Values = modTables.DeepClone(meta.Library.BaseValues or {});

	else
		self.Quantity = 1;
		self.Values = {};

	end
	
	if data and data.CustomName then
		self.CustomName = tostring(data.CustomName);
	end

	meta.__newIndex = function(self, key, value)
		if key == "CustomName" then
			rawset(self, "CustomName", value);

		elseif rawget(self, key) == nil then
			Debugger:StudioWarn("Set raw meta", key);
			meta[key] = value;
		end;
	end;

	if meta.Library and meta.Library.OnInstantiate then
		meta.Library.OnInstantiate(self, data);
	end
	
	if data then
		for valuesKey, valuesData in pairs(data.Values or {}) do 
			self.Values[valuesKey] = valuesData;
		end
		
		self:SetNonTradeable();
	end
	
	return self;
end

-- MARK: Meta Functions
function StorageItem:SetItemId(itemId)
	local meta = getmetatable(self);

	meta.Library = modItemsLibrary:Find(itemId);

	if meta.Library then
		self.Name = meta.Library.Name;
		self.Quantity = math.clamp(self.Quantity, 1, meta.Library.Stackable == false and 1 or meta.Library.Stackable);
		
	else
		self.Quantity = 1;

	end

	self.ItemId = itemId;
end

function StorageItem:SetStorageId(storageId)
	local meta = getmetatable(self);
	meta.StorageId = storageId;
end

function StorageItem:Shrink()
	local compressedItem = {};
	compressedItem.ID = self.ID;
	compressedItem.ItemId = self.ItemId;
	compressedItem.Index = self.Index;
	compressedItem.Quantity = self.Quantity;
	compressedItem.Values = self.Values;
	compressedItem.Fav = self.Fav;
	compressedItem.Vanity = self.Vanity;
	compressedItem.Name = self.Name;
	compressedItem.CustomName = self.CustomName;
	compressedItem.DisplayName = self.DisplayName;
	compressedItem.NonTradeable = self.NonTradeable;
	
	return compressedItem;
end

function StorageItem:Sync(keys)
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
		local delValues = {};
		
		for _, k in pairs(keys) do
			if self[k] then
				properties[k] = self[k];
			end
			if self.Values[k] then
				values[k] = self.Values[k];
			end
			if self.Values[k] == nil then
				delValues[k] = true;
			end
		end
		
		packet.Properties = properties;
		packet.Values = values;
		packet.DelValues = delValues;
		
	else
		packet.Action = "fullsync";
		packet.Data = self:Shrink();
	end
	
	if self.Player == nil then

		local storage = shared.modStorage.Get(self.StorageId);
		if storage and storage.Player then
			remoteStorageItemSync:FireClient(storage.Player, packet);
			return;
		end

		remoteStorageItemSync:FireAllClients(packet);
		
	else
		remoteStorageItemSync:FireClient(self.Player, packet);
		
	end
end

function StorageItem:UpdatePlayer(player)
	local meta = getmetatable(self);
	meta.Player = player;
end

function StorageItem:GetValues(key)
	return self.Values[key];
end

function StorageItem:SetValues(key, value, syncFunc)
	self.Values[key] = value;
	if syncFunc then syncFunc() end;
	return self;
end

function StorageItem:DeleteValues(key, syncFunc)
	self.Values[key] = nil;
	if syncFunc then syncFunc(); end;
	return self;
end

function StorageItem:SetFav(v)
	if self.Fav == nil then
		self.Fav = true;
	else
		self.Fav = nil;
	end
	if v ~= nil then
		if v == true then
			self.Fav = true;
		else
			self.Fav = nil;
		end
	end
end

function StorageItem:SetVanity(v)
	if v == self.Vanity or v == nil then
		self.Vanity = nil;
		self.VanityItemId = nil;
		self.VanitySkinId = nil;
		self.VanityMeta = nil;
		return;
	end
	self.Vanity = v;
end

	
function StorageItem:SetDisplayName(v)
	rawset(self, "DisplayName", v);
end

function StorageItem:SetNonTradeable(v)
	if v ~= nil then
		self.NonTradeable = v;
		
	else
		local shopLib = modGoldShopLibrary.Products:Find(self.ItemId);
		if shopLib then return end;

		self.NonTradeable = v;
		
	end
end

function StorageItem:Clone()
	local data = {
		CustomName = self.CustomName;
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

function StorageItem:TakeDamage(damage)
	if self:GetValues("MaxHealth") == nil then
		self:SetValues("MaxHealth", 100);
	end

	local initHealth = self:GetValues("Health") or 100;
	local newHealth = math.max(initHealth-(damage/2), 0);
	self:SetValues("Health", newHealth);

	self:Sync({"Health"; "MaxHealth"});
end

-- MARK: Global Functions
function StorageItem.IsStackable(storageItemA, storageItemB)
	if storageItemA.ItemId ~= storageItemB.ItemId then return false end;
	local itemLibA = modItemsLibrary:Find(storageItemA.ItemId);
	local stackable = itemLibA.Stackable;
	
	if stackable == false then return false end;
	if (storageItemA.Quantity or 1) >= stackable or (storageItemB.Quantity or 1) >= stackable then return false end;
	if storageItemA.Name ~= storageItemB.Name then return false end
	
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

function StorageItem.PopupItemStatus(storageItem, statusId)
	local classPlayer = shared.modPlayers.Get(storageItem.Player);
	if classPlayer == nil then return end

	local itemLib = storageItem.Library;

	local itemDmgStatus = {
		UniqueId = storageItem.ID;
		Icon = itemLib.Icon;
		Expires= modSyncTime.GetTime() + 3;
	};

	statusId = statusId or "ItemHealth";
	if statusId == "ItemHealth" then
		itemDmgStatus.Alpha = storageItem.Values.Health / storageItem.Values.MaxHealth;

		itemDmgStatus.IconColor = storageItem.Values.Health > 0 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(255, 82, 82);
		itemDmgStatus.Desc = storageItem.Values.Health > 0 and `Your {itemLib.Name} is taking damage.` or `Your {itemLib.Name} is broken.`;
	end

	local statusKey = statusId..itemDmgStatus.UniqueId;
	classPlayer:SetProperties(statusKey, itemDmgStatus);
end

return StorageItem;