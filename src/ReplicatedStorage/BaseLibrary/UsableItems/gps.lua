local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local UsablePreset = require(game.ReplicatedStorage.Library.UsableItems.UsablePreset).new();

local modAudio = require(game.ReplicatedStorage.Library.Audio);

local remotes = game.ReplicatedStorage.Remotes;
local remoteOpenStorageRequest = remotes.Interactable.OpenStorageRequest;

function UsablePreset:Use(storageItem)
	local player = game.Players.LocalPlayer;
	local modData = require(player:WaitForChild("DataModule"));
	
	local modInterface = modData:GetInterfaceModule();
	
	if not modInterface:IsVisible("GpsWindow") then
		local itemId = storageItem.ItemId;
		local toolHandler = modData:GetBaseToolModule(itemId);
		toolHandler.StorageItem = storageItem;
		
		modInterface:OpenWindow("GpsWindow", toolHandler);

	end
end

return UsablePreset;