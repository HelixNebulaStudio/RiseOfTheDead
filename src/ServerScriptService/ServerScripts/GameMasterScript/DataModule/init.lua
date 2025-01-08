local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local dataMeta = require(game.ReplicatedStorage.ParallelLibrary.DataModule);
local Data = setmetatable({Script = script;}, dataMeta);

local CollectionService = game:GetService("CollectionService");

local localPlayer: Player = game.Players.LocalPlayer;

local modModEngineService = require(game.ReplicatedStorage.Library.ModEngineService);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modStorageItem = require(game.ReplicatedStorage.Library.StorageItem);

local modEventSignal = require(game.ReplicatedStorage.Library:WaitForChild("EventSignal"));

local remotePlayerDataSync = modRemotesManager:Get("PlayerDataSync") :: RemoteEvent;
local remotePlayerDataFetch = modRemotesManager:Get("PlayerDataFetch");

Data.modInterface = nil;

--== PlayerData;
Data.Profile = {};
Data.GameSave = nil;
Data.MockStorageItem = modStorageItem.new();

Data.Cache = {};
Data.ErrorLogs = {};
Data.Binds = {};
Data.Settings={
	ZoomLevel=8;
};
Data.Storages={};
Data.Players={};
Data.WeaponPropertiesCache={};
Data.ItemClassesCache = {};
Data.TradeRequests = {};
Data.DuelRequests = {};
Data.SquadRequests = {};
Data.TravelRequests = {};
Data.PickupCache = {};
Data.Equipped = nil;

Data.IsPremium = false;
Data.TradeSession = {};

--Data.PlayerGold = 0;
--== Events;
Data.OnDataEvent = modEventSignal.new("OnDataEvent");
Data.OnStorageUpdate = modEventSignal.new("OnStorageUpdate");
Data.OnGoldUpdate = modEventSignal.new("OnGoldUpdate");
Data.OnAmmoUpdate = modEventSignal.new("OnAmmoUpdate");

Data.InteractRequest = function() Debugger:Warn("Interact request not yet binded.") end;
Data.HandleTool = function() end;
Data.UpdateProgressionBar = function() end;

function Data.ToggleChat()
	if Data.modChatRoomInterface then
		Data.modChatRoomInterface.ToggleChat();
	end
end

function Data:GetModCharacter()
	local fiveSecTick = tick();
	
	while localPlayer.Character == nil do
		task.wait();
		if tick()-fiveSecTick >= 5 then
			fiveSecTick = tick();
			Debugger:Warn("Still waiting for Character..", debug.traceback());
		end
	end
	
	local character: Model? = localPlayer.Character;
	if character == nil then return end;
	
	local characterModule = character:WaitForChild("CharacterModule") :: ModuleScript;
	local modCharacter = require(characterModule);
	if modCharacter.__init == false then 
		modCharacter.__init = nil;

		characterModule.Destroying:Once(function()
			for k, v in pairs(modCharacter) do
				if typeof(v) == "table" and v.ClassName == "EventSignal" then
					v:Destroy();
				end
				modCharacter[k] = nil;
			end
		end)
	end;

	return modCharacter;
end

-- !outline: Data:SaveSettings()
function Data:SaveSettings(force)
	if script:GetAttribute("SettingsLoaded") ~= true then return end;
	if Data.MarkSettingsDirty ~= true and force ~= true then return end;
	Data.MarkSettingsDirty = false;
	
	remotePlayerDataSync:FireServer({
		[modRemotesManager.Ref("Action")] = "savesettings";
		[modRemotesManager.Ref("Data")] = Data.Settings;
	});
end

-- !outline: Data:UpdateSettings(func)
function Data:UpdateSettings(func)
	Data.MarkSettingsDirty = true;
	if func then func(); end;
end


function Data:GetInterfaceModule(tryFind)
	local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui");
	
	if Data.modInterface == nil then
		local new = playerGui:FindFirstChild("MainInterface") and playerGui.MainInterface:FindFirstChild("InterfaceModule");
		if new then
			Data.modInterface = require(new);
		end

		--if tryFind then
		--else
		--	local new = playerGui:WaitForChild("MainInterface");
		--	Data.modInterface = require(new:WaitForChild("InterfaceModule"));
			
		--end
	end
	
	return Data.modInterface;
end

