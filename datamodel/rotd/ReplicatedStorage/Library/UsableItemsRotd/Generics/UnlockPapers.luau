local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modSafehomesLibrary = shared.require(game.ReplicatedStorage.Library.SafehomesLibrary);

local UsablePreset = shared.require(game.ReplicatedStorage.Library.UsableItems.UsablePreset).new();

--== MARK: Server
if RunService:IsClient() then return UsablePreset; end;

function UsablePreset:ServerUse(player, inputStorageItem)
    local remoteHudNotification = modRemotesManager:Get("HudNotification");

    local profile = shared.modProfile:Get(player);
	local activeSave = profile:GetActiveSave();
	local storageItem, storage = activeSave:FindItemFromStorages(inputStorageItem.ID);

	if storageItem == nil or storage == nil then return end;
	local itemLib = storageItem.Library;
	
	local safehomeData = profile.Safehome;
	if safehomeData == nil then return end;
	
	local safehomeId = itemLib.UnlockData.Id;

	local safehomeLib = modSafehomesLibrary:Find(safehomeId);
	
	if safehomeLib == nil then return end;

    if safehomeLib.UnlockPapers ~= true then
		shared.Notify(player, safehomeLib.Name .. " Safehome unavailable to unlock!", "Negative");
        return;
    end
	
	if safehomeData.Homes[safehomeId] ~= nil then
		shared.Notify(player, safehomeLib.Name .. " Safehome already unlocked!", "Negative");
		return;
	end
	
	safehomeData.Homes[safehomeId] = {};
	storage:Remove(storageItem.ID, 1);

	profile:Sync("Safehome/Homes/"..safehomeId);

    remoteHudNotification:FireClient(player, "Unlocked", {Name=`{safehomeLib.Name} Safehome`});
	shared.Notify(player, "Unlocked ".. safehomeLib.Name .. " Safehome!", "Reward");
end

return UsablePreset;