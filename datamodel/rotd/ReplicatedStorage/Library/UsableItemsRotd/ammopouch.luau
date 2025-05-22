local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local UsablePreset = shared.require(game.ReplicatedStorage.Library.UsableItems.UsablePreset).new();

function UsablePreset:ClientUse(storageItem)
	local player = game.Players.LocalPlayer;
	local modData = shared.require(player:WaitForChild("DataModule") :: ModuleScript);
	
	local modInterface = modData:GetInterfaceModule();
	
	if not modInterface:IsVisible("SupplyStation") then
		modInterface:OpenWindow("SupplyStation", storageItem);
	end
end

return UsablePreset;