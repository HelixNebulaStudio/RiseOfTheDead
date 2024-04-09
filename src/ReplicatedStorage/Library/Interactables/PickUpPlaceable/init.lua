local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local InteractHandler = {};
InteractHandler.__index = InteractHandler;

local CollectionService = game:GetService("CollectionService");
local PhysicsService = game:GetService("PhysicsService");
local RunService = game:GetService("RunService");

local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modTools = require(game.ReplicatedStorage.Library.Tools);
local modItem = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);
local modCommandHandler = require(game.ReplicatedStorage.Library.CommandHandler);

if RunService:IsServer() then
	modRemotesManager:NewEventRemote("PickUpPlaceable");
end
local remotePickUpPlaceable = modRemotesManager:Get("PickUpPlaceable");
--== Script;
function InteractHandler:Init(super, modInteractable)
	function modInteractable.PickUpPlaceable(moduleScript, storageItemId)
		local interact = modInteractable.new();
		local interactMeta = getmetatable(interact);
		interactMeta.Label = "Place";
		
		interact.Script = moduleScript;
		interact.IndicatorPresist = false;
		interact.Label = nil;

		interact.StorageItemId = storageItemId;

		function interact:OnInteracted(library)
			local prefab = interact.Object.Parent;
			
			local prefabCframe = prefab:GetPrimaryPartCFrame();
			
			remotePickUpPlaceable:FireServer(library.modCharacter.EquippedItem, prefabCframe);
		end

		function interact:OnTrigger()
		end

		return interact;
	end
end

if RunService:IsServer() then
	local modStorage = Debugger:Require(game.ServerScriptService.ServerLibrary.Storage);
	local modItemDrops = require(game.ServerScriptService.ServerLibrary.ItemDrops);
	
	local pickUpInteractable = script:WaitForChild("Interactable");
	local itemsPrefab = game.ReplicatedStorage.Prefabs.Items;
	
	remotePickUpPlaceable.OnServerEvent:Connect(function(player, clientStorageItem, prefabCframe)
		if clientStorageItem == nil then return end;
		local profile = shared.modProfile:Get(player);
		local playerSave = profile:GetActiveSave();
		local inventory = profile.ActiveInventory;
		
		local storageItemId, itemId = clientStorageItem.ID, clientStorageItem.ItemId;
		
		local storageItem = inventory:Find(storageItemId);
		if storageItem == nil or storageItem.ItemId ~= itemId then Debugger:Log("storageItem", storageItem); return end;
		if player.Character == nil or player.Character:FindFirstChild(itemId) == nil then Debugger:Log("player.Character", player.Character); return end;
		if storageItem.Quantity <= 0 then return end;
		
		if player:DistanceFromCharacter(prefabCframe.p) >= 15 then Debugger:Log("Placing structure too far!"); return end;
		
		local itemValues = storageItem.Values or {};
		local itemLib = modItem:Find(itemId);
		
		local prefabId = itemValues.PickUpItemId;
		
		local prefabData = itemValues.PrefabData;
		
		inventory:Remove(storageItemId, 1);
		shared.Notify(player, ("1 $Item removed from your Inventory."):gsub("$Item", itemLib.Name), "Negative");
		
		if itemsPrefab:FindFirstChild(prefabId) == nil then Debugger:Log("Missing",prefabId,"structure prefabs.") return end;

		local newPrefab = itemsPrefab[prefabId]:Clone();
		newPrefab.Name = storageItemId;
		newPrefab:SetPrimaryPartCFrame(prefabCframe);
		newPrefab.PrimaryPart.Anchored = true;
		newPrefab.Parent = workspace.Environment;
		
		if prefabData then
			for k, properties in pairs(prefabData) do
				local obj = newPrefab:FindFirstChild(k, true);
				if obj then
					pcall(function()
						for key, value in pairs(properties) do
							obj[key] = modCommandHandler.ParseString(value);
						end
					end)
				end
			end
		end
		
		local newModule = pickUpInteractable:Clone();
		newModule.Name = "Interactable";
		newModule.Parent = newPrefab;
		
		newModule:SetAttribute("PickUpItemId", prefabId);
		
		modAudio.Play("StorageItemDrop", newPrefab);
	end)
end

return InteractHandler;