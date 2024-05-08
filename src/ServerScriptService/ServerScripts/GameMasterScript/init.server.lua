local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--== Configuration;
shared.GameCache = {};

--== Variables;
local RunService = game:GetService("RunService");
local Players = game:GetService("Players");
local CollectionService = game:GetService("CollectionService");
local MemoryStoreService = game:GetService("MemoryStoreService");
local ScriptContext = game:GetService("ScriptContext");

--== Modules;
local modEngineCore = Debugger:Require(game.ReplicatedStorage.EngineCore);
local modGlobalVars = Debugger:Require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modAssetHandler = Debugger:Require(game.ReplicatedStorage.Library.AssetHandler); modAssetHandler.init();
local modPlayers = Debugger:Require(game.ReplicatedStorage.Library.Players);
local modScheduler = Debugger:Require(game.ReplicatedStorage.Library.Scheduler); modScheduler:GetGlobal();
local modGameLogService = Debugger:Require(game.ReplicatedStorage.Library.GameLogService);
local modItemsLibrary = Debugger:Require(game.ReplicatedStorage.Library.ItemsLibrary);
local modModsLibrary = Debugger:Require(game.ReplicatedStorage.Library.ModsLibrary);
local modSyncTime = Debugger:Require(game.ReplicatedStorage.Library.SyncTime);
local modBranchConfigs = Debugger:Require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = Debugger:Require(game.ReplicatedStorage.Library.RemotesManager);
local modConfigurations = Debugger:Require(game.ReplicatedStorage.Library.Configurations);
local modCommandHandler = Debugger:Require(game.ReplicatedStorage.Library.CommandHandler);
local modInteractables = Debugger:Require(game.ReplicatedStorage.Library.Interactables);
local modCollectiblesLibrary = Debugger:Require(game.ReplicatedStorage.Library.CollectiblesLibrary);
local modAudio = Debugger:Require(game.ReplicatedStorage.Library.Audio);
local modUsableItems = Debugger:Require(game.ReplicatedStorage.Library.UsableItems);
local modCutscene = Debugger:Require(game.ReplicatedStorage.Library.Cutscene);
local modRewardsLibrary = Debugger:Require(game.ReplicatedStorage.Library.RewardsLibrary);
local modWorkbenchLibrary = Debugger:Require(game.ReplicatedStorage.Library.WorkbenchLibrary);
local modMissionLibrary = Debugger:Require(game.ReplicatedStorage.Library.MissionLibrary);
local modGpsLibrary = Debugger:Require(game.ReplicatedStorage.Library.GpsLibrary);
local modLeaderboardService = Debugger:Require(game.ReplicatedStorage.Library.LeaderboardService);
local modGoldShopLibrary = Debugger:Require(game.ReplicatedStorage.Library.GoldShopLibrary);
local modCharacterInteractions = Debugger:Require(game.ReplicatedStorage.Library.CharacterInteractions);

local modUniversalBind = Debugger:Require(game.ServerScriptService.ServerLibrary.UniversalEventBind);
local modProfile = Debugger:Require(game.ServerScriptService.ServerLibrary.Profile);
local modStorage = Debugger:Require(game.ServerScriptService.ServerLibrary.Storage);
local modMission = Debugger:Require(game.ServerScriptService.ServerLibrary.Mission);
local modMailObject = Debugger:Require(game.ServerScriptService.ServerLibrary.MailObject);
local modPhysics = Debugger:Require(game.ServerScriptService.ServerLibrary.Physics);
local modWorldEvents = Debugger:Require(game.ServerScriptService.ServerLibrary.WorldEventSystem);
local modDialogues = Debugger:Require(game.ServerScriptService.ServerLibrary.DialogueSave);
local modGameModeManager = Debugger:Require(game.ServerScriptService.ServerLibrary.GameModeManager);
local modSquadService = Debugger:Require(game.ServerScriptService.ServerLibrary.SquadService);
local modFactions = Debugger:Require(game.ServerScriptService.ServerLibrary.Factions);
local modBlueprints = Debugger:Require(game.ServerScriptService.ServerLibrary.Blueprints);
local modServerManager = Debugger:Require(game.ServerScriptService.ServerLibrary.ServerManager);
local modTradingService = Debugger:Require(game.ServerScriptService.ServerLibrary.TradingService);
local modEvents = Debugger:Require(game.ServerScriptService.ServerLibrary.Events);
modPlayers.SkillTree = Debugger:Require(game.ServerScriptService.ServerLibrary.SkillTree);
local modAnalytics = Debugger:Require(game.ServerScriptService.ServerLibrary.GameAnalytics);
local modCharacterAppearance = Debugger:Require(game.ServerScriptService.ServerLibrary.CharacterAppearance);
local modMemoryMap = Debugger:Require(game.ServerScriptService.ServerLibrary.MemoryMap);
local modEconomyAnalytics = Debugger:Require(game.ServerScriptService.ServerLibrary.EconomyAnalytics);


local modOnGameEvents = Debugger:Require(game.ServerScriptService.ServerLibrary.OnGameEvents);
local modModerationSystem = Debugger:Require(game.ServerScriptService.ServerLibrary.ModerationSystem);

local remotes = game.ReplicatedStorage.Remotes;

local remotePickUpRequest = remotes.Interactable.PickUpRequest;
local remoteWorldTravelRequest = remotes.Interactable.WorldTravelRequest;
local remoteOpenStorageRequest = remotes.Interactable.OpenStorageRequest;

local remotePlayerDataSync = modRemotesManager:Get("PlayerDataSync");
local remotePlayerDataFetch = modRemotesManager:Get("PlayerDataFetch");

local remoteUpgradeStorage = modRemotesManager:Get("UpgradeStorage");
local remoteEnterDoorRequest = modRemotesManager:Get("EnterDoorRequest");
local remoteOnTrigger = remotes.Interactable.OnTrigger;
local remoteInteractableToggle = modRemotesManager:Get("InteractableToggle");
local remoteLockHydra = modRemotesManager:Get("LockHydra");
--== Remotes;
local remoteEnterCampaign = remotes.MainMenu.EnterCampaign;
local remoteSetLoadLabel = remotes.MainMenu.SetLoadLabel;
local remoteMailboxFunction = remotes.Interface.MailboxFunction;
local remoteRequestResetData = modRemotesManager:Get("RequestResetData");
local remoteFastTravel = modRemotesManager:Get("FastTravel");
local remoteDuelRequest = modRemotesManager:Get("DuelRequest");
local remoteKeypadInput = modRemotesManager:Get("KeypadInput");
local remotePlayerSearch = modRemotesManager:Get("PlayerSearch");
local remoteGoldDonate = modRemotesManager:Get("GoldDonate");
local remoteGeneralUIRemote = modRemotesManager:Get("GeneralUIRemote");

