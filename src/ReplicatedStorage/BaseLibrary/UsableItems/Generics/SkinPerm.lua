local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modItemsLibrary = require(game.ReplicatedStorage.Library.ItemsLibrary);
local modColorsLibrary = require(game.ReplicatedStorage.Library.ColorsLibrary);
local modSkinsLibrary = require(game.ReplicatedStorage.Library.SkinsLibrary);

local UsablePreset = require(game.ReplicatedStorage.Library.UsableItems.UsablePreset).new();

if RunService:IsClient() then
	function UsablePreset:Use(storageItem)
		local player = game.Players.LocalPlayer;
		local modData = require(player:WaitForChild("DataModule"));

		local modInterface = modData:GetInterfaceModule();
		modInterface:OpenWindow("SkinPerm", storageItem);
	end
	
else
	function UsablePreset:Use(player, storageItem, packet)
		local modStorage = require(game.ServerScriptService.ServerLibrary.Storage);
		
		local profile = shared.modProfile:Get(player);
		
		local skinPermStorageItem, storage = modStorage.FindIdFromStorages(storageItem.ID, player);
		
		local targetStorageItem = packet.TargetStorageItem;
		
		local returnPacket = {};
		
		if targetStorageItem == nil then
			returnPacket.Success = false;
			returnPacket.FailMsg = "Missing Target Item";
			return returnPacket;
			
		elseif targetStorageItem.Values and targetStorageItem.Values.LockedPattern ~= nil then
			returnPacket.Success = false;
			returnPacket.FailMsg = "Item already has skin permanent";
			return returnPacket;
			
		end

		local skinPermItemLib = modItemsLibrary:Find(skinPermStorageItem.ItemId);
		if skinPermItemLib.ToolItemId ~= targetStorageItem.ItemId then
			returnPacket.Success = false;
			returnPacket.FailMsg = "Incompatible item";
			return returnPacket;
		end
		
		local skinLib = modSkinsLibrary.GetByName(skinPermItemLib.SkinPerm)
		if skinLib == nil then
			returnPacket.Success = false;
			returnPacket.FailMsg = "Skin unavailable";
			return returnPacket;
		end
		
		storage:SetValues(targetStorageItem.ID, {LockedPattern=skinLib.Id});

		task.spawn(function()
			if profile.EquippedTools.WeaponModels == nil then return end;
			
			for a=1, #profile.EquippedTools.WeaponModels do
				if not profile.EquippedTools.WeaponModels[a]:IsA("Model") then continue end;
				
				modColorsLibrary.ApplyAppearance(profile.EquippedTools.WeaponModels[a], storageItem.Values);
			end
		end)
		returnPacket.Success = true;
		
		storage:Remove(skinPermStorageItem.ID, 1);
		shared.Notify(player, skinPermItemLib.Name.." has been applied to your tool.", "Reward");
		
		return returnPacket;
	end
	
end

return UsablePreset;
