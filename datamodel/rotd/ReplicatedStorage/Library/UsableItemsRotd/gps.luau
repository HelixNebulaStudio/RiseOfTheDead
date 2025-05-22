local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local UsablePreset = shared.require(game.ReplicatedStorage.Library.UsableItems.UsablePreset).new();

function UsablePreset:ClientUse(storageItem)
	local localPlayer = game.Players.LocalPlayer;

	local modData = shared.require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	local modInterface = modData:GetInterfaceModule();
	
	local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);

	if not modInterface:IsVisible("GpsWindow") then
		local toolHandler = playerClass.WieldComp:GetToolHandler(storageItem.ID, storageItem.ItemId, storageItem);
		modInterface:OpenWindow("GpsWindow", toolHandler);
	end
end

return UsablePreset;