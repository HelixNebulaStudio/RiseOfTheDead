local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);

local modCrateLibrary = require(game.ReplicatedStorage.Library.CrateLibrary);
local modReplicationManager = require(game.ReplicatedStorage.Library.ReplicationManager);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modDropRateCalculator = require(game.ReplicatedStorage.Library.DropRateCalculator);
local modRewardsLibrary = require(game.ReplicatedStorage.Library.RewardsLibrary);

local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
local modOnGameEvents = require(game.ServerScriptService.ServerLibrary.OnGameEvents);

--== Variables;
local Crates = {};
Crates.IdCounter = 0;

local storageInteractableTemplate = script:WaitForChild("Interactable");
local random = Random.new();
--== Script;
-- !outline: Crates.GenerateRewards(id, player, criteria)
function Crates.GenerateRewards(id, player, criteria)
	local chosenRewards = {};
	local crateLib = modCrateLibrary.Get(id);
	local rewardsLib = crateLib and modRewardsLibrary:Find(crateLib.RewardsId or id) or nil;
	if rewardsLib then
		chosenRewards = modDropRateCalculator.RollDrop(rewardsLib, player, criteria);
	else
		Debugger:Warn("Missing crate rewardsLib:",id);
	end
	return chosenRewards;
end

-- !outline: Crates.Spawn(id, cframe, whitelist, content, visibleToWhitelistOnly)
function Crates.Spawn(id, cframe, whitelist, content, visibleToWhitelistOnly)
	local crateLib = modCrateLibrary.Get(id);
	if crateLib == nil then return end;
	
	local newPrefab = crateLib.Prefab:Clone();
	newPrefab.PrimaryPart.Anchored = true;
	newPrefab:PivotTo(cframe);
	
	Crates.IdCounter = Crates.IdCounter +1;
	local storageConfig = crateLib.Configurations;
	local storageId = storageConfig.Persistent and crateLib.Id or crateLib.Id.."$r"..Crates.IdCounter;
	local storageName = crateLib.Name;
	
	newPrefab.Name = crateLib.Name;
	
	local storageInteractable = storageInteractableTemplate:Clone();
	storageInteractable.Parent = newPrefab;
	local interactData = require(storageInteractable);
	
	interactData.Script = storageInteractable;
	interactData:SetStorageId(storageId);
	
	interactData.RefStorageId = crateLib.Id;
	interactData.StorageName = storageName;
	interactData.Configurations = storageConfig;
	interactData.Whitelist = {};
	
	if crateLib.EmptyLabel then interactData.EmptyLabel = crateLib.EmptyLabel end;
	if crateLib.LoadingLabel then interactData.LoadingLabel = crateLib.LoadingLabel; end;
	if crateLib.Label then interactData.Label = crateLib.Label; end;
	
	if whitelist then
		for a=1, #whitelist do
			local player = whitelist[a];
			
			interactData.Whitelist[player.Name] = true;
			
			local profile = modProfile:Get(player);
			local playerSave = profile and profile:GetActiveSave();
			if playerSave then
				local storages = storageConfig.Persistent and playerSave.Storages or profile:GetCacheStorages();
				
				if storages[storageId] == nil then
					storages[storageId] = modStorage.new(storageId, storageName, math.clamp(storageConfig.Size or (content and math.ceil(#content/5)*5) or 10, 10, 100), player);
					storages[storageId].Physical = newPrefab.PrimaryPart;
					storages[storageId].ItemSpawn = true;
				end
				
				-- Add content;
				for b=1, #content do
					local rewardInfo = content[b];
					local itemId = rewardInfo.ItemId;
					local quantity = typeof(rewardInfo.Quantity) == "table" and random:NextInteger(rewardInfo.Quantity.Min, rewardInfo.Quantity.Max) or rewardInfo.Quantity;
					local itemLib = modItemsLibrary:Find(itemId);
					
					storages[storageId]:Add(itemId, {Quantity=quantity;}, function(event, remains)
						if event ~= "Success" then
							Debugger:Warn("Failed to spawn ("..id..") with its contents.", remains);
						end;
					end)
				end
				
				if storageConfig.Settings then
					for k, v in pairs(storageConfig.Settings) do
						if storages[storageId].Settings[k] ~= nil then
							storages[storageId].Settings[k] = v;
						end
					end
					
					if storageConfig.Settings.DestroyOnEmpty then
						storages[storageId]:OnDestroyConnect(function(storage)
							game.Debris:AddItem(newPrefab, 0);
						end)
					end
				end
			end
		end
		
		if visibleToWhitelistOnly then
			modReplicationManager.ReplicateIn(whitelist, newPrefab, workspace.Interactables);
		else
			newPrefab.Parent = workspace.Interactables;
		end
	end
	
	local rewardsLib = modRewardsLibrary:Find(id);
	if rewardsLib and rewardsLib.Level then
		interactData.LevelRequired = rewardsLib.Level;
	end 
	
	interactData:Sync();

	modOnGameEvents:Fire("OnCrateSpawn", newPrefab, interactData, whitelist);
	
	return newPrefab, interactData;
end

-- !outline: Crates.Create(id, cframe)
function Crates.Create(id, cframe)
	local crateLib = modCrateLibrary.Get(id);
	if crateLib then
		local newPrefab;
		if type(crateLib.Prefab) == "table" then
			newPrefab = crateLib.Prefab[random:NextInteger(1, #crateLib.Prefab)]:Clone();
		else
			newPrefab = crateLib.Prefab:Clone();
		end
		
		newPrefab:PivotTo(cframe);

		Crates.IdCounter = Crates.IdCounter +1;
		local storageConfig = crateLib.Configurations;
		local storageId = storageConfig.Persistent and crateLib.Id or crateLib.Id.."$r"..Crates.IdCounter;
		local storageName = crateLib.Name;

		newPrefab.Name = crateLib.Name;

		local storageInteractable = storageInteractableTemplate:Clone();
		storageInteractable.Parent = newPrefab;
		local interactData = require(storageInteractable);
		interactData:SetStorageId(storageId);
		
		interactData.RefStorageId = crateLib.Id;
		interactData.StorageName = storageName;
		interactData.Configurations = storageConfig;
		
		if crateLib.EmptyLabel then interactData.EmptyLabel = crateLib.EmptyLabel end;
		if crateLib.Label then interactData.Label = crateLib.Label; end;
		
		local newStorage = modStorage.new(storageId, storageName, 0);
		newStorage.Physical = newPrefab.PrimaryPart;

		if storageConfig.Settings then
			for k, v in pairs(storageConfig.Settings) do
				if newStorage.Settings[k] ~= nil then
					newStorage.Settings[k] = v;
				end
			end

			if storageConfig.Settings.DestroyOnEmpty then
				newStorage:OnDestroyConnect(function(storage)
					game.Debris:AddItem(newPrefab, 0);
				end)
			end
		end

		newPrefab.Parent = workspace.Interactables;
		--interactData:Sync();

		return newPrefab, interactData, newStorage;
	end
end

return Crates;