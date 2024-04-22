local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modProfile = require(game.ServerScriptService.ServerLibrary.Profile);
local modColorsLibrary = require(game.ReplicatedStorage.Library:WaitForChild("ColorsLibrary"));
local modSkinsLibrary = require(game.ReplicatedStorage.Library:WaitForChild("SkinsLibrary"));
local modAnalytics = require(game.ServerScriptService.ServerLibrary.GameAnalytics);
local modItemUnlockablesLibrary = require(game.ReplicatedStorage.Library.ItemUnlockablesLibrary);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);

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

function ItemHandler:ConsumeTomeOfTweaks(player, storageItem)
	local profile = modProfile:Get(player);
	local activeSave = profile:GetActiveSave();
	local storageItem, storage = activeSave:FindItemFromStorages(storageItem.ID);

	if storageItem == nil or storage == nil then return end;
	activeSave:AddStat("TweakPoints", 10);
	shared.Notify(player, "You have recieved 10 tweak points.", "Reward");
	modAnalytics.RecordResource(player.UserId, 10, "Source", "TweakPoints", "Gameplay", "TomeOfTweaks");
	
	storage:Remove(storageItem.ID, 1);
end

function ItemHandler:UnlockPack(player, storageItem)
	local profile = modProfile:Get(player);
	local activeSave = profile:GetActiveSave();
	local storageItem, storage = activeSave:FindItemFromStorages(storageItem.ID);
	
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

function ItemHandler:ItemUnlockable(player, storageItem)
	local profile = modProfile:Get(player);
	local activeSave = profile:GetActiveSave();
	local storageItem, storage = activeSave:FindItemFromStorages(storageItem.ID);

	if storageItem == nil or storage == nil then return end;
	
	local unlockKey = storageItem.ItemId;
	local modItemUnlockLib = modItemUnlockablesLibrary:Find(unlockKey);
	
	if modItemUnlockLib then
		local itemLib = modItemsLibrary:Find(unlockKey);
		local itemId = modItemUnlockLib.ItemId;
		
		if profile.ItemUnlockables[itemId] and profile.ItemUnlockables[itemId][unlockKey] ~= nil then
			shared.Notify(player, "You have already unlocked: "..itemLib.Name, "Negative");
			return;
		end
		
		profile.ItemUnlockables:Set(itemId, unlockKey, true);
		profile.ItemUnlockables:Alert(itemId, unlockKey);
		storage:Remove(storageItem.ID, 1);

		profile:Sync("ItemUnlockables/"..itemId);
	end

end

function ItemHandler:UnlockPapers(player, storageItem)
	local profile = modProfile:Get(player);
	local activeSave = profile:GetActiveSave();
	local storageItem, storage = activeSave:FindItemFromStorages(storageItem.ID);

	if storageItem == nil or storage == nil then return end;
	local itemLib = storageItem.Properties;
	
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

function ItemHandler:UnlockCustomColor(player, storageItem)
	local profile = modProfile:Get(player);
	local flags = profile.Flags;
	local activeSave = profile:GetActiveSave();
	storageItem, storage = activeSave:FindItemFromStorages(storageItem.ID);

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
