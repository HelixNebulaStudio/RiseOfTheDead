local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local UsablePreset = require(game.ReplicatedStorage.Library.UsableItems.UsablePreset).new();

function UsablePreset:Use(storageItem)
	local player = game.Players.LocalPlayer;
	local modData = require(player:WaitForChild("DataModule") :: ModuleScript);
	
	local modInterface = modData:GetInterfaceModule();
	
	if not modInterface:IsVisible("SupplyStation") then
		modInterface:OpenWindow("SupplyStation", storageItem);
	end
end

return UsablePreset;