local modEngineMode = modGlobalVars.EngineMode == "RiseOfTheDead" 
	and require(script:WaitForChild("RiseOfTheDead")) 
	or require(game.ServerScriptService:WaitForChild("ModEngine") :: ModuleScript);

--== Script;
Debugger:Log("Initializing server data script complete.");
workspace:SetAttribute("Version", modGlobalVars.GameVersion.."."..modGlobalVars.GameBuild .. " (".. modBranchConfigs.CurrentBranch.Name ..")");


function OnPlayerAdded(player)
	Debugger:Log("OnPlayerAdded>> ", player);
	
	local dataModule = script:WaitForChild("DataModule"):Clone();
	dataModule.Parent = player;
	
	task.spawn(function() modEngineMode.OnPlayerAdded(player); end);
	task.spawn(function() modSquadService.OnPlayerAdded(player); end);
	
	local firstLoad = false;
	local function onCharacterAdded(character)
		firstLoad = true;
		for _, obj in pairs(player.PlayerGui:GetChildren()) do
			if obj:GetAttribute("OnPlayerAdded") then
				obj:Destroy();
			end
		end

		modEngineMode.OnCharacterAdded(player, character);
		modAnalytics:SyncRemoteConfigs(player);
	end
	
	player.CharacterAdded:Connect(onCharacterAdded);
	
	-- Load OnPlayerAdded
	modAnalytics:SyncRemoteConfigs(player);
	
	
	if player.Character and not firstLoad then
		onCharacterAdded(player.Character);
	end
	
	task.spawn(function()
		local followedPlayer = game.Players:GetPlayerByUserId(player.FollowUserId);
		local referrer: Player;
		if player.FollowUserId ~= 0 and followedPlayer then
			referrer = followedPlayer;
		else
			local oldestFirstJoin = os.time();
			for _, otherPlayer: Player in pairs(game.Players:GetPlayers()) do
				if otherPlayer == player then continue end;

				local isFriend = false;
				pcall(function()
					isFriend = otherPlayer:IsFriendsWith(player.UserId);
				end)
				if not isFriend then continue end;

				local otherProfile = modProfile:Get(otherPlayer);
				if otherProfile.FirstJoined < oldestFirstJoin then
					oldestFirstJoin = otherProfile.FirstJoined;
					referrer = otherPlayer;
				end
			end
		end

		if referrer == nil then
			return;
		end

		local referrerProfile = modProfile:Get(referrer);
		if #referrerProfile.ReferralList < 8 and table.find(referrerProfile.ReferralList, player.UserId) == nil then
			table.insert(referrerProfile.ReferralList, player.UserId);
		end

		local profile = modProfile:Get(player);
		if table.find(profile.ReferralList, referrer.UserId) == nil then
			table.insert(profile.ReferralList, referrer.UserId);
		end
	end)
end


local modEngineCore = require(game.ReplicatedStorage.EngineCore);
modEngineCore:ConnectOnPlayerAdded(script, OnPlayerAdded, 2);

Players.PlayerRemoving:Connect(function(player)
	--== Connections
	task.spawn(function() modSquadService.OnPlayerRemoving(player); end);
	task.spawn(function() modRemotesManager.OnPlayerRemoving(player); end);
	task.spawn(function() modEngineMode.OnPlayerRemoving(player); end);
	
	local profile = modProfile:Get(player);
	profile:Save(); -- Disconnect save
	
	local playerSave = profile and profile:GetActiveSave();
	if playerSave then playerSave.Statistics:Save(); end
	
	pcall(function()
		if profile and profile.Junk and profile.Junk.CacheInstances then
			for a=1, #profile.Junk.CacheInstances do
				if profile.Junk.CacheInstances[a] then
					profile.Junk.CacheInstances[a]:Destroy();
				end
			end
		end
	end)
	
	profile:Unload();
	task.spawn(function()
		local onlineSetS, onlineSetE = pcall(function()
			local lastOnlineData = MemoryStoreService:GetSortedMap("LastOnline");
			lastOnlineData:RemoveAsync(tostring(player.UserId));

			local accessCodeData = MemoryStoreService:GetSortedMap("AccessCode");
			accessCodeData:RemoveAsync(tostring(player.UserId));
		end)
	end)
end)


function remotePlayerDataFetch.OnServerInvoke(player, packet)
	local profile = modProfile:WaitForProfile(player);
	if profile == nil then return end;
	
	local action = packet[modRemotesManager.Ref("Action")];
	
	if action == "flagfetch" then
		local flagId = packet[modRemotesManager.Ref("Id")];
		local flagData, flagIndex = profile.Flags:Get(flagId);

		if flagData then
			return {
				[modRemotesManager.Ref("Index")]=flagIndex;
				[modRemotesManager.Ref("Data")]=flagData;
			};
		end
		
	elseif action == "eventfetch" then
		local eventId = packet[modRemotesManager.Ref("Id")];
		local eventData, eventIndex = modEvents:GetEvent(player, eventId)

		if eventData then
			return {
				[modRemotesManager.Ref("Index")]=eventIndex;
				[modRemotesManager.Ref("Data")]=eventData;
			};
		end
		
	elseif action == "npcdatafetch" then
		local npcName = packet[modRemotesManager.Ref("Id")];

		local safehomeData = profile.Safehome;
		local npcData = safehomeData:GetNpc(npcName);
		if npcData == nil then return end;

		profile:Sync("NpcTaskData/Npc/"..npcName);

		return {
			[modRemotesManager.Ref("Data")]={
				NpcData=npcData;
				NpcTasks=profile.NpcTaskData:GetTasks(npcName);
			};
		};
	end

	return;
end

remotePlayerDataSync.OnEvent:Connect(function(player, packet)
	local profile = modProfile:WaitForProfile(player);
	if profile == nil then return end;
	
	local action = packet[modRemotesManager.Ref("Action")];
	local data = packet[modRemotesManager.Ref("Data")];

	if action == "request" then
		if profile.FirstSync == nil then
			profile.FirstSync = true;
			profile:Sync();

			if profile.GameSave then
				profile.GameSave.FirstSync = true;
			end
			Debugger:Warn("First sync ("..player.Name..")");
		end
		
		local hierarchyKey = packet[modRemotesManager.Ref("HierarchyKey")];
		if hierarchyKey then
			profile:Sync(hierarchyKey);
			
		end
		
	elseif action == "savesettings" then
		if data == nil or type(data) ~= "table" then return end;

		local profile = modProfile:Get(player);
		profile:RefreshSettings(data);
		Debugger:Log("Player (",player.Name,") Saving settings.");
	end
end)


