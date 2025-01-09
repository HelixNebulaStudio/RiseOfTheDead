local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local UsablePreset = require(game.ReplicatedStorage.Library.UsableItems.UsablePreset).new();

function UsablePreset:ClientUse(storageItem)
	local player = game.Players.LocalPlayer;
	local modData = require(player:WaitForChild("DataModule") :: ModuleScript);
	
	local modInterface = modData:GetInterfaceModule();
	
	if not modInterface:IsVisible("GpsWindow") then
		local itemId = storageItem.ItemId;
		local toolHandler = modData:GetBaseToolModule(itemId);
		toolHandler.StorageItem = storageItem;
		
		modInterface:OpenWindow("GpsWindow", toolHandler);

	end
end

return UsablePreset;