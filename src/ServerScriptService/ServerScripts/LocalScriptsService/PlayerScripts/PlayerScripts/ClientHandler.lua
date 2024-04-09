local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
return function()
	Debugger:Log("Initializing client data script.");
	--== Configuration;

	--== Variables;
	local CollectionService = game:GetService("CollectionService");
	local UserInputService = game:GetService("UserInputService");
	local HttpService = game:GetService("HttpService");
	local RunService = game:GetService("RunService");
	local PhysicsService = game:GetService("PhysicsService");
	local LogService = game:GetService("LogService");
	local localPlayer = game.Players.LocalPlayer;
	local StarterGui = game.StarterGui;

	local dataModule = localPlayer:WaitForChild("DataModule"); --script:WaitForChild("DataModule"):Clone(); dataModule.Parent = player;
	local modGlobalVars = require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
	local modAssetHandler = require(game.ReplicatedStorage.Library.AssetHandler); modAssetHandler.init();
	local modInfoBubbles = require(game.ReplicatedStorage.Library.InfoBubbles);
	local modPlayers = require(game.ReplicatedStorage.Library.Players);
	local modRemotesManager = require(game.ReplicatedStorage:WaitForChild("Library", 60):WaitForChild("RemotesManager", 60));
	local modReplicationManager = require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("ReplicationManager"));
	local modConfigurations = require(game.ReplicatedStorage:WaitForChild("Library"):WaitForChild("Configurations"));
	local modBranchConfigurations = require(game.ReplicatedStorage.Library.BranchConfigurations);
	local modInteractable = require(game.ReplicatedStorage.Library.Interactables);
	local modColorsLibrary = require(game.ReplicatedStorage.Library:WaitForChild("ColorsLibrary"));
	local modMissionLibrary = require(game.ReplicatedStorage.Library:WaitForChild("MissionLibrary"));
	local modSkinsLibrary = require(game.ReplicatedStorage.Library:WaitForChild("SkinsLibrary"));
	local modCollectiblesLibrary = require(game.ReplicatedStorage.Library.CollectiblesLibrary);
	local modKeyBindsHandler = require(game.ReplicatedStorage.Library.KeyBindsHandler);
	local modBranchConfigs = require(game.ReplicatedStorage.Library.BranchConfigurations);
	local modSettings = require(game.ReplicatedStorage.Library.Settings);
	local modTableManager = require(game.ReplicatedStorage.Library.TableManager);
	
	local modModsLibrary = require(game.ReplicatedStorage.Library.ModsLibrary);
	local modItemLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);

	local modItemInterface = require(game.ReplicatedStorage.Library.UI.ItemInterface);
	local modStorageInterface = require(game.ReplicatedStorage.Library.UI.StorageInterface);
	Debugger:Log("Dependencies loaded.");
	
	local remotes = game.ReplicatedStorage.Remotes;
	--== Remote: Syncronization;
	local remotePlayerDataSync = modRemotesManager:Get("PlayerDataSync");
	local remoteGoldStatSync = modRemotesManager:Get("GoldStatSync");
	local remoteStorageItemSync = modRemotesManager:Get("StorageItemSync");
	
	local remoteMasterySync = modRemotesManager:Get("MasterySync");
	local remoteStorageSync = modRemotesManager:Get("StorageSync");
	local remoteStorageDestroy = modRemotesManager:Get("StorageDestroy");
	
	local remoteMailboxSync = remotes.Interface.MailboxSync;
	local remoteMissionsSync = remotes.Interface.MissionsSync;
	local remoteTogglePlayer = remotes.TogglePlayer;
	local remoteSquadSync = modRemotesManager:Get("SquadSync");
	local remoteBodyEquipmentsSync = modRemotesManager:Get("BodyEquipmentsSync");
	local remoteInteractableSync = modRemotesManager:Get("InteractableSync");
	local remoteInteractionUpdate = modRemotesManager:Get("InteractionUpdate");
	local remoteTradeRequest = modRemotesManager:Get("TradeRequest");
	local remoteDuelRequest = modRemotesManager:Get("DuelRequest");
	local remoteTravelRequest = modRemotesManager:Get("TravelRequest");
	local remoteStorageService = modRemotesManager:Get("StorageService");
	local remoteGameModeAssign = modRemotesManager:Get("GameModeAssign");
	local remoteMissionRemote = modRemotesManager:Get("MissionRemote");
	
	--== Bind:
	local bindOpenLobbyInterface = remotes.LobbyInterface.OpenLobbyInterface;
	
	--
	local modData = require(dataModule);
	
	LogService.MessageOut:Connect(function(message, messageType)
		--Validate
		if messageType ~= Enum.MessageType.MessageError then return end		
		if message:match("Failed to load") then return end;
		if message:match("HTTP") then return end;
		if message:match("LoadAnimation") then return end;
		if message:match("Provider") then return end;
		if message:match("CoreGui") then return end;
		if message:match("roblox") then return end;
		if message:match("Roblox") then return end;
		if message:match("tween") then return end;
		
		--Report
		local ver = modGlobalVars.GameVersion.."."..modGlobalVars.GameBuild;
		local errorMsg = "["..ver.."] "..message;
		
		for a=#modData.ErrorLogs, 1, -1 do
			if modData.ErrorLogs[a] == errorMsg then
				table.remove(modData.ErrorLogs, a);
			end
		end
		table.insert(modData.ErrorLogs, 1, errorMsg);
		
		if #modData.ErrorLogs >= 10 then
			table.remove(modData.ErrorLogs, 10);
		end
	end)
	
	local otherCharacter = workspace:FindFirstChild("Characters") or Instance.new("Folder");
	otherCharacter.Name = "Characters";
	otherCharacter.Parent = workspace;
	
	local hiddenCharacter = game.ReplicatedStorage:FindFirstChild("HiddenCharacters") or Instance.new("Folder");
	hiddenCharacter.Name = "HiddenCharacters";
	hiddenCharacter.Parent = game.ReplicatedStorage;
	
	spawn(function()
		local worldClips = workspace:WaitForChild("Clips", 60);
		local function loadClip(obj)
			if obj:IsA("BasePart") then
				if obj.Name == "_playerClip" or obj.Name == "_Void" then
					obj.CanCollide = true;
				end
			elseif obj:IsA("Model") then
				for _, modelObj in pairs(obj:GetChildren()) do
					loadClip(modelObj);
				end
			end
		end
		wait(5);
		for _, obj in pairs(worldClips:GetChildren()) do
			loadClip(obj)
		end
		worldClips.ChildAdded:Connect(function(obj)
			RunService.Heartbeat:Wait();
			loadClip(obj)
		end);
		
	end)
	
	local hiddenPlayers = {}; local hideAllPlayers = false;
	
	--== Script;
	
	
	local function GetInterfaceModule()
		return modData:GetInterfaceModule();
	end
	
	
	local modModEngineService = require(game.ReplicatedStorage.Library:WaitForChild("ModEngineService"));
	local moddedSelf = modModEngineService:GetModule(script.Name);
	if moddedSelf then moddedSelf:Init(); end
	
	local playerDataSyncRequest = {
		[modRemotesManager.Ref("Action")] = "request";
	};
	
	local function syncedRefresh()
		if modData.Profile == nil then return end;
		modData.IsPremium = modData.Profile.Premium;
		modData.GameSave = modData.Profile.GameSave;
		
		if modData.Profile.ColorPacks then
			for packName, pack in pairs(modData.Profile.ColorPacks) do
				if modColorsLibrary.Packs[packName] then
					modColorsLibrary.Packs[packName].Owned = modColorsLibrary.Packs[packName];
				end
			end
		end
		
		if modData.Profile.SkinsPacks then
			for packName, pack in pairs(modData.Profile.SkinsPacks) do
				if modSkinsLibrary.Packs[packName] then
					modSkinsLibrary.Packs[packName].Owned = modSkinsLibrary.Packs[packName];
				end
			end
		end
		
		if modData.GameSave then
			--if modData.GameSave.Storages then
			--	for id, _ in pairs(modData.GameSave.Storages) do
			--		local storage = modData.GameSave.Storages[id];
			--		modData.SetStorage(storage);
			--		modStorageInterface.UpdateStorages({storage});
			--	end
			--end
			
			task.spawn(function()
				local modInterface = GetInterfaceModule();
				
				if modInterface then
					modInterface:CallBind("UpdateStats");
					modInterface:CallBind("UpdateMissions");
					modInterface:CallBind("UpdateMailbox");
				end
			end)
		end
		
		if modData.Profile.Settings then
			for k, v in pairs(modData.Profile.Settings) do
				modData.Settings[k] = v;
				if typeof(v) ~= "table" and typeof(v) ~= "Instance" then
					dataModule:SetAttribute("Settings".. k, v);
				end
			end;
			for k, v in pairs(dataModule:GetAttributes()) do
				if k:sub(1, 8) == "Settings" then
					local key = k:gsub("Settings", "");
					if modData.Settings[key] == nil then
						dataModule:SetAttribute(k, nil);
					end
				end
			end
			dataModule:SetAttribute("SettingsLoaded", true);
		end
		
		if modData.OnGoldUpdate and modData.Profile and modData.Profile.Trader and modData.Profile.Trader.Gold then
			modData.PlayerGold = modData.Profile.Trader.Gold;
			modData.OnGoldUpdate:Fire(modData.Profile.Trader.Gold);
		end
		
	end
	
	local sendDataRequest = true;
	remotePlayerDataSync.OnEvent:Connect(function(packet)
		local action = packet[modRemotesManager.Ref("Action")];
		local id = packet[modRemotesManager.Ref("Id")];
		local data = packet[modRemotesManager.Ref("Data")];
		local hierarchyKey = packet[modRemotesManager.Ref("HierarchyKey")];
		
		sendDataRequest = false;
		
		if action == "sync" then
			if hierarchyKey == nil then
				Debugger:Warn("Missing hierarchy key");
				return;
			end
			
			local dataKey = modTableManager.SetDataHierarchy(modData.Profile, data, hierarchyKey, true);
			modData.GameSave = modData.Profile.GameSave;

			if hierarchyKey == "GameSave/Missions" then
				local modInterface = GetInterfaceModule();
				if modInterface then
					modInterface:CallBind("UpdateMissions", modData.GameSave.Missions);
				end

			elseif hierarchyKey == "GameSave/Mailbox" then
				local modInterface = GetInterfaceModule();
				if modInterface then
					modInterface:CallBind("UpdateMailbox", modData.GameSave.Mailbox);
				end

			elseif hierarchyKey == "Cache/AuthSeed" then
				modData.ShotIdGen = Random.new(modData.Profile.Cache.AuthSeed);

			elseif hierarchyKey == "Trader/Gold" then
				if modData.OnGoldUpdate and modData.Profile and modData.Profile.Trader and modData.Profile.Trader.Gold then
					modData.PlayerGold = modData.Profile.Trader.Gold;
					modData.OnGoldUpdate:Fire(modData.Profile.Trader.Gold);
				end

			elseif hierarchyKey == "Settings" then
				Debugger:Warn("Sync Settings data");
				
				if packet.Reset == true then
					for k, _ in pairs(modData.Settings) do
						modData.Settings[k] = nil;
					end
					modData.Settings.ZoomLevel=8;

					for k, v in pairs(modKeyBindsHandler.DefaultKeybind) do
						if k == "__index" then continue end;

						modKeyBindsHandler:SetKey(k);
					end

				end
				
				Debugger:Warn("data", data);
				modData.UpdatePickupCache();
				
			end
			
		elseif action == "syncevent" then
			data.LastFetch = tick();
			modData.Events[data.Id] = data;
			
		elseif action == "destroyevent" then
			local id = packet[modRemotesManager.Ref("Data")];
			modData.Events[id] = nil;
			
		end
		
		modData.OnDataEvent:Fire(action, hierarchyKey, data);
	end)
	
	
	modData.OnDataEvent:Connect(function(action, hierarchyKey, data)
		if action ~= "sync" then return end;
		
		task.delay(0.1, function()
			local modInterface = GetInterfaceModule();
			if modInterface then
				modInterface:CallBind("UpdateStats");
			end
		end)
		syncedRefresh();
		
		--if hierarchyKey == "Collectibles" then
		--	local collectiblesData = modTableManager.GetDataHierarchy(modData.Profile, "Collectibles");

		--	local interactablesFolder = game.Workspace:FindFirstChild("Interactables");
		--	if interactablesFolder and data then
		--		for id, _ in pairs(data) do
		--			local lib = modCollectiblesLibrary:Find(id);
		--			if lib == nil then continue end;

		--			local obj = interactablesFolder:FindFirstChild("(Collectible)"..lib.Name);
		--			if obj then game.Debris:AddItem(obj, 0); end
		--		end
		--	end
		--end
	end)

	local function onCharacterAdded(character)
		local modCharacter = modData:GetModCharacter();
		local humanoid = character:WaitForChild("Humanoid");

		remotePlayerDataSync:Fire(playerDataSyncRequest);

		modCharacter.CharacterProperties.ZoomLevel = modData.Settings.ZoomLevel;

		if moddedSelf then
			moddedSelf.OnCharacterAdded(character);
		end
	end


	local classPlayer = shared.modPlayers.Get(localPlayer);
	classPlayer.Died:Connect(function(character)
		local modCharacter = modData:GetModCharacter();
		if modCharacter then
			modData.Settings.ZoomLevel = modCharacter.CharacterProperties.ZoomLevel;
		end

		modData:SaveSettings(true);

		if moddedSelf then
			moddedSelf.OnCharacterDied(character);
		end
	end)


	if localPlayer.PlayerGui:FindFirstChild("ChatInterface") == nil then
		local newChatInterface = game.ReplicatedStorage.PlayerGui:WaitForChild("ChatInterface"):Clone();
		newChatInterface.Parent = localPlayer.PlayerGui;
	end
	localPlayer.CharacterAdded:Connect(onCharacterAdded);

	remoteInteractionUpdate.OnClientEvent:Connect(function(src, object, action)
		if workspace:IsAncestorOf(src) then return end;
		
		Debugger:Warn("Server ",action, src, object);
		if action == "interact" then
			modData.InteractRequest(src, object);
		end
	end)
	
	Debugger:Log("Requesting for save data sync...");
	repeat
		remotePlayerDataSync:Fire(playerDataSyncRequest);
		task.wait(1);
	until sendDataRequest == false;
	
	remoteGoldStatSync.OnClientEvent:Connect(function(playerGold)
		if modData.Profile and modData.Profile.Trader and modData.Profile.Trader.Gold then
			modData.Profile.Trader.Gold = playerGold;
			modData.PlayerGold = playerGold;
		end
		if modData.OnGoldUpdate then
			modData.OnGoldUpdate:Fire(playerGold);
		end
	end)
	
	
	remoteMasterySync.OnClientEvent:Connect(function(name, value)
		if name == nil then return end;
		if modData.Players[name] == nil then
			modData.Players[name] = {
				Stats={
					Level=0;
				};
			};
		end;
		if modData.Players[name] and modData.Players[name].Stats then
			modData.Players[name].Stats.Level = value; 
		end
		wait(0.1);
		local modInterface = GetInterfaceModule();
		if modInterface then
			modInterface:CallBind("UpdateSocialMenu");
		end
	end)
	
	remoteStorageSync.OnClientEvent:Connect(function(action, ...)
		local storage;
		
		if action == "sync" then
			storage = ...;
			
			if RunService:IsStudio() then
				Debugger:Warn("[Studio] StorageSync Key", storage.Id, "Size", modRemotesManager.PacketSizeCounter.GetPacketSize{PacketData={storage};});
			end
			modStorageInterface:ClearPrompts();
			
		elseif action == "syncvalues" then
			local storageId, storageValues = ...;
			
			storage = modData.Storages[storageId];
			if storage == nil then return end;
			 
			for k, v in pairs(storageValues) do
				storage.Values[k] = v;
			end
			for k, v in pairs(storage.Values) do
				if storageValues[k] then continue end;
				storage.Values[k] = nil;
			end
			
		end
		
		modData.SetStorage(storage);
		modStorageInterface.UpdateStorages({storage});
	end)
	
	remoteBodyEquipmentsSync.OnClientEvent:Connect(function()
		local modInterface = GetInterfaceModule();
		if modInterface and modInterface.modInventoryInterface and modInterface.modInventoryInterface.UpdateHotbarSize then
			modInterface.modInventoryInterface.UpdateHotbarSize();
		end
	end)
	
	remoteStorageDestroy.OnClientEvent:Connect(function(id)
		modData.DelStorage(id);
	end)
	
	local function refreshCharacterVisibility()
		if not hideAllPlayers then
			for _, c in pairs(hiddenCharacter:GetChildren()) do
				if hiddenPlayers[c.Name] == nil then
					c.Parent = otherCharacter;
				end
			end
		end
		for _, c in pairs(otherCharacter:GetChildren()) do
			if hiddenPlayers[c.Name] == true or hideAllPlayers then
				c.Parent = hiddenCharacter;
			end
		end
	end
	
	remoteInteractableSync.OnClientEvent:Connect(function(src, data)
		if src == nil then Debugger:Log("Missing interactable module.") return end;
		if src.ClassName ~= "ModuleScript" then Debugger:Warn("Invalid src. Data:", data); return end;
		if not game:IsAncestorOf(src) then Debugger:Warn("Interactable was destroyed.") return end;
		
		local interact = require(src);
		if interact.OnSync then
			interact:OnSync(data);
			
			if localPlayer.Character then
				local modCharacter = modData:GetModCharacter();
				if modCharacter == nil or modCharacter.CharacterProperties == nil then return end; 

				local activeInteractable = modCharacter.CharacterProperties.ActiveInteract;
				if activeInteractable and activeInteractable == interact then
					activeInteractable:Trigger();
				end
			end
			
			if src:GetAttribute("Debug") == true then
				Debugger:Warn(src:GetFullName(), " ManualSynced.");
			end
			
		else
			for k, v in pairs(data) do
				interact[k] = v;
			end
			if src:GetAttribute("Debug") == true then
				Debugger:Warn(src:GetFullName(), " AutoSynced.");
			end
			
		end
	end)
	
	remoteStorageItemSync.OnClientEvent:Connect(function(packet)
		local storageId = packet.StorageId;
		local storageItemId = packet.ID;
		
		local itemId = packet.ItemId;
		--local itemLib = modItemLibrary:Find(itemId);

		if RunService:IsStudio() then
			local size = modRemotesManager.PacketSizeCounter.GetPacketSize{PacketData={packet};};
			if size > 500 then
				Debugger:Warn("[Studio] Key", storageId,storageItemId, "Size >500",size);
			end
		end
		
		local action = packet.Action;
		if action == "fullsync" then
			local itemData = packet.Data;
			
			if storageId == "MockStorageItem" then
				--modData.Profile.MockStorageItem = itemData;
				for k, v in pairs(itemData) do
					modData.MockStorageItem[k] = v;
				end
				
				--Debugger:Warn("fullsync MockStorageItem", itemData.ItemId);
				return;
			end
			
			if modData.Storages[storageId] == nil then
				local rPacket = remoteStorageService:InvokeServer({
					Action="RequestStorage";
					StorageIds={storageId};
					Request=true;
				});

				if rPacket.Storages then
					for storageId, _ in pairs(rPacket.Storages) do
						modData.SetStorage(rPacket.Storages[storageId]);
					end
				end
			end

			if modData.Storages[storageId] then
				if itemData and itemData.Quantity > 0 then
					-- Updated item.
					local existingItem = modData.Storages[storageId].Container[storageItemId];
					if existingItem then
						for k, v in pairs(itemData) do
							existingItem[k] = itemData[k];
						end
						for k, v in pairs(existingItem) do
							if itemData[k] == nil then
								existingItem[k] = nil;
							end
						end
					else
						modData.Storages[storageId].Container[storageItemId] = itemData;
					end
					
				else
					-- Deleted item.
					--Debugger:Warn("Item deleted, no follow up action needed");
					modData.Storages[storageId].Container[storageItemId] = nil;
					
				end

				modStorageInterface.UpdateStorages({modData.Storages[storageId]});
			end
			
		elseif action == "synckeys" then
			local properties = packet.Properties;
			local values = packet.Values;

			local localStorageItem, localStorage;
			
			if storageId ~= "MockStorageItem" then
				localStorage = modData.Storages[storageId];
				if localStorage == nil or localStorage.Container[storageItemId] == nil then return end;

				localStorageItem = localStorage.Container[storageItemId];
				
			else
				localStorageItem = modData.MockStorageItem;
				
			end
			
			
			for k, v in pairs(properties) do
				localStorageItem[k] = v;
			end

			for k, v in pairs(values) do
				localStorageItem.Values[k] = v;

				if k == "MA" or (k == "A" and v == nil) then
					modData.OnAmmoUpdate:Fire(storageItemId);
					
				end

				if (k == "E" or k == "EG") and not modConfigurations.DisableExperiencebar then
					local itemValues = localStorageItem.Values;

					local modCharacter = modData:GetModCharacter();
					if modCharacter.EquippedItem and modCharacter.EquippedItem.ID == storageItemId then
						modData.UpdateProgressionBar((itemValues.E or 0)/math.max(itemValues.EG or 0, 100), "WeaponLevel", itemValues.L);
					end
				end
			end
			if storageId ~= "MockStorageItem" then
				modStorageInterface.UpdateStorages({localStorage}, storageItemId);
			end
			
			--Debugger:Warn("localStorageItem", localStorageItem);
		end
		
		if modItemLibrary:HasTag(itemId, "Ammo") then
			modData.OnAmmoUpdate:Fire(storageItemId);
		end
		
		modItemInterface.ProcessSyncHooks(storageItemId);
	end)
	
	--remoteItemValuesSync.OnClientEvent:Connect(function(storageId, id, key, value)
	--	if modData.Storages[storageId] == nil or modData.Storages[storageId].Container[id] == nil then return end
	--	local storageItem = modData.Storages[storageId].Container[id];
		
	--	storageItem.Values[key] = value;
	--	modStorageInterface.UpdateStorages({modData.Storages[storageId]}, id);
		
	--	if key == "MA" or (key == "A" and value == nil) then
	--	end
		
	--	if (key == "E" or key == "EG") and not modConfigurations.DisableExperiencebar then
	--		local itemValues = storageItem.Values;
			
	--		modData.UpdateProgressionBar((itemValues.E or 0)/math.max(itemValues.EG or 0, 100), "WeaponLevel", itemValues.L);
	--	end
	--end)
	
	--remoteItemSync.OnClientEvent:Connect(function(storageId, id, itemData)
	--	if modData.Storages[storageId] == nil then
	--		local rPacket = remoteStorageService:InvokeServer({
	--			Action="RequestStorage";
	--			StorageIds={storageId};
	--			Request=true;
	--		});
			
	--		if rPacket.Storages then
	--			for storageId, _ in pairs(rPacket.Storages) do
	--				modData.SetStorage(rPacket.Storages[storageId]);
	--			end
	--		end
	--	end
		
	--	if modData.Storages[storageId] then
	--		if itemData then
	--			-- Updated item.
	--			local existingItem = modData.Storages[storageId].Container[id];
	--			if existingItem then
	--				for k, v in pairs(itemData) do
	--					existingItem[k] = itemData[k];
	--				end
	--				for k, v in pairs(existingItem) do
	--					if itemData[k] == nil then
	--						existingItem[k] = nil;
	--					end
	--				end
	--			else
	--				modData.Storages[storageId].Container[id] = itemData;
	--			end
	--		else
	--			-- Deleted item.
	--			--Debugger:Warn("Item deleted, no follow up action");
	--			--if modData.Storages[storageId].Container[id] 
	--			--	and modData.Storages[storageId].Container[id].Values 
	--			--	and modData.Storages[storageId].Container[id].Values.IsEquipped then
	--			--	--modData.Binds.CharacterUnequip:Fire(id);
	--			--	modData.HandleTool("local", {Unequip={Id=id;}});
	--			--end
	--			--modData.Storages[storageId].Container[id] = nil;
	--		end
			
	--		modStorageInterface.UpdateStorages({modData.Storages[storageId]});
	--	end
	--end)
	
	remoteDuelRequest.OnClientEvent:Connect(function(requestType, ...)
		local modInterface = GetInterfaceModule();
		if requestType == "request" then
			local playerName = ...;
			modData.DuelRequests[playerName] = tick();
			
			if modInterface then
				modInterface:CallBind("UpdateSocialMenu");
			end
		end
	end)
	
	remoteTravelRequest.OnClientEvent:Connect(function(userData)
		local exist = false;
		for a=1, #modData.TravelRequests do
			if modData.TravelRequests[a].UserName == userData.UserName then
				modData.TravelRequests[a] = userData;
				exist = true;
				break;
			end
		end
		if not exist then
			table.insert(modData.TravelRequests, userData);
		end
		local modInterface = GetInterfaceModule();
		modInterface:CallBind("UpdateSocialMenu");
	end)
	
	remoteGameModeAssign.OnClientEvent:Connect(function(lobbyData)
		local modInterface = GetInterfaceModule();
		modInterface:ToggleGameBlinds(false, 0.5);
		wait(0.51);
		bindOpenLobbyInterface:Fire(lobbyData);
	end)
	
	function remoteMissionRemote.OnClientInvoke(actionId, missionId, logicScript)
		if actionId == "init" then
			modData:WaitForMissions();

			local missionsList = modData.GameSave and modData.GameSave.Missions;
			local mission = modData:GetMission(missionId);
			
			local modMissionFuncs = require(logicScript);
			if modMissionFuncs and modMissionFuncs.Init then
				modMissionFuncs.Init(missionsList, mission);
			end
			
			Debugger:Warn("Init mission logic", missionId, logicScript);
		end
	end
	
	remoteTradeRequest.OnClientEvent:Connect(function(requestType, ...)
		local modInterface = GetInterfaceModule();
		if requestType == "request" then
			local playerName = ...;
			modData.TradeRequests[playerName] = tick();
			if modInterface then
				modInterface:CallBind("UpdateSocialMenu");
			end
			
		elseif requestType == "tradesession" then
			local tradeSessionData = ...;
			local modInterface = GetInterfaceModule();
			if modInterface then
				modInterface.modTradeInterface.TradeSession = tradeSessionData;
				modInterface.modTradeInterface.Update();
			end
			
		elseif requestType == "syncgold" then
			local tradeSessionData = ...;
			local modInterface = GetInterfaceModule();
			if modInterface then
				local gold = tradeSessionData.Players[game.Players.LocalPlayer.Name].Gold;
				modInterface.modTradeInterface.SyncLocalGold(gold);
			end
			
		elseif requestType == "init" then
			local tradeSessionData = ...;
			local modInterface = GetInterfaceModule();
			if modInterface and modInterface.modTradeInterface then
				modInterface.modTradeInterface.TradeSession = tradeSessionData;
				modInterface:OpenWindow("Trade");
			end
			
		elseif requestType == "end" then
			local tradeSessionData = ...;
			local modInterface = GetInterfaceModule();
			if modInterface then
				modInterface.modTradeInterface.TradeSession = tradeSessionData;
			end
			
		end
	end)
	
	UserInputService.InputBegan:Connect(function(inputObject, gameProcessed)
		if inputObject.KeyCode == Enum.KeyCode.F2 then
	
		end
	end)
		
	local function ParentCharacter(char)
		if char == nil then return end;
		RunService.Heartbeat:Wait();
		if hideAllPlayers or hiddenPlayers[char.Name] then
			char.Parent = hiddenCharacter;
		else
			char.Parent = otherCharacter;
		end
		
		game.Debris:AddItem(char:FindFirstChild("LeftHandOld"), 0);
		game.Debris:AddItem(char:FindFirstChild("RightHandOld"), 0);
	end
	
	modConfigurations.OnChanged("ShowNameDisplays", function(oldValue, value)
		local list = CollectionService:GetTagged("PlayerNameDisplays");
		for a=1, #list do
			list[a].Enabled = value;
		end
	end)
	
	local players = game.Players:GetPlayers();
	for a=1, #players do
		if players[a] == localPlayer then continue end;
		
		players[a].CharacterAdded:Connect(ParentCharacter);
		ParentCharacter(players[a].Character);
	end
	
	game.Players.PlayerAdded:Connect(function(player)
		if player == localPlayer then return end;
		player.CharacterAdded:Connect(ParentCharacter);
	end)
	
	spawn(function() while wait(10) do refreshCharacterVisibility(); end end)
	
	function shared.DisableHudRefresh()
		local disableHud = localPlayer:GetAttribute("DisableHud") == true;
		
		for _, obj in pairs(workspace.Interactables:GetDescendants()) do
			if obj.Name == "InteractableType" and obj:IsA("BillboardGui") then
				obj.MaxDistance = disableHud and 0.001 or 64;
			end
		end
		
		local list = CollectionService:GetTagged("PlayerNameDisplays");
		
		for _, billBoardObject in pairs(list) do
			billBoardObject.MaxDistance = disableHud and 0.0001 or 45;
		end
		
		local function refreshHealthbar(model)
			local humanoid = model:FindFirstChildWhichIsA("Humanoid");
			if humanoid then
				humanoid.DisplayDistanceType = disableHud and Enum.HumanoidDisplayDistanceType.None or Enum.HumanoidDisplayDistanceType.Subject;
			end
		end
		
		for _, character in pairs(workspace.Characters:GetChildren()) do
			refreshHealthbar(character);
		end
		
		for _, character in pairs(workspace.Entity:GetChildren()) do
			refreshHealthbar(character);
		end
	end
	
	CollectionService:GetInstanceAddedSignal("PlayerNameDisplays"):Connect(shared.DisableHudRefresh);
	CollectionService:GetInstanceRemovedSignal("PlayerNameDisplays"):Connect(shared.DisableHudRefresh);
	
	CollectionService:GetInstanceAddedSignal("WeakPoints"):Connect(function(obj)
		if localPlayer:GetAttribute("CinematicMode") == true then
			obj.Enabled=false;
		end
	end);
	
	localPlayer:GetAttributeChangedSignal("DisableHud"):Connect(shared.DisableHudRefresh);
	workspace:WaitForChild("Characters").ChildAdded:Connect(shared.DisableHudRefresh);
	workspace:WaitForChild("Entity").ChildAdded:Connect(function(model)
		local disableHud = localPlayer:GetAttribute("DisableHud") == true;
		
		local humanoid = model:FindFirstChildWhichIsA("Humanoid");
		if humanoid then
			humanoid.DisplayDistanceType = disableHud and Enum.HumanoidDisplayDistanceType.None or Enum.HumanoidDisplayDistanceType.Subject;
		end
	end);
	
	workspace:WaitForChild("Debris").ChildAdded:Connect(function(child)
		if child:IsA("BasePart") then
			child.CollisionGroup = "Debris";
		end 
	end)
	
	modSettings.OnChanged:Connect(function(key)
		Debugger:Warn("OnSettingsChanged",key, modData.Settings[key]);

		if key == "CompactInterface" then
			shared.ReloadGui();
			
		elseif key == "HideHotkey" then
			pcall(function()
				local mainInterface = GetInterfaceModule();
				for k, v in pairs(mainInterface.Windows) do
					local quickButton = mainInterface.Windows[k].QuickButton
					if quickButton then
						quickButton.hotKey.Visible = not modConfigurations.DisableHotKeyLabels and UserInputService.KeyboardEnabled or false;
						if modData:GetSetting("HideHotkey") == 1 then
							quickButton.hotKey.Visible = false;
						end
					end
					if mainInterface.Windows[k].CloseButtonLabel then
						local hotKeyButton = mainInterface.Windows[k].CloseButtonLabel.Parent;
						if modData:GetSetting("HideHotkey") == 1 then
							hotKeyButton.Visible = false;
						else
							hotKeyButton.Visible = true;
						end
					end
				end
			end)
			
		elseif key == "AutoPickupMode" or key == "AutoPickupConfig" then
			task.wait(0.1);
			modData.UpdatePickupCache();
			
		end
	end)
	
end