-- !outline Data.SetStorage(refStorage)
function Data.SetStorage(refStorage)
	if refStorage == nil then return end;
	if refStorage.Id == nil then return end;
	
	local storageId = refStorage.Id;
	if Data.GameSave and Data.GameSave.Storages then
		for id, _ in pairs(Data.GameSave.Storages) do
			if id == storageId then
				Data.GameSave.Storages[id] = refStorage;
			end
		end
	end
	
	Data.Storages[storageId] = refStorage;
	
	Data.OnStorageUpdate:Fire(refStorage);
	return refStorage;
end

-- !outline Data.DelStorage(id)
function Data.DelStorage(id)
	if id == nil then return end;

	Debugger:Log("Del Storage", id);
	
	if Data.GameSave and Data.GameSave.Storages then
		for oid, _ in pairs(Data.GameSave.Storages) do
			if oid == id then
				Data.GameSave.Storages[id] = nil;
			end
		end
	end
	
	Data.Storages[id] = nil;
end

-- !outline Data.GetStorage(id)
function Data.GetStorage(id)
	return Data.Storages[id];
end


function Data.GetItemById(id, onCharacterOnly)
	if id == "MockStorageItem" then
		return Data.MockStorageItem;
	end
	
	if Data.Storages["Inventory"] and Data.Storages["Inventory"].Container[id] then
		return Data.Storages["Inventory"].Container[id];
		
	elseif Data.Storages["Clothing"] and Data.Storages["Clothing"].Container[id] then
		return Data.Storages["Clothing"].Container[id];

	elseif Data.Storages["Wardrobe"] and Data.Storages["Wardrobe"].Container[id] then
		return Data.Storages["Wardrobe"].Container[id];
		
	elseif onCharacterOnly ~= true then
		for _, storage in pairs(Data.Storages) do
			if storage.Container[id] then
				return storage.Container[id];
			end;
		end
	end
	return;
end

function Data.GetStorageOfItem(id)
	if Data.Storages["Inventory"] and Data.Storages["Inventory"].Container[id] then
		return Data.Storages["Inventory"];

	elseif Data.Storages["Clothing"] and Data.Storages["Clothing"].Container[id] then
		return Data.Storages["Clothing"];

	elseif Data.Storages["Wardrobe"] and Data.Storages["Wardrobe"].Container[id] then
		return Data.Storages["Wardrobe"];
		
	end
	return;
end

-- !outline: Data.UpdatePickupCache()
function Data.UpdatePickupCache()
	local autoPickupConfig = Data.Settings.AutoPickupConfig or {};

	local modSettings = require(game.ReplicatedStorage.Library.Settings);
	modSettings.UpdateAutoPickup(Data.PickupCache, autoPickupConfig);
end

-- !outline: Data.FindIndexFromStorage(storageId, index)
function Data.FindIndexFromStorage(storageId, index)
	local storage = Data.Storages[storageId];
	if storage == nil then return end;
	
	for siid, storageItem in pairs(storage.Container) do
		if storageItem.Index == index then
			return storageItem;
		end
	end

	return;
end

-- !outline: Data.FindIdFromStorages(id)
function Data.FindIdFromStorages(id)
	for name, storage in pairs(Data.Storages) do
		if storage.Container[id] then
			return storage.Container[id], storage;
		end;
	end
	return;
end

-- !outline: Data.FindNameFromStorages(name)
function Data.FindNameFromStorages(name)
	for storageId, storage in pairs(Data.Storages) do
		for id, item in pairs(storage.Container) do
			if item.Name == name then
				return storage.Container[id];
			end
		end
	end
	return;
end

-- !outline: Data.FindItemIdFromStorages(itemId)
function Data.FindItemIdFromStorages(itemId)
	for storageId, storage in pairs(Data.Storages) do
		for id, item in pairs(storage.Container) do
			if item.ItemId == itemId then
				return storage.Container[id];
			end
		end
	end
	return;
end

-- !outline: Data.FindItemIdFromCharacter(itemId)
function Data.FindItemIdFromCharacter(itemId)
	if Data.Storages["ammopouch"] then
		for id, item in pairs(Data.Storages.ammopouch.Container) do
			if item.ItemId == itemId then
				return Data.Storages.ammopouch.Container[id];
			end
		end
	end
	if Data.Storages["Inventory"] then
		for id, item in pairs(Data.Storages.Inventory.Container) do
			if item.ItemId == itemId then
				return Data.Storages.Inventory.Container[id];
			end
		end
	end
	if Data.Storages["Clothing"] then
		for id, item in pairs(Data.Storages.Clothing.Container) do
			if item.ItemId == itemId then
				return Data.Storages.Clothing.Container[id];
			end
		end
	end
	if Data.Storages["Wardrobe"] then
		for id, item in pairs(Data.Storages.Wardrobe.Container) do
			if item.ItemId == itemId then
				return Data.Storages.Wardrobe.Container[id];
			end
		end
	end
	return;