function PickUpRequest(player, interactObject, interactModule)
	if interactObject == nil or interactModule == nil then return "Invalid interact object."; end
	
	local interactData = shared.saferequire(player, interactModule);
	if interactData == nil then shared.Notify(player, "Invalid interact object.", "Negative"); return "Invalid interact object." end;
	if not interactData:CheckDebounce(player.Name, 1) then return "Interactable is on cooldown." end;
	
	local profile = modProfile:Get(player);
	local playerSave = profile and profile:GetActiveSave();
	local playerLevel = playerSave and playerSave:GetStat("Level") or 0;
		
	if interactData.LevelRequired and playerLevel < interactData.LevelRequired then return "Insufficient Mastery Level." end;
	
	interactData.Object = interactObject;
	interactData.Script = interactModule;
	
	if interactData.Type == modInteractables.Types.Pickup then
		if interactData.StorageItem then
			interactData.SharedDrop = false;
		end
		
		if interactData.SharedDrop == false and interactData.Taken then
			local takenString = tostring(interactData.Taken).." already picked it up!";
			shared.Notify(player, takenString, "Negative");
			return takenString;
		end;
		
		if interactData.Whitelist and interactData.Whitelist[player.Name] == nil then 
			shared.Notify(player, "Interact object is locked.", "Negative");
			return "Interact object locked."; 
		end
		local itemId = interactData.ItemId;
		
		
		if itemId == "Money" then
			playerSave:AddStat(itemId, interactData.Quantity or 1);
			shared.Notify(player, "You recieved $"..interactData.Quantity..".", "Reward");
			
		elseif modConfigurations.StorageInsertRequest == true then
			local storage = profile.ActiveInventory;
			
			interactData.Taken = player;

			local itemLibrary = modItemsLibrary:Find(itemId);
			local rPacket = storage:InsertRequest(interactData.StorageItem or {ItemId=itemId; Quantity=interactData.Quantity;});
			if rPacket.Success then

				local quantityRemaining = rPacket.QuantityRemaining or 0;
				if quantityRemaining > 0 then
					interactData.Taken = nil;
					interactData:SetQuantity(quantityRemaining);
					interactData:Sync();
					
				else
					game.Debris:AddItem(interactModule.Parent, 0);
					
				end
				
				local pickedUpQuantity = interactData.Quantity-quantityRemaining;
				shared.Notify(player, (pickedUpQuantity > 1 and itemLibrary.Name.." (".. pickedUpQuantity..")" or itemLibrary.Name), "PickUp")
				
				if interactData.OnPickUp then interactData.OnPickUp(player) end;
				--modOnGameEvents:Fire("OnItemPickup", player, interactData, {
				--	Storage=rPacket.Storage;
				--	StorageItem=rPacket.StorageItem;
				--});
				
			else
				game.Debris:AddItem(interactModule.Parent, 0);
				return "Failed id: "..tostring(rPacket.Failed);
			end
		else
			
			local storage = profile.ActiveInventory;
			
			if interactData.TargetStorage then
				storage = playerSave.Storages[interactData.TargetStorage];
			end
			
			if storage == nil then return ("Missing storage: ".. interactData.TargetStorage); end;
			local itemLibrary = modItemsLibrary:Find(itemId);
			
			if itemLibrary == nil then
				Debugger:Warn("Missing itemlib ", itemId);
			end
			
			if interactData.Players == nil then interactData.Players = {} end;
			
			if interactData.StorageItem then -- Unique item;
				if interactData.Taken == nil then
					local storageItem = interactData.StorageItem;
					local emptyIndex = storage:FindEmpty();
					--local hasSpace = activeInventory:SpaceCheck{
					--	ItemId=storageItem.ItemId;
					--	Data={Quantity=storageItem.Quantity;};
					--};
					
					if emptyIndex then
						interactData.Taken = player;
						if interactData.SharedDrop == false then
							game.Debris:AddItem(interactModule.Parent, 0);
						end
						
						storage:Insert(storageItem, emptyIndex);
						shared.Notify(player, (storageItem.Quantity > 1 and itemLibrary.Name.." ("..storageItem.Quantity..")" or itemLibrary.Name), "PickUp");
						
						if interactData.OnPickUp then interactData.OnPickUp(player) end;
						modOnGameEvents:Fire("OnItemPickup", player, interactData, {
							Storage=storage;
							StorageItem=storageItem;
						});
						
					else
						shared.Notify(player, storage.Id.." Storage full!", "Negative");
						return "Inventory full.";
					end
				end
				
			else
				
				local hasSpace = storage:SpaceCheck{{ItemId=interactData.ItemId; Data={Quantity=(interactData.Quantity or 1)}; }};
				if hasSpace then
					if interactData.Players[player.Name] then return "Already picked up item." end;
					interactData.Players[player.Name] = true;
					if interactData.OnPickUp then interactData.OnPickUp(player) end;
					
					local addPacket = {Quantity=interactData.Quantity;};
					
					if interactData.ItemValues then
						addPacket.Values = interactData.ItemValues;
					end
					
					storage:Add(interactData.ItemId, addPacket, function(queueEvent, storageItem)
						if interactObject.Name == "Mission1Pickup" then
							modMission:Progress(player, 1, function(mission)
								if mission.ProgressionPoint < 4 then mission.ProgressionPoint = 4; end;
							end)
						end
						
						modOnGameEvents:Fire("OnItemPickup", player, interactData, {
							Storage=storage;
							StorageItem=storageItem;
						});
						
						if playerSave.Statistics then
							playerSave.Statistics:AddStat("PickUp", interactData.ItemId, (interactData.Quantity or 1));
						end
						
						local rewardsList = modRewardsLibrary:Find(interactData.ItemId);
						if rewardsList and rewardsList.Level then
							profile:AddPlayPoints(120);
						else
							profile:AddPlayPoints(1);
						end
						
						modStorage.OnItemSourced:Fire(nil, storageItem, storageItem.Quantity);
					end);
					shared.Notify(player, interactData.Quantity > 1 and itemLibrary.Name.." ("..interactData.Quantity..")" or itemLibrary.Name, "PickUp");
					
					interactData.Taken = player;
					if interactData.SharedDrop == false then
						game.Debris:AddItem(interactModule.Parent, 0);
					end
					
					
				else
					local fitList, quantityRemaining = storage:FitStackableItem({ItemId=interactData.ItemId; Data={Quantity=(interactData.Quantity or 1)};});
					--Debugger:Log("fitList", fitList, quantityRemaining);
					
					for a=1, #fitList do
						local fitItem = fitList[a];
						
						storage:Add(fitItem.ItemId, {Quantity=fitItem.Quantity;}, function(queueEvent, storageItem)
							modOnGameEvents:Fire("OnItemPickup", player, interactData, {
								Storage=storage;
								StorageItem=storageItem;
							});
							
							modStorage.OnItemSourced:Fire(nil, storageItem,  storageItem.Quantity);
						end);
						
						shared.Notify(player, interactData.Quantity > 1 and itemLibrary.Name.." ("..fitItem.Quantity..")" or itemLibrary.Name, "PickUp");

					end
					
					if quantityRemaining > 0 then
						interactData:SetQuantity(quantityRemaining);
						interactData:Sync();
						
					end
					
					if #fitList > 0 then
						shared.Notify(player, storage.Id.." Storage full!", "Negative");
						return "Inventory full after partial pickup.", true;
						
					else
						shared.Notify(player, storage.Id.." Storage full!", "Negative");
						return "Inventory full.";
					end
				end
			end
		end
		
	elseif interactData.Type == modInteractables.Types.Collectible then
		local lib = modCollectiblesLibrary:Find(interactData.Id);
		if lib == nil then return "Unknown collectible." end;
		
		modOnGameEvents:Fire("OnItemPickup", player, interactData);
		profile:UnlockCollectible(interactData.Id);
	end
	
	return true;
