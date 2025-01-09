--==
local RunService = game:GetService("RunService");

local UsablePreset = require(game.ReplicatedStorage.Library.UsableItems.UsablePreset).new();

--== MARK: Server
if RunService:IsClient() then return UsablePreset; end;

function UsablePreset:ServerUse(player, inputStorageItem)
    local profile = shared.modProfile:Get(player);
	local activeSave = profile:GetActiveSave();
	local storageItem, storage = activeSave:FindItemFromStorages(inputStorageItem.ID);

	if storageItem == nil or storage == nil then return end;

	activeSave:AddStat("TweakPoints", 10);
	shared.Notify(player, "You have recieved 10 tweak points.", "Reward");
    
	storage:Remove(storageItem.ID, 1);
end

return UsablePreset;