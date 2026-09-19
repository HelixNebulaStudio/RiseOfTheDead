local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local UsablePreset = shared.require(game.ReplicatedStorage.Library.UsableItems.UsablePreset).new();
local modClientGuis = shared.require(game.ReplicatedStorage.PlayerScripts.ClientGuis);
--==

function UsablePreset:ClientUse(storageItem)
	local localPlayer = game.Players.LocalPlayer;
	local playerClass: PlayerClass = shared.modPlayers.get(localPlayer);
	local wieldComp: WieldComp = playerClass.WieldComp;

	local activeToolHandler = wieldComp:GetToolHandler(storageItem.ID, storageItem.ItemId, storageItem);
	if activeToolHandler == nil then return end;

	modClientGuis.toggleWindow("GpsWindow", true, activeToolHandler);
end

return UsablePreset;