end


function remotePickUpRequest.OnServerInvoke(player, interactObject, interactModule)
	if interactObject == nil then shared.Notify(player, "Interact object does not exist.", "Negative"); return "Interact object does not exist."; end;
	if not interactObject:IsDescendantOf(workspace) and not interactObject:IsDescendantOf(game.ReplicatedStorage:WaitForChild("Replicated")) then return "Interact object is illegitimate."; end;
	if player:DistanceFromCharacter(interactObject.Position) > 20 then return "Too far from object."; end;
	
	return PickUpRequest(player, interactObject, interactModule);
end;
modProfile.PickUpRequest = PickUpRequest;


local modLeaderboardService = require(game.ReplicatedStorage.Library.LeaderboardService);
function remoteGoldDonate.OnServerInvoke(player, id)
	if remoteGoldDonate:Debounce(player) then return 5; end;

	local profile = modProfile:Get(player);
	local activeSave = profile and profile:GetActiveSave();
	local traderProfile = profile and profile.Trader;
	
	local playerGold = traderProfile.Gold or 0;
	local productInfo = modGoldShopLibrary.Products:Find(id);
	
	if productInfo == nil then return 3 end;
	
	local donateAmount = productInfo.Product.Gold;
	if playerGold >= donateAmount then
		
		traderProfile:AddGold(-donateAmount);
		modAnalytics.RecordResource(player.UserId, donateAmount, "Sink", "Gold", "Usage", "donate");

		profile.DailyStats.GoldDonor = (profile.DailyStats.GoldDonor or 0) + donateAmount;
		profile.WeeklyStats.GoldDonor = (profile.WeeklyStats.GoldDonor or 0) + donateAmount;
		profile.AllTimeStats.GoldDonor = (profile.AllTimeStats.GoldDonor or 0) + donateAmount;
		
		modLeaderboardService.Update();
		
		shared.Notify(player, "Successfully donated to the development of the game!", "Reward");
		profile:AddPlayPoints(donateAmount/100);
		return 0;
	end
	
	shared.Notify(player, "Not enough Gold!", "Negative");
	return 1;
end


local fastTravelQuotes = {
	"Next stop, $Location!";
	"It's good doing business with you, $PlayerName.";
	"Buckle up, $PlayerName.";
	"This is going to be a crazy ride, $PlayerName";
}

function remotePlayerSearch.OnServerInvoke(player, searchName)
	if remotePlayerSearch:Debounce(player) then return end;
	
	local profile = modProfile:Get(player);
	if profile.PlayerSearchLimit == nil then
		profile.PlayerSearchLimit = 3;
		task.delay(60, function()
			profile.PlayerSearchLimit = nil;
		end)
	end
	
	if profile.PlayerSearchLimit > 0 then
		profile.PlayerSearchLimit = profile.PlayerSearchLimit -1;
		shared.Notify(player, "Searching for player "..searchName.."..", "Inform");
		
		local targetPlaceId, _, packet = modServerManager:RequestPlayerServer(player, searchName);
		if targetPlaceId == nil then
			shared.Notify(player, "Could not find player "..searchName.." in-game..", "Negative");
			
		else
			shared.Notify(player, searchName.." found!", "Inform");			
			return {
				UserName=searchName;
				VisitorId=packet.UserId;
				PlaceId=targetPlaceId;
			}
		end
	else
		shared.Notify(player, "Please wait one minute before retrying..", "Negative");
	end
end


local travelDebounce = {};
function remoteWorldTravelRequest.OnServerInvoke(player, travelType, data)
	if travelDebounce[player.Name] and tick()-travelDebounce[player.Name] < 30 then return end;
	travelDebounce[player.Name] = tick();
	
	local profile = modProfile:Get(player);
	
	local success = false;
	if travelType == "Social" then
		local targetName = data;
		local playerSave = profile and profile:GetActiveSave();
		local beginningMission = playerSave and playerSave.Missions:Get(1);
		
		if beginningMission and beginningMission.Type == 3 then
			success = modServerManager:TravelToPlayer(player, targetName);
		else
			shared.Notify(player, "You can't join a friend yet. Start campaign first.", "Negative");
		end
		
	elseif travelType == "TravelRequest" then
		local targetName = data;
		modServerManager:SendTravelRequest(player, targetName);
		
	elseif travelType == "AcceptTravel" then
		local targetName = data;
		modServerManager:AcceptTravelRequest(player, targetName);
		
	elseif travelType == "Interact" then
		local src = data;
		local part = src and src.Parent;
		
		if part == nil or player:DistanceFromCharacter(part:IsA("Model") and part:GetPrimaryPartCFrame().Position or part.Position) > 17 then
			return "Too far from object.";
		end;
		
		local interactData = shared.saferequire(player, src);
		if interactData then
			local profile = modProfile:Get(player);
			local activeSave = profile:GetActiveSave();
			if profile and interactData.SetSpawn and activeSave then
				activeSave.Spawn = interactData.SetSpawn;
			end
			success = modServerManager:Travel(player, interactData.WorldId);
		end;
		
	end
	travelDebounce[player.Name] = nil;
	return success;
end

