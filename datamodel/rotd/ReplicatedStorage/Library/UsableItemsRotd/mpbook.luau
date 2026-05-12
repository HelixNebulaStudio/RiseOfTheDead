--==
local RunService = game:GetService("RunService");

local UsablePreset = shared.require(game.ReplicatedStorage.Library.UsableItems.UsablePreset).new();

--== MARK: Server
if RunService:IsClient() then return UsablePreset; end;

function UsablePreset:ServerUse(player, inputStorageItem)
	local profile = shared.modProfile:Get(player);
	local storageItem, storage = shared.modStorage.FindIdFromStorages(inputStorageItem.ID, player);

	if storageItem == nil or storage == nil then return end;

	local modBattlePassLibrary = shared.require(game.ReplicatedStorage.Library.BattlePassLibrary);
	local activeId = modBattlePassLibrary.Active;
	if activeId == nil then
		shared.Notify(player, "No active event pass available.", "Negative");
		return;
	end;

	local battlePassSave = profile.BattlePassSave;
	local passData = battlePassSave:GetPassData(activeId);
	if passData == nil then
		shared.Notify(player, "No active event pass data.", "Negative");
		return;
	end

	shared.Notify(player, "You have recieved a level to your event pass.", "Reward");
	storage:Remove(storageItem.ID, 1);

	battlePassSave:AddLevel(activeId);
end

return UsablePreset;