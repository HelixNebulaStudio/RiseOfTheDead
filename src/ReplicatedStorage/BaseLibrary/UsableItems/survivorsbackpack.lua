local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local UsablePreset = require(game.ReplicatedStorage.Library.UsableItems.UsablePreset).new();

local modAudio = require(game.ReplicatedStorage.Library.Audio);

local remotes = game.ReplicatedStorage.Remotes;
local remoteOpenStorageRequest = remotes.Interactable.OpenStorageRequest;

UsablePreset.PortableStorage = {StorageId="dufflebag"; Persistent=true; Size=5; Expandable=true; MaxSize=15;};

function UsablePreset:Use(storageItem)
	local player = game.Players.LocalPlayer;
	local modData = require(player:WaitForChild("DataModule") :: ModuleScript);
	
	local storage = remoteOpenStorageRequest:InvokeServer(storageItem);
	if storage and type(storage) == "table" then
		modAudio.Preload("ZipOpen", 5);
		modAudio.Play("ZipOpen");
		
		storage.Name = "Survivor's Backpack";
		
		modData.SetStorage(storage);
		
		local modInterface = modData:GetInterfaceModule();
		modInterface:OpenWindow("ExternalStorage", storage.Id, storage);
	else
		Debugger:Warn("Storage does not exist.");
	end
end


return UsablePreset;