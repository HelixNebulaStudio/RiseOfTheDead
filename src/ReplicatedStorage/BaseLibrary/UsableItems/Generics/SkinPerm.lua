local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modColorsLibrary = require(game.ReplicatedStorage.Library.ColorsLibrary);
local modSkinsLibrary = require(game.ReplicatedStorage.Library.SkinsLibrary);
local modItemUnlockablesLibrary = require(game.ReplicatedStorage.Library.ItemUnlockablesLibrary);
local modItemSkinsLibrary = require(game.ReplicatedStorage.Library.ItemSkinsLibrary);

local UsablePreset = require(game.ReplicatedStorage.Library.UsableItems.UsablePreset).new();

if RunService:IsClient() then
	function UsablePreset:Use(storageItem)
		local player = game.Players.LocalPlayer;
		local modData = require(player:WaitForChild("DataModule") :: ModuleScript);

		local modInterface = modData:GetInterfaceModule();
		modInterface:OpenWindow("SkinPerm", storageItem);
	end
	
else

	function UsablePreset:HasSkinPermanent(storageItem, skinId)
		local unlockedSkins = storageItem:GetValues("Skins") or {};

		return table.find(unlockedSkins, skinId) ~= nil;
	end

	function UsablePreset:AddSkinPermanent(storageItem, skinId)
		local unlockedSkins = storageItem:GetValues("Skins") or {};

		if table.find(unlockedSkins, skinId) == nil then
			table.insert(unlockedSkins, skinId);
		end

		for a=1, #unlockedSkins do
			unlockedSkins[a] = tostring(unlockedSkins[a])
		end

		storageItem:SetValues("ActiveSkin", skinId);
		storageItem:SetValues("Skins", unlockedSkins);
		storageItem:Sync({"ActiveSkin"; "Skins"});
	end

	function UsablePreset:Use(player, storageItem, packet)
		local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
		
		local profile = shared.modProfile:Get(player);
		
		local skinPermStorageItem, storage = modStorage.FindIdFromStorages(storageItem.ID, player);
		local targetStorageItem, _ = modStorage.FindIdFromStorages(packet.TargetStorageItem.ID, player);
		
		local returnPacket = {};
		
		if targetStorageItem == nil then
			returnPacket.Success = false;
			returnPacket.FailMsg = "Missing Target Item";
			return returnPacket;
			
		end

		local skinPermItemLib = modItemsLibrary:Find(skinPermStorageItem.ItemId);
		if skinPermItemLib.PatPerm ~= true and skinPermItemLib.TargetItemId ~= targetStorageItem.ItemId then
			returnPacket.Success = false;
			returnPacket.FailMsg = "Incompatible item";
			return returnPacket;
		end
		
		local permType = nil;
		local permLib = modItemUnlockablesLibrary:Find(skinPermItemLib.Id);

		if permLib then
			permType = "Clothing";

		elseif modItemSkinsLibrary:GetItemSkinId(targetStorageItem.ItemId, skinPermItemLib.Id) then
			permLib = modItemSkinsLibrary:GetItemSkinId(targetStorageItem.ItemId, skinPermItemLib.Id);
			permType = "Tool";

		else
			permLib = modSkinsLibrary.GetByName(skinPermItemLib.SkinPerm)
			if permLib then
				permType = "Tool";
			end
		end
		
		if permType == nil then
			returnPacket.Success = false;
			returnPacket.FailMsg = "Skin unavailable";
			return returnPacket;
		end

		if self:HasSkinPermanent(targetStorageItem, permLib.Id) then
			returnPacket.Success = false;
			returnPacket.FailMsg = "Skin is already unlocked on item.";
			return returnPacket;
		end
		self:AddSkinPermanent(targetStorageItem, permLib.Id);

		
		task.spawn(function()
			if permType == "Clothing" then
				local profile = shared.modProfile:Get(player);
				local activeSave = profile:GetActiveSave();
				activeSave.AppearanceData:Update(activeSave.Clothing);

			elseif permType == "Tool" then
				if profile.EquippedTools.WeaponModels == nil then return end;
				
			end
		end)

		returnPacket.Success = true;
		storage:Remove(skinPermStorageItem.ID, 1);
		shared.Notify(player, `{skinPermItemLib.Name} has been applied to your {skinPermItemLib.TargetItemId}.`, "Reward");
		
		return returnPacket;
	end
	
end

return UsablePreset;