-- MARK: remoteOpenStorageRequest.OnServerInvoke(player, interactObject, interactModule, storagePage)
function remoteOpenStorageRequest.OnServerInvoke(player, interactObject, interactModule, storagePage)
	--== Opening virtual storage;
	local storageItem = interactObject;
	if typeof(storageItem) == "table" and storageItem.ItemId then

		local usableItemLib = modUsableItems:Find(storageItem.ItemId);
		if usableItemLib.PortableStorage then
			local profile = modProfile:Get(player);
			
			local itemLib = modItemsLibrary:Find(storageItem.ItemId);
			local storageName = itemLib.Name;
			local storageConfig = usableItemLib.PortableStorage;
			
			local storageId = (usableItemLib.PortableStorage.StorageId)..(storagePage and "#p"..storagePage or "");
			
			--local cacheStorages = profile:GetCacheStorages();
			--local storage = storageId and (modStorage.Get(storageId, player) or cacheStorages and cacheStorages[storageId]);
			if storageId == nil then Debugger:Warn("Missing storage id", storageConfig); return end;
			
			local storage = modStorage.Get(storageId);
			if storage then
				storage.Virtual = true;
				storage:RefreshAuth(player, 60);
				
			else
				storage = modStorage.Get(storageId, player);

			end
			
			if storage then
				if storageConfig.Expandable ~= true then
					storage.Size = storageConfig.MaxSize;
				end
				storage.Values.Siid = storageItem.ID;
				storage.Virtual = true;
				modOnGameEvents:Fire("OnStorageOpen", player, storageItem);

				task.spawn(function()
					storage:Loop(function(storageItem)
						local attachmentStorage = modStorage.Get(storageItem.ID, player);
						if attachmentStorage then
							attachmentStorage:Sync();
						end
					end)
				end)

				return storage:Shrink();
				
			else
				modOnGameEvents:Fire("OnStorageOpen", player, storageItem);

				local activeSave = profile:GetActiveSave();
			
				local defaultSize = storagePage and 0 or storageConfig.Size;
				
				local newStorage;
				if activeSave == nil then return "Missing active save." end;
				if activeSave.Storages[storageId] == nil then
					activeSave.Storages[storageId] = modStorage.new(storageId, storageName, defaultSize, player);
					newStorage = activeSave.Storages[storageId];
					newStorage:InitStorage();
				end
				newStorage = activeSave.Storages[storageId];
				newStorage.Name = storageName;
				newStorage.MaxPages = storageConfig.MaxPages;
				newStorage.Page = storagePage;
				newStorage.MaxSize = storageConfig.MaxSize;
				newStorage.Size = math.clamp(activeSave.Storages[storageId].Size, defaultSize, storageConfig.MaxSize or activeSave.Storages[storageId].Size);
				newStorage.Expandable = storageConfig.Expandable;
				newStorage.Virtual = true;
				newStorage.Values.Siid = storageItem.ID;
				
				return newStorage:Shrink();
			end
		end
		
		return;
	end
	
	--== Opening physical storage;
	if interactObject == nil or interactModule == nil then
		Debugger:Warn(player.Name,", invalid storage interact object.");
		return "Invalid interact object.";
	end
	
	local interactData = shared.saferequire(player, interactModule);
	if interactData == nil then
		return "Invalid interact object.";
	end;
	
	interactData.Script = interactModule;
	if interactData.Type ~= modInteractables.Types.Storage then return "Interactable is not a storage." end;
	if not interactData:CheckDebounce(player.Name) then return "Interactable is on cooldown." end; -- Debugger:Warn(player.Name,", interactable is on cooldown.");
	if interactObject == nil or player:DistanceFromCharacter(interactObject.Position) > 20 then
		Debugger:Warn(player.Name,", Too far from object."); 
		return "Too far from object.";
	end;

	if interactObject and interactData then
		Debugger:Warn(player,"Requesting for physical storage.", interactData.StorageId);

		local profile = modProfile:Get(player);
		local gameSave = profile:GetActiveSave();
		
		if interactData.Whitelist and interactData.Whitelist[player.Name] == nil then
			Debugger:Warn(player.Name,", Interact object locked..");
			return "Interact object locked.";
		end
		
		if interactData.LevelRequired and interactData.LevelRequired > (gameSave:GetStat("Level") or 0) then
			Debugger:Warn(player.Name,", underleveled.");
			return "Interact object locked.";
		end
		
		local storageConfig = interactData.Configurations;
		if storageConfig.MaxPages and storageConfig.MaxPages >= 2 and storagePage then
			storagePage = math.clamp(storagePage, 2, storageConfig.MaxPages);
		end
		
		local storageId = interactData.StorageId..(storagePage and "#p"..storagePage or "");
		if storageId == nil then
			Debugger:Warn("Missing storage id", interactData);
			return "Missing storage";
		end

		local defaultSize = storageConfig.Size or 1;
		if storageConfig.Expandable and storagePage then
			defaultSize = 0;
		end
		
		local storage = modStorage.Get(storageId);
		if storage then
			storage.Physical = interactObject;
			storage:RefreshAuth(player, 60);
			
		else
			storage = modStorage.Get(storageId, player);
			
		end
		interactData:Sync();
		
		if storage then
			modOnGameEvents:Fire("OnStorageOpen", player, interactData);

			task.spawn(function()
				storage:Loop(function(storageItem)
					local attachmentStorage = modStorage.Get(storageItem.ID, player);
					if attachmentStorage then
						attachmentStorage:Sync();
					end
				end)
			end)
			
			if interactData.Configurations.Persistent then
				storage.MaxPages = storageConfig.MaxPages;
				storage.Page = storagePage;
				storage.MaxSize = storageConfig.MaxSize;
				storage.Size = math.clamp(storage.Size, defaultSize, storageConfig.MaxSize or storage.Size);
				storage.Expandable = storageConfig.Expandable;
				
				if storageConfig.Settings then
					for k, v in pairs(storageConfig.Settings) do
						if storage.Settings[k] ~= nil then
							storage.Settings[k] = v;
						end
					end
				end
			end
			
			return storage:Shrink();
			
		elseif storage == nil and interactData.Configurations then
			modOnGameEvents:Fire("OnStorageOpen", player, interactData);
			
			local publicStorage = interactData.Configurations.PublicStorage;
			local storageOwner = publicStorage ~= true and player or nil;
			
			
			if interactData.Configurations.Persistent then
				local activeSave = profile:GetActiveSave();
				
				if activeSave == nil then return "Missing active save." end;
				if activeSave.Storages[storageId] == nil then
					activeSave.Storages[storageId] = modStorage.new(storageId, interactData.StorageName, defaultSize, storageOwner);
					
					if interactData.OnNewStorage then
						interactData:OnNewStorage(activeSave.Storages[storageId]);
					end
				end
				
				local newStorage = activeSave.Storages[storageId];
				newStorage.MaxPages = storageConfig.MaxPages;
				newStorage.Page = storagePage;
				newStorage.MaxSize = storageConfig.MaxSize;
				newStorage.Size = math.clamp(activeSave.Storages[storageId].Size, defaultSize, storageConfig.MaxSize or activeSave.Storages[storageId].Size);
				newStorage.Expandable = storageConfig.Expandable;
				newStorage.Physical = interactObject;
				newStorage:RefreshAuth(player, 60);

				if storageConfig.Settings then
					for k, v in pairs(storageConfig.Settings) do
						if newStorage.Settings[k] ~= nil then
							newStorage.Settings[k] = v;
						end
					end
				end
				
				return newStorage:Shrink();
				
			else
				local cacheStorages = profile:GetCacheStorages();
				cacheStorages[storageId] = modStorage.new(storageId, interactData.StorageName, defaultSize, storageOwner);
				cacheStorages[storageId].Physical = interactObject;
				if storageConfig.Settings then
					for k, v in pairs(storageConfig.Settings) do
						if cacheStorages[storageId].Settings[k] ~= nil then
							cacheStorages[storageId].Settings[k] = v;
						end
					end
				end
				
				if interactData.OnNewStorage then
					interactData:OnNewStorage(cacheStorages[storageId]);
				end
				
				return cacheStorages[storageId]:Shrink();
			end
			
		else
			return "Invalid storage.";
		end
	else
		return "Invalid interact object.";
	end
