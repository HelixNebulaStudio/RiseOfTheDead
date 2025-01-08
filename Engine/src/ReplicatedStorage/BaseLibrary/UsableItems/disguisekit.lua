local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local UsablePreset = require(game.ReplicatedStorage.Library.UsableItems.UsablePreset).new();

local modAudio = require(game.ReplicatedStorage.Library.Audio);

local remotes = game.ReplicatedStorage.Remotes;
local remoteOpenStorageRequest = remotes.Interactable.OpenStorageRequest;

function UsablePreset:Use(storageItem)
	local player = game.Players.LocalPlayer;
	local modData = require(player:WaitForChild("DataModule") :: ModuleScript);
	
	local modInterface = modData:GetInterfaceModule();
	
	if not modInterface:IsVisible("DisguiseKit") then
		modAudio.Play("StorageClothPickup");
		modInterface:OpenWindow("DisguiseKit", storageItem);

	end
end

return UsablePreset;