local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local UsablePreset = shared.require(game.ReplicatedStorage.Library.UsableItems.UsablePreset).new();

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);

function UsablePreset:ClientUse(storageItem)
	local player = game.Players.LocalPlayer;
	local modData = shared.require(player:WaitForChild("DataModule") :: ModuleScript);
	
	local storage = modData.RequestStorage{Action="GetStorage"; StorageId="portableautoturret"};
	if storage and type(storage) == "table" then
		modAudio.Preload("TorqueWrench", 5);
		modAudio.Play("TorqueWrench");
		
		storage.Name = "AutoTurret";
		
		modData.SetStorage(storage);
		
		modClientGuis.toggleWindow("AutoTurretWindow", true, storageItem);
	else
		Debugger:Warn("Storage does not exist.");
	end
end

return UsablePreset;