end


function remoteEnterDoorRequest.OnServerInvoke(player, interactObject, interactModule)
	if remoteEnterDoorRequest:Debounce(player) then return end;
	if interactObject == nil or interactModule == nil then return "Invalid interact object."; end
	
	local interactData = shared.saferequire(player, interactModule);
	if interactData == nil then return "Invalid interact object." end;
	
	if not interactData:CheckDebounce(player.Name) then return "Interactable is on cooldown." end;

	local distanceFromDoor = interactObject and player:DistanceFromCharacter(interactObject.Position) or -1;
	if interactObject == nil or distanceFromDoor > (interactData.MaxEnterDistance or 20) then Debugger:Warn(player.Name,"Too far from door. ("..distanceFromDoor..")"); return "Too far from object."; end;
	if interactObject and interactModule then
		local profile = modProfile:Get(player);
		
		interactData.Object = interactObject;
		local doorName = interactData.Name;
		local premiumOnly = interactData.Premium;
		
		if premiumOnly and not profile.Premium then return "Not Premium"; end
		
		local destination = interactObject:FindFirstChild("Destination")

		if interactModule:FindFirstChild("CustomDestination") then
			destination = interactModule.CustomDestination.Value;
		end
		if destination then
			local sound = modAudio.Play(interactData.EnterSound, destination); 
			if sound then sound.PlaybackSpeed = math.random(7, 12)/10; end;
			
			local tpCframe = CFrame.new(destination.WorldPosition + Vector3.new(0, 2.35, 0)) * CFrame.Angles(0, math.rad(destination.WorldOrientation.Y-90), 0);
			shared.modAntiCheatService:Teleport(player, tpCframe);
		end
		
		modOnGameEvents:Fire("OnDoorEnter", player, interactData);
	else
		return "Invalid interact object.";
	end
end


function remoteOnTrigger.OnServerInvoke(player, interactObject, interactModule, packet)
	packet = packet or {};
	local profile = modProfile:Get(player);
	
	if profile.Cache.remoteOnTriggerCd and tick()-profile.Cache.remoteOnTriggerCd <= 0.5 then return "Activate on cooldown." end;
	profile.Cache.remoteOnTriggerCd = tick();
	
	local distanceFromTrigger = interactObject and player:DistanceFromCharacter(interactObject.Position) or -1;
	if interactObject == nil or distanceFromTrigger > 20 then Debugger:Warn(player.Name,"Too far from trigger. ("..distanceFromTrigger..")"); return "Too far from object."; end;
	if interactObject and interactModule then
		
		local interactData = shared.saferequire(player, interactModule);
		if interactData == nil then return "Invalid interact object." end;
		
		interactData.Object = interactObject;
		interactData.Script = interactModule;
		modOnGameEvents:Fire("OnTrigger", player, interactData, packet);
	else
		return "Invalid interact object.";
	end
	return;
end


remoteInteractableToggle.OnServerEvent:Connect(function(player, interactObject, interactModule)
	local distanceFromTrigger = interactObject and player:DistanceFromCharacter(interactObject.Position) or -1;
	if interactObject == nil or distanceFromTrigger > 20 then Debugger:Warn(player.Name,"Too far from toggle. ("..distanceFromTrigger..")"); return "Too far from object."; end;
	if interactObject and interactModule then
		
		local interactData = shared.saferequire(player, interactModule);
		if interactData == nil then return "Invalid interact object." end;
		
		interactData.Object = interactObject;
		interactData.Script = interactModule;
		
		if interactData.OnToggle then
			modOnGameEvents:Fire("OnToggle", player, interactData);
			interactData:OnToggle(player);
		end
	else
		return "Invalid interact object.";
	end
end)


function remoteUpgradeStorage.OnServerInvoke(player, storageId)
	local profile = modProfile:Get(player);
	local activeSave = profile and profile:GetActiveSave();
	local storage = storageId and modStorage.Get(storageId, player);
	
	if storage and storage.Expandable and storage.Size < storage.MaxSize then
		local newSize = storage.Size+1;
		local cost = modWorkbenchLibrary.StorageCost(storageId, storage.Size);
		local playerCurrency = activeSave and activeSave.GetStat and activeSave:GetStat("Perks");
		if playerCurrency-cost >= 0 then
			activeSave:AddStat("Perks", -cost);
			modAnalytics.RecordResource(player.UserId, cost, "Sink", "Perks", "Gameplay", "StorageUpgrade");
			storage.Size = newSize;
			storage.OnChanged:Fire(storage);
			
			profile:AddPlayPoints(cost);
			return storage:Shrink();
		else
			return 2;
		end
	else
		return 1;
	end	
end

