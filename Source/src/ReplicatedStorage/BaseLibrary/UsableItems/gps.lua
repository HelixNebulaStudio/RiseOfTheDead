local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local UsablePreset = require(game.ReplicatedStorage.Library.UsableItems.UsablePreset).new();

function UsablePreset:ClientUse(storageItem)
	local localPlayer = game.Players.LocalPlayer;
	local modData = require(localPlayer:WaitForChild("DataModule") :: ModuleScript);
	
	local modInterface = modData:GetInterfaceModule();
	
	if not modInterface:IsVisible("GpsWindow") then
		local toolHandler = shared.modPlayerEquipment.getToolHandler(storageItem);
		modInterface:OpenWindow("GpsWindow", toolHandler);
	end
end

return UsablePreset;