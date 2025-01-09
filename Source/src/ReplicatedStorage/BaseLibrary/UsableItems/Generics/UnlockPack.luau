local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modItemSkinsLibrary = require(game.ReplicatedStorage.Library.ItemSkinsLibrary);

local UsablePreset = require(game.ReplicatedStorage.Library.UsableItems.UsablePreset).new();

--== MARK: Server
if RunService:IsClient() then return UsablePreset; end;

function UsablePreset.UnlockPack(player, packType, packId)
    local remoteHudNotification = modRemotesManager:Get("HudNotification");
	local profile = shared.modProfile:Get(player);

    local function unlock(category, key)
        local unlockedName = "";
        if category == "ColorPacks" then
            profile.ColorPacks[key] = true;
            unlockedName = "Color Pack: "..packId;
            
        elseif category == "SkinsPacks" then
            profile.SkinsPacks[key] = true;
            unlockedName = "Skin Pack: "..packId;
    
        end
        remoteHudNotification:FireClient(player, "Unlocked", {Name=unlockedName;});
        
        profile:Sync(category.."/"..key);

        return true;
    end

	if packType == "Color" and profile.ColorPacks[packId] == nil then
        unlock("ColorPacks", packId);
        return true;

	elseif packType == "Skin" and profile.SkinsPacks[packId] == nil then
        unlock("SkinsPacks", packId);
        return true;

	end

    shared.Notify(player, "You have already unlocked: "..packId, "Negative");
    return false;
end

function UsablePreset:ServerUse(player, inputStorageItem)
    local storageItem, storage = shared.modStorage.FindIdFromStorages(inputStorageItem.ID, player);
	if storageItem == nil or storage == nil then return end;
	
	local packType = self.PackType;
	local packId = self.PackId;
	
    local success = UsablePreset.UnlockPack(player, packType, packId);
    if success then
        storage:Remove(storageItem.ID, 1);
    end
end

return UsablePreset;