function remoteMailboxFunction.OnServerInvoke(player, index, action)
	local profile = modProfile:Get(player);
	
	if profile.Cache.remoteMailboxFunctionDebounce then return end;
	profile.Cache.remoteMailboxFunctionDebounce = true;
	
	if index == nil then Debugger:WarnClient(player, "Missing Mail Index"); return end;
	local profile = modProfile:Get(player);
	local activeSave = profile and profile:GetActiveSave();
	local successful = nil;
	
	if activeSave and index <= #activeSave.Mailbox then
		local mailData = activeSave.Mailbox[index];
		if mailData.Type == 1 then
			if mailData.Data.Amount and mailData.Data.Amount > 0 then
				activeSave:AddStat("Perks", mailData.Data.Amount);
			end
			successful = true;
			
		elseif mailData.Type == 2 then
			activeSave:AddStat("Perks", 10);
			successful = true;
			
		elseif mailData.Type == 3 then
			local activeInventory = profile.ActiveInventory;
			if activeInventory then
				if mailData.Data and mailData.Data.ItemId then
					local itemId = mailData.Data.ItemId;
					local itemLib = modItemsLibrary:Find(itemId);
					if itemLib then
						if activeInventory:SpaceCheck{{ItemId=itemId}} then
							activeInventory:Add(itemId, nil, function(event, insert)
								shared.Notify(player, string.gsub("You recieved a $Item.", "$Item", itemLib.Name), "Reward");
							end);
							successful = true;
						else
							successful = "Inventory full!";
						end
					else
						successful = "Invalid item id ("..itemId..")";
					end
				end
			end
			
		elseif mailData.Type == 4 then
			if modEvents:GetEvent(player, "masteryLevelReward") == nil then
				if mailData.Data.Amount and mailData.Data.Amount > 0 then
					activeSave:AddStat("Perks", mailData.Data.Amount);
				end
				modEvents:NewEvent(player, {Id="masteryLevelReward"});
			end
			successful = true;
			
		elseif mailData.Type == 5 then
			-- Referral Complete
			successful = true;
			
		elseif mailData.Type == 6 then
			activeSave:AddStat("TweakPoints", mailData.Data.Amount);
			shared.Notify(player, "You recieved "..mailData.Data.Amount.." tweak points.", "Reward");
			successful = true;
			
		elseif mailData.Type == 99 then
			if action == "Claim" then
				successful = true;
				local weapons = mailData.Data.Weapons;
				if weapons then
					local activeInventory = profile.ActiveInventory;
					if activeInventory then
						local itemsCheck = {};
						for weaponName, _ in pairs(weapons) do
							local itemLib = modItemsLibrary:Find(weaponName);
							if itemLib then
								local itemId = itemLib.Id;
								table.insert(itemsCheck, {ItemId=itemId});
							end
						end
						if activeInventory:SpaceCheck(itemsCheck) then
							for a=1, #itemsCheck do
								if itemsCheck[a] then
									local itemLib = modItemsLibrary:Find(itemsCheck[a].ItemId);
									activeInventory:Add(itemsCheck[a].ItemId, nil, function(event, insert)
										shared.Notify(player, string.gsub("You recieved a $Item.", "$Item", itemLib.Name), "Reward");
									end);
								end
							end
						else
							successful = "Not enough inventory space.";
						end
					end
				end
				--local blueprints = mailData.Data.Blueprints;
				--if blueprints then
				--	local userBlueprints = activeSave.Blueprints;
				--	for bpName,_ in pairs(blueprints) do
				--		local bpLib = :FindByName(bpName);
				--		if bpLib then
				--			userBlueprints:UnlockBlueprint(bpLib.Id);
				--			mailData.Data.Blueprints[bpName] = nil;
				--		end
				--	end
				--	mailData.Data.Blueprints = {};
				--end
			elseif action == "Destroy" then
				successful = true;
			end
		else
			Debugger:Log("Missing mail type function");
		end
		if successful == true then
			table.remove(activeSave.Mailbox, index);
		end
		activeSave:SyncMail();
	end
	
	profile.Cache.remoteMailboxFunctionDebounce = nil;
	return successful;
end

local function isGameOnline()
	local isGameOnline = false;
	local s, e = pcall(function()
		isGameOnline = game:GetService("DataStoreService"):GetDataStore("LiveConfig"):GetAsync("Online") ~= false
		workspace:SetAttribute("IsGameOnline", isGameOnline);
	end)
	return isGameOnline;
end
task.spawn(function()
	if modBranchConfigs.IsWorld("MainMenu") then
		while true do
			isGameOnline();
			task.wait(5);
		end
	end
end)


local remotePromptWarning = remotes.Interface.PromptWarning;
local enterCampaignDebounce = {};
remoteEnterCampaign.OnServerEvent:Connect(function(player, followName)
	if enterCampaignDebounce[player.Name] and tick()-enterCampaignDebounce[player.Name] <= 1 then return end;
	enterCampaignDebounce[player.Name] = tick();
	
	
	local profile = modProfile:Get(player);
	if profile == nil then
		modServerManager:TeleportToPrivateServer("MainMenu", modServerManager:CreatePrivateServer("MainMenu"), {player});
		return;
	end

	local isGameOnline = false;
	local s, e = pcall(function()
		isGameOnline = game:GetService("DataStoreService"):GetDataStore("LiveConfig"):GetAsync("Online") ~= false
	end)
	if not s then
		Debugger:Warn("LiveConfig>>  ", e);
	end

	if not isGameOnline then
		if profile == nil or (profile.GroupRank or 0) < 100 then
			remotePromptWarning:FireClient(player, "Servers are currently under maintenance, please wait.", true);
			return;
		else
			shared.Notify(player, "Joining maintenance servers as Rank:"..(profile.GroupRank or 0), "Inform");
		end
	end
	
	local saveData = profile:GetActiveSave();
	if saveData then
		if game.PlaceId == modBranchConfigs.CurrentBranch.Worlds.MainMenu then
			local beginningMission = saveData.Missions:Get(1);
			
			if beginningMission and beginningMission.Type == 3 then
				if followName and followName ~= "/solo" then
					local success = modServerManager:TravelToPlayer(player, followName);
					if success then return end;
				end
				local spawnId = saveData.Spawn;
				local worldId = modBranchConfigs.GetWorldOfSpawn(spawnId);
				
				if followName == "/solo" then
					if worldId == nil then
						shared.Notify(player, "Invalid SpawnId ("..spawnId.."), spawning in the warehouse.", "Negative");
						worldId = "TheWarehouse";
					end
					modServerManager:Travel(player, worldId);
				end
				
			else
				saveData.Missions:Start(1);
				
				remoteSetLoadLabel:FireClient(player, "You hear the sound of thunder...");
				modServerManager:Teleport(player, "TheBeginning");
			end
		end
	else
		warn("Player(",player.Name,") does not have any savedata.");
	end
end);


remoteKeypadInput.OnServerEvent:Connect(function(player, interactObject, input)
	local distanceFromTrigger = interactObject and player:DistanceFromCharacter(interactObject.Position) or -1;
	if interactObject == nil or distanceFromTrigger > 20 then Debugger:Warn(player.Name,"Too far from trigger. ("..distanceFromTrigger..")"); return "Too far from object."; end;
	if interactObject and interactObject:FindFirstChild("Interactable") then
		
		local interactData = shared.saferequire(player, interactObject.Interactable);
		if interactData == nil then return "Invalid interact object." end;
		
		interactData.Object = interactObject;
		interactData.Script = interactObject.Interactable;
		modOnGameEvents:Fire("OnTrigger", player, interactData, input);
	else
		return "Invalid interact object.";
	end
end)

