local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local UsablePreset = require(game.ReplicatedStorage.Library.UsableItems.UsablePreset).new();

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modItem = Debugger:Require(game.ReplicatedStorage.Library.ItemsLibrary);

local remotes = game.ReplicatedStorage.Remotes;
local remoteOpenStorageRequest = remotes.Interactable.OpenStorageRequest;

UsablePreset.PortableStorage = {StorageId="ammopouch"; Persistent=true; Size=5; Expandable=true; MaxSize=15;};

function UsablePreset.StorageCheck(packet)
	local dragStorageItem = packet;
	local itemLib = modItem:Find(dragStorageItem.ItemId);
	
	if itemLib.Type ~= "Ammo" then
		packet.Allowed = false;
		packet.FailMsg = "Only ammo is allowed in a ammo pouch.";
		return packet;
	end
end

function UsablePreset:Use(storageItem)
	local player = game.Players.LocalPlayer;
	local modData = require(player:WaitForChild("DataModule"));
	
	local storage = remoteOpenStorageRequest:InvokeServer(storageItem);
	if storage and type(storage) == "table" then
		modAudio.Play("ZipOpen");
		modData.SetStorage(storage);
		
		local modInterface = modData:GetInterfaceModule();
		modInterface:OpenWindow("ExternalStorage", storage.Id, storage);
	else
		Debugger:Warn("Storage does not exist.");
	end
end

return UsablePreset;
