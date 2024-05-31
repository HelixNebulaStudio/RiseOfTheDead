local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==

local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modColorsLibrary = require(game.ReplicatedStorage.Library:WaitForChild("ColorsLibrary"));
local modSkinsLibrary = require(game.ReplicatedStorage.Library:WaitForChild("SkinsLibrary"));
local modItemUnlockablesLibrary = require(game.ReplicatedStorage.Library.ItemUnlockablesLibrary);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);

local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);

local ItemHandler = {};
ItemHandler.__index = ItemHandler;
--==

function ItemHandler.new(scr)
	local self = {
		Script = scr;
	};
	
	setmetatable(self, ItemHandler);
	return self;
end

function ItemHandler:Use(player, storageItem)
	Debugger:Log(player.Name,"attempt to server use",storageItem.ItemId);
end

function ItemHandler:ConsumeTomeOfTweaks(player, inputStorageItem)
	local profile = modProfile:Get(player);
	local activeSave = profile:GetActiveSave();
	local storageItem, storage = activeSave:FindItemFromStorages(inputStorageItem.ID);

	if storageItem == nil or storage == nil then return end;
	activeSave:AddStat("TweakPoints", 10);
	shared.Notify(player, "You have recieved 10 tweak points.", "Reward");
	modAnalytics.RecordResource(player.UserId, 10, "Source", "TweakPoints", "Gameplay", "TomeOfTweaks");
	
	storage:Remove(storageItem.ID, 1);
end

function ItemHandler:ConsumeMpBook(player, inputStorageItem)
	local profile = modProfile:Get(player);
	local activeSave = profile:GetActiveSave();
	local storageItem, storage = activeSave:FindItemFromStorages(inputStorageItem.ID);

	if storageItem == nil or storage == nil then return end;

	local modBattlePassLibrary = require(game.ReplicatedStorage.Library.BattlePassLibrary);
	local activeId = modBattlePassLibrary.Active;
	if activeId == nil then
		shared.Notify(player, "No active event pass available.", "Negative");
		return;
	end;

	local battlePassSave = profile.BattlePassSave;
	local passData = battlePassSave:GetPassData(activeId);
	if passData == nil then
		shared.Notify(player, "No active event pass data.", "Negative");
		return;
	end

	shared.Notify(player, "You have recieved a level to your event pass.", "Reward");
	storage:Remove(storageItem.ID, 1);

	battlePassSave:AddLevel(activeId);
end

function ItemHandler:UnlockPack(player, inputStorageItem)
	local profile = modProfile:Get(player);
	local activeSave = profile:GetActiveSave();
	local storageItem, storage = activeSave:FindItemFromStorages(inputStorageItem.ID);
	
	if storageItem == nil or storage == nil then return end;
	
	local packType = self.PackType;
	local packId = self.PackId;
	
	if packType == "Color" and modColorsLibrary.Packs[packId] then
		if profile.ColorPacks[packId] == nil then
			profile:Unlock("ColorPacks", packId, true);
			storage:Remove(storageItem.ID, 1);
			
		else
			shared.Notify(player, "You have already unlocked: "..packId, "Negative");
			
		end
	elseif packType == "Skin" and modSkinsLibrary.Packs[packId] then
		if profile.SkinsPacks[packId] == nil then
			profile:Unlock("SkinsPacks", packId, true);
			storage:Remove(storageItem.ID, 1);
			
		else
			shared.Notify(player, "You have already unlocked: "..packId, "Negative");
			
		end
	end
end

function ItemHandler:ItemUnlockable(player, inputStorageItem)
	local profile = modProfile:Get(player);
	local activeSave = profile:GetActiveSave();
	local storageItem, storage = activeSave:FindItemFromStorages(inputStorageItem.ID);

	if storageItem == nil or storage == nil then return end;
	
	local unlockKey = storageItem.ItemId;
	local modItemUnlockLib = modItemUnlockablesLibrary:Find(unlockKey);
	
	if modItemUnlockLib then
		local itemId = modItemUnlockLib.ItemId;
		
		profile.ItemUnlockables:Add(itemId, unlockKey, 1);
		profile.ItemUnlockables:Alert(itemId, unlockKey);

		storage:Remove(storageItem.ID, 1);

		profile:Sync("ItemUnlockables/"..itemId);
	end

end

function ItemHandler:UnlockPapers(player, inputStorageItem)
	local profile = modProfile:Get(player);
	local activeSave = profile:GetActiveSave();
	local storageItem, storage = activeSave:FindItemFromStorages(inputStorageItem.ID);

	if storageItem == nil or storage == nil then return end;
	local itemLib = storageItem.Library;
	
	local safehomeData = profile.Safehome;
	if safehomeData == nil then return end;
	
	local safehomeId = itemLib.UnlockData.Id;

	local modSafehomesLibrary = require(game.ReplicatedStorage.Library.SafehomesLibrary);
	local safehomeLib = modSafehomesLibrary:Find(safehomeId);
	
	if safehomeLib == nil then return end;
	
	if safehomeData.Homes[safehomeId] ~= nil then
		shared.Notify(player, safehomeLib.Name .. " Safehome already unlocked!", "Negative");
		return;
	end
	
	safehomeData.Homes[safehomeId] = {};
	shared.Notify(player, "Unlocked ".. safehomeLib.Name .. " Safehome!", "Reward");
	
	storage:Remove(storageItem.ID, 1);

	profile:Sync("Safehome/Homes/"..safehomeId);
end

function ItemHandler:UnlockCustomColor(player, inputStorageItem)
	local profile = modProfile:Get(player);
	local flags = profile.Flags;
	local activeSave = profile:GetActiveSave();
	local storageItem, storage = activeSave:FindItemFromStorages(inputStorageItem.ID);

	if storageItem == nil or storage == nil then return end;

	local customColorsData = flags:Get("CustomColors", {
		Id="CustomColors";
		Unlocked={};
	});
	local colorHex = storageItem.Values.Color;

	if customColorsData.Unlocked[colorHex] ~= nil then
		shared.Notify(player,`You have already unlocked this color.`, "Negative");
		return;
	end

	customColorsData.Unlocked[colorHex] = true;
	flags:Sync();

	shared.Notify(player, "Unlocked a new color!", "Reward");
	storage:Remove(storageItem.ID, 1);
end

return ItemHandler;