remoteDuelRequest.OnServerEvent:Connect(function(player, requestType, targetName)
	local classPlayerSpeaker = modPlayers.Get(player);
	local speakerPvp = classPlayerSpeaker.Properties.Pvp;
	if speakerPvp == nil then
		classPlayerSpeaker.Properties.Pvp = {};
		speakerPvp = classPlayerSpeaker.Properties.Pvp;
	end
	
	if speakerPvp.Requesting and os.time()-speakerPvp.Requesting < 60 then
		shared.Notify(player, "You pvp request is on cooldown for ".. 60-(os.time()-speakerPvp.Requesting) .."s.", "Negative");
		return false;
	end
		
	if player.Name == targetName then
		shared.Notify(player, "You can't duel yourself.", "Negative"); 
		return false;
	end;
	
	local targetPlayer = game.Players:FindFirstChild(targetName);
	if targetPlayer then
		local classPlayerTarget = modPlayers.Get(targetPlayer);
		local targetPvp = classPlayerTarget.Properties.Pvp;
		if targetPvp and targetPvp.InDuel == nil and targetPvp.Name == player.Name and os.time()-targetPvp.Requesting <= 30 then
			local players = {player, targetPlayer};
			shared.Notify(game.Players:GetPlayers(), "A duel has broke out between "..targetPlayer.Name.." and "..player.Name..".", "Defeated");
			for a=5, 1, -1 do
				shared.Notify(players, "The duel begins in "..a..".", "Defeated");
				wait(1);
			end
			shared.Notify(players, "The duel has begun!", "Defeated");
			targetPvp.InDuel = player.Name;
			speakerPvp.InDuel = targetPlayer.Name;
			speakerPvp.DmgMultiplier = targetPvp.DmgMultiplier;
			
		else
			speakerPvp.Requesting = os.time();
			speakerPvp.Name = targetPlayer.Name;
			speakerPvp.DmgMultiplier = 1;
			shared.Notify(player, "Requesting "..targetPlayer.Name.." to a duel..\nThe request will expire in 30 seconds.", "Defeated");
			shared.Notify(targetPlayer, player.Name.." is requesting you to a duel..", "Defeated");
			remoteDuelRequest:FireClient(targetPlayer, "request", player.Name);
			
		end
	else
		shared.Notify(player, "Could not find player ("..targetName..")..", "Negative");
		
	end
end)

remoteRequestResetData.OnServerEvent:Connect(function(player)
	local profile = modProfile:Get(player);
	--profile.ActiveSave = nil;
	--profile.Saves = {};
	
	profile:ResetSave();
	profile.Reset = true;
	modServerManager:Travel(player, "MainMenu");
	shared.Notify(player, "Data reset complete.", "Positive");
end)

function remoteGeneralUIRemote.OnServerInvoke(player, action)
	if remoteGeneralUIRemote:Debounce(player) then return end;
	
	local profile = modProfile:Get(player);
	local saveData = profile:GetActiveSave();
	local playerFlags = profile.Flags;
	
	if action == "closeupdatelog" then
		modEvents:NewEvent(player, {Id="seenupdatelog"});
	end
end


function remoteLockHydra.OnServerInvoke(player, action, interactData, ...)
	if interactData == nil then return end;

	local interactObject: BasePart = interactData.Object;
	local interactModule: ModuleScript = interactData.Script;
	
	local interactableModel = interactObject.Parent;
	
	while interactableModel:GetAttribute("InteractableParent") == true do
		interactableModel = interactableModel.Parent;
	end
	
	if not interactableModel:IsAncestorOf(interactModule) then Debugger:Warn("Invalid Interactable.") return end;

	local interactData = shared.saferequire(player, interactModule);
	if interactData == nil then return "Invalid interact object." end;

	interactData.Object = interactObject;
	interactData.Script = interactModule;

	if interactData.Type ~= "Terminal" then return "Invalid interact object." end;

	modOnGameEvents:Fire("OnLockHydra", player, action, interactData);
end

modStorage.OnItemSourced:Connect(function(sourceStorage, storageItem, quantity)
	if modBranchConfigs.CurrentBranch.Name == "Dev" then
		Debugger:Warn("src Store", (sourceStorage and sourceStorage.Id or nil), "itemId",storageItem.ItemId, "amt", quantity);
	end
	if quantity <= 0 then
		Debugger:Warn("OnItemSource ",storageItem.ItemId," quantity <= 0");
		return;
	end
	
	modEconomyAnalytics.Record(storageItem.ItemId, quantity);
end)

modStorage.OnItemSunk:Connect(function(sourceStorage, storageItem, quantity)
	quantity = -quantity;

	if modBranchConfigs.CurrentBranch.Name == "Dev" then
		Debugger:Warn("sink Store", (sourceStorage and sourceStorage.Id or nil), "itemId",storageItem.ItemId, "amt", quantity);
	end
	if quantity >= 0 then
		Debugger:Warn("OnItemSunk ",storageItem.ItemId," quantity >= 0");
		return;
	end
	
	modEconomyAnalytics.Record(storageItem.ItemId, quantity);
end)


task.spawn(function()
	while true do
		task.wait(60);
		if modBranchConfigs.IsWorld("MainMenu") then
			Debugger:Warn("LiveProfile Update disabled for menu.");
			continue;
		end;
		
		local players = game.Players:GetPlayers();
		for _, player in pairs(players) do
			local onlineSetS, onlineSetE = pcall(function()
				local lastOnlineData = MemoryStoreService:GetSortedMap("LastOnline");
				lastOnlineData:SetAsync(tostring(player.UserId), DateTime.now().UnixTimestamp, 61);

				local accessCodeData = MemoryStoreService:GetSortedMap("AccessCode");

				if modServerManager.AccessCode then
					accessCodeData:SetAsync(tostring(player.UserId), modServerManager.AccessCode, 61);
				else
					accessCodeData:RemoveAsync(tostring(player.UserId));
				end
			end)
		end
	end
end)
	
game:BindToClose(function()
	if RunService:IsStudio() then return end;
	task.wait();
	local threads = {};
	
	for playerName, profile in pairs(modProfile.Profiles) do
		if profile ~= nil then
			threads[playerName] = false;
			task.spawn(function()
				profile:Save(); -- Shutdown save;
				Debugger:Log("Profile(",playerName,") shutdown save completed.");
				threads[playerName] = true;
			end)
		end
	end
	
	local done = true;
	repeat
		done = true;
		for name, complete in pairs(threads) do
			if not complete then
				done = false;
				break;
			end
		end
		task.wait();
	until done;
	
	Debugger:Log("All profiles shutdown save completed.");
	task.wait(0.5);
end);

modCutscene.Init();
modCharacterAppearance.Init();

Debugger:Log("Initialized server master script.");
shared.MasterScriptInit = true;

if modBranchConfigs.CurrentBranch.Name == "Dev" then
	workspace:SetAttribute("IsDev", true);
	if RunService:IsStudio() then return end;
	
	ScriptContext.Error:Connect(function(message, trace, scr)
		if scr == nil then return end;
		if scr:GetAttribute("SuppressWarnClient") == true then return end;

		if message == nil then return end;
		if message:match("resume") and message:match("coroutine") then return end;

		Debugger:WarnClient(game.Players:GetPlayers(), scr.Name ..">> [ERROR] ".. message .. "\n".. trace);
	end)
end