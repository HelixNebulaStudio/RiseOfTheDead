local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local UsablePreset = shared.require(game.ReplicatedStorage.Library.UsableItems.UsablePreset).new();

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

function UsablePreset:ClientUse(storageItem)
	local player = game.Players.LocalPlayer;
	local modData = shared.require(player:WaitForChild("DataModule") :: ModuleScript);
	
	local storage = modData.RequestStorage{Action="GetStorage"; StorageId="dufflebag"};
	if storage and type(storage) == "table" then
		modAudio.Preload("ZipOpen", 5);
		modAudio.Play("ZipOpen");
		
		storage.Name = "Survivor's Backpack";
		
		modData.SetStorage(storage);
		
		modClientGuis.toggleWindow("ExternalStorage", true, storage.Id);
	else
		Debugger:Warn("Storage does not exist.");
	end
end


return UsablePreset;