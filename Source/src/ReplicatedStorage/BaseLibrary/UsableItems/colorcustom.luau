--==
local RunService = game:GetService("RunService");

local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);

local UsablePreset = require(game.ReplicatedStorage.Library.UsableItems.UsablePreset).new();

--== MARK: Server
if RunService:IsClient() then return UsablePreset; end;

function UsablePreset:ServerUse(player, inputStorageItem)
    local remoteHudNotification = modRemotesManager:Get("HudNotification");

    local profile = shared.modProfile:Get(player);
	local flags = profile.Flags;
	local activeSave = profile:GetActiveSave();
	local storageItem, storage = activeSave:FindItemFromStorages(inputStorageItem.ID);

	if storageItem == nil or storage == nil then return end;

	local customColorsData = flags:Get("CustomColors", {
		Id="CustomColors";
		Unlocked={};
	});
	local colorHex = storageItem.Values.Color;

	if customColorsData.Unlocked[colorHex] ~= nil then
		shared.Notify(player,`You have already unlocked this color.`, "Negative");
		return;
	end

	customColorsData.Unlocked[colorHex] = true;
	flags:Sync();

	shared.Notify(player, "Unlocked a new color!", "Reward");
	storage:Remove(storageItem.ID, 1);

    remoteHudNotification:FireClient(player, "Unlocked", {Name=`a new color!`});
end

return UsablePreset;