end

-- !outline: Data.ListItemIdFromCharacter(itemId)
function Data.ListItemIdFromCharacter(itemId)
	local list = {};
	if Data.Storages["ammopouch"] then
		for id, item in pairs(Data.Storages.ammopouch.Container) do
			if item.ItemId == itemId then
				table.insert(list, item);
			end
		end
	end
	if Data.Storages["Inventory"] then
		for id, item in pairs(Data.Storages.Inventory.Container) do
			if item.ItemId ~= itemId then continue end;
			table.insert(list, item);
		end

		local linkedStorages = Data.Storages.Inventory.LinkedStorages;

		for a=#linkedStorages, 1, -1 do
			local linkStorageInfo = linkedStorages[a];
			if linkStorageInfo == nil then continue end;
			
			local storage = Data.Storages[linkStorageInfo.StorageId];
			if storage == nil then continue end;
			
			for id, item in pairs(storage.Container) do
				if item.ItemId ~= itemId then continue end;
				table.insert(list, item);
			end
		end
		
	end
	if Data.Storages["Clothing"] then
		for id, item in pairs(Data.Storages.Clothing.Container) do
			if item.ItemId == itemId then
				table.insert(list, item);
			end
		end
	end
	if Data.Storages["Wardrobe"] then
		for id, item in pairs(Data.Storages.Wardrobe.Container) do
			if item.ItemId == itemId then
				table.insert(list, item);
			end
		end
	end
	return list;
end

-- !outline: Data.CountItemIdFromCharacter(itemId)
function Data.CountItemIdFromCharacter(itemId)
	local c = 0;
	
	local itemsList = Data.ListItemIdFromCharacter(itemId);
	for a=1, #itemsList do
		local item = itemsList[a];
		
		c = c + item.Quantity;
	end

	return c;
end

function Data.ListItemIdFromStorages(itemId)
	local list = {};
	for storageId, storage in pairs(Data.Storages) do
		for id, item in pairs(storage.Container) do
			if item.ItemId == itemId then
				table.insert(list, item);
			end
		end
	end
	return list;
end

function Data.CountItemIdFromStorages(itemId)
	local c = 0;
	for storageId, storage in pairs(Data.Storages) do
		for id, item in pairs(storage.Container) do
			if item.ItemId == itemId then
				c = c + item.Quantity;
			end
		end
	end
	return c;
end

function Data.GetAllMods()
	local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);

	local mods = {};
	local storages = {Data.Storages.Inventory; Data.Storages["Safehouse Storage"]};
	for storageId, storage in pairs(storages) do
		for id, item in pairs(storage.Container) do
			local itemLib = modItemsLibrary:Find(item.ItemId);
			if itemLib and itemLib.Type == modItemsLibrary.Types.Mod then
				table.insert(mods, {Item=storage.Container[id]; Storage=storage});
			end
		end
	end
	return mods;
end

-- !outline Data.GetItemStorage(id)
function Data.GetItemStorage(id) -- Get storage with names of item ids. E.g. Weapon Attachments
	return Data.Storages[id];
end

function Data.GetStats()
	return Data.GameSave and Data.GameSave.Stats;
end

function Data.GetStat(key)
	return Data.GameSave and Data.GameSave.Stats and Data.GameSave.Stats[key] or nil;
end

function Data:GetFlag(flagId, fetch)
	if fetch == true then
		local packet = remotePlayerDataFetch:InvokeServer{
			[modRemotesManager.Ref("Action")] = "flagfetch";
			[modRemotesManager.Ref("Id")] = flagId;
		}
		if packet then
			if Data.Profile.Flags == nil then
				Data.Profile.Flags = {};
			end
			if Data.Profile.Flags.Data == nil then
				Data.Profile.Flags.Data = {};
			end
			
			local index = packet[modRemotesManager.Ref("Index")];
			local data = packet[modRemotesManager.Ref("Data")];
			
			for k, flagData in pairs(Data.Profile.Flags.Data) do
				if flagData.Id == flagId then
					Data.Profile.Flags.Data[k] = nil;
				end
			end
		
			Data.Profile.Flags.Data[index] = data;
		end
	end
	
	if Data.Profile == nil or Data.Profile.Flags == nil or Data.Profile.Flags.Data == nil then return nil end;
	
	for a, flag in pairs(Data.Profile.Flags.Data) do
		if flag.Id == flagId then
			return flag;
		end
	end
	return;
end

Data.Events = {};
Data.FirstFetchEvent = {};
function Data:GetEvent(id, fetch)
	if Data.FirstFetchEvent[id] == nil then
		fetch = true;
	end
	
	local eventData = Data.Events[id];
	if fetch ~= true and eventData == nil then return end;
	
	local lastFetch = eventData and eventData.LastFetch;
	
	if lastFetch == nil or (tick()-lastFetch >= 5) or fetch == true then
		Data.FirstFetchEvent[id] = true;
		local packet = remotePlayerDataFetch:InvokeServer{
			[modRemotesManager.Ref("Action")] = "eventfetch";
			[modRemotesManager.Ref("Id")] = id;
		}
		if packet then
			local data = packet[modRemotesManager.Ref("Data")];
			data.LastFetch = tick();
			Data.Events[id] = data;
		end
	end
	
	return Data.Events[id];
end

function Data:RequestData(hierarchyKey)
	remotePlayerDataSync:FireServer{
		[modRemotesManager.Ref("Action")] = "request";
		[modRemotesManager.Ref("HierarchyKey")] = hierarchyKey;
	};
end

function Data:SetSquad(squad)
	local ClientSquad = require(script:WaitForChild("ClientSquad"))(Data);
	
	if squad then
		if Data.Squad == nil then
			Data.Squad = ClientSquad.new();
		end 
		Data.Squad:Update(squad);
	else
		if Data.Squad then
			Data.Squad:Destroy();
		end
		Data.Squad = nil;
	end
	
	local remotes = game.ReplicatedStorage.Remotes;
	delay(0, function() remotes.Interface.UpdateSocialMenu:Fire() end);
	return Data.Squad;
end

function Data:GetBaseToolModule(itemId)
	local modWeapons = require(game.ReplicatedStorage.Library.Weapons);
	local modTools = require(game.ReplicatedStorage.Library.Tools);
	if modWeapons[itemId] then
		return require(modWeapons[itemId].Module)(), "Weapon";
		
	elseif modTools[itemId] then
		return require(modTools[itemId].Module)(), "Tool";
		
	end

	return;
end

-- MARK: GetItemClass
function Data:GetItemClass(storageItemId, getShadowCopy)
	local storageItem = Data.GetItemById(storageItemId);
	if storageItem == nil then return end;
	
	local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);

	local itemValues = storageItem.Values;
	local itemId = storageItem.ItemId;
	local itemLib = modItemsLibrary:Find(itemId);
	if itemLib == nil then return end;
	
	local classLib = nil;

	local attachmentStorage = Data.GetItemStorage(storageItemId);

	local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);
	local modWeaponsMechanics = require(game.ReplicatedStorage.Library.WeaponsMechanics);

	local update = function(storageItem, class, classType)
		if class.Reset then class:Reset(); end;
		if modConfigurations.SkipRotDModding == true then return class; end;

		if classType == "Weapon" then
			modWeaponsMechanics.UpdateWeaponPotential(itemValues.L, class);
			
			if itemValues and itemValues.Tweak then
				modWeaponsMechanics.ApplyTraits(storageItem, class);
			end
			
		elseif classType == "Clothing" then
			if itemValues and itemValues.Seed then
				if class.ApplySeed then
					class:ApplySeed(storageItem);
				end;
			end
			
		end

		if class.PreMod then
			class:PreMod();
		end

		if attachmentStorage and next(attachmentStorage.Container) then
			class = modWeaponsMechanics.ApplyPassiveMods(storageItem, attachmentStorage, class);
		end

		if class.PostMod then
			class:PostMod();
		end
		
		if class.LoadModifiers then
			class:LoadModifiers(storageItem);
		end

		if class.CalculateDps then class:CalculateDps(); end
		if class.CalculateDpm then class:CalculateDpm(); end
		if class.CalculateMd then class:CalculateMd(); end
		if class.CalculateTad then class:CalculateTad(); end
		if class.CalculatePower then class:CalculatePower(); end
		
		return class;
	end
	
	local modItemClass = modModEngineService:GetModule(`ItemClass`);
	if modItemClass then
		update = modItemClass.UpdateItemClass;
	end

	local classType = nil;
	if itemLib.Type == modItemsLibrary.Types.Tool then
		local modWeapons = require(game.ReplicatedStorage.Library.Weapons);
		local modTools = require(game.ReplicatedStorage.Library.Tools);

		if modWeapons[itemId] then
			classType = "Weapon";
			classLib = modWeapons[itemId];
			
		elseif modTools[itemId] then
			classType = "Tool";
			classLib = modTools[itemId];
			
		end
		
	elseif itemLib.Type == modItemsLibrary.Types.Clothing then
		local modClothingLibrary = require(game.ReplicatedStorage.Library.ClothingLibrary);

		classType = "Clothing";
		classLib = modClothingLibrary:Find(itemId);
		
	end
	
	if classLib then
		if getShadowCopy == true then
			return update(storageItem, classLib.NewToolLib(), classType), classType;
		else
			local cacheKey = storageItemId;
			if storageItemId == "MockStorageItem" then
				cacheKey = itemId;
			end

			if Data.ItemClassesCache[cacheKey] == nil then
				Data.ItemClassesCache[cacheKey] = classLib.NewToolLib();
			end
			return update(storageItem, Data.ItemClassesCache[cacheKey], classType), classType;
		end
		
	end
	
	return;
end

function Data:WaitForMissions()
	while Data.GameSave == nil or Data.GameSave.Missions == nil do
		task.wait(1);
	end
end

function Data:GetMission(id)
	if Data.GameSave and Data.GameSave.Missions then
		local missionsList = Data.GameSave.Missions;
		
		for a=1, #missionsList do
			local missionData = missionsList[a];
			
			if missionData.Id == id then
				return missionData;
			end
		end
	end

	return;
end


function Data:GetSkillTree(skillId)
	local skilltree = Data.Profile.SkillTree.ActiveTree and Data.Profile.SkillTree.Trees[Data.Profile.SkillTree.ActiveTree];
	
	local modSkillTreeLibrary = require(game.ReplicatedStorage.Library.SkillTreeLibrary);

	local lib = modSkillTreeLibrary:Find(skillId);
	local pts = skilltree and skilltree.Data and skilltree.Data[skillId] or 0;
	
	if lib and pts then
		return modSkillTreeLibrary:CalStats(lib, pts);
	end

	return;
end


Data.MutePlayerNoise = {};

function Data.RefreshPlayerNoise(playerName)
	local sounds = CollectionService:GetTagged("PlayerNoiseSounds");
		
	for _, player in pairs(game.Players:GetChildren()) do
		if player == game.Players.LocalPlayer then continue end;
		if player.Name ~= playerName then continue end;
		
		local shouldMute = Data.MutePlayerNoise[playerName] == true;

		for a=1, #sounds do
			local sound = sounds[a];
			local soundOwner = sound:GetAttribute("SoundOwner");
			if soundOwner ~= playerName then continue end;

			sound.Volume = shouldMute and 0 or sound:GetAttribute("Volume") or 1;
		end
	end

end

CollectionService:GetInstanceAddedSignal("PlayerNoiseSounds"):Connect(function(sound)
	local ownerName = sound:GetAttribute("SoundOwner");
	
	for a=1, 5 do
		ownerName = sound:GetAttribute("SoundOwner");
		if ownerName == nil then
			task.wait(1);
		else
			break; 
		end
	end
	
	if ownerName == nil then Debugger:Log("Missing ownerName", sound:GetFullName()); sound.Volume = 0; return end;
	if ownerName == game.Players.LocalPlayer.Name then return end;
	
	local shouldMute = Data.MutePlayerNoise[ownerName] == true;

	if sound:GetAttribute("MusicNote") and shouldMute then
		sound.Volume = 0;
		game.Debris:AddItem(sound, 0);
	end
	
	local onChangeConn;
	local function onChange()
		if not CollectionService:HasTag(sound, "PlayerNoiseSounds") then
			onChangeConn:Disconnect();
			return;
		end
		
		sound.Volume = shouldMute and 0 or sound:GetAttribute("Volume") or 1;
	end
	onChangeConn = sound:GetPropertyChangedSignal("Playing"):Connect(onChange);
	onChange();

end)


Debugger:Warn("Initialize");
return Data;