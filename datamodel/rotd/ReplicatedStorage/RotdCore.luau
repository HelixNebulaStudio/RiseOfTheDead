local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local RotdCore = {};
--==
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManagerRotd);
local modOnEventsHandlers = shared.require(game.ReplicatedStorage.Library.OnEventHandlersRotd);
local modPlayers = shared.require(game.ReplicatedStorage.Library.PlayersRotd);
local modItemsLibrary = shared.require(game.ReplicatedStorage.Library.ItemsLibraryRotd);
local modStoragePresetsLibrary = shared.require(game.ReplicatedStorage.Library.StoragePresetsLibraryRotd);
local modBlueprintLibrary = shared.require(game.ReplicatedStorage.Library.BlueprintLibraryRotd);
local modRewardsLibrary = shared.require(game.ReplicatedStorage.Library.RewardsLibraryRotd);
local modEquipmentClass = shared.require(game.ReplicatedStorage.Library.EquipmentClassRotd);
local modClothingLibrary = shared.require(game.ReplicatedStorage.Library.ClothingLibraryRotd);
local modWeaponsLibrary = shared.require(game.ReplicatedStorage.Library.WeaponsLibraryRotd);
local modToolsLibrary = shared.require(game.ReplicatedStorage.Library.ToolsLibraryRotd);
local modInteractables = shared.require(game.ReplicatedStorage.Library.InteractablesRotd);
local modUsableItems = shared.require(game.ReplicatedStorage.Library.UsableItemsRotd);
local modItemModsLibrary = shared.require(game.ReplicatedStorage.Library.ItemModsLibraryRotd);
local modBattlePassLibrary = shared.require(game.ReplicatedStorage.Library.BattlePassLibraryRotd);
local modItemSkinsLibrary = shared.require(game.ReplicatedStorage.Library.ItemSkinsLibraryRotd);
local modItemModifierClass = shared.require(game.ReplicatedStorage.Library.ItemModifierClassRotd);
local modItemUnlockablesLibrary = shared.require(game.ReplicatedStorage.Library.ItemUnlockablesLibraryRotd);
local modStatusLibrary = shared.require(game.ReplicatedStorage.Library.StatusLibraryRotd);
local modCrateLibrary = shared.require(game.ReplicatedStorage.Library.CrateLibraryRotd);
local modAchievementLibrary = shared.require(game.ReplicatedStorage.Library.AchievementLibraryRotd);
local modSettings = shared.require(game.ReplicatedStorage.Library.SettingsRotd);
local modSafehomesLibrary = shared.require(game.ReplicatedStorage.Library.SafehomesLibrary);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffectsRotd);
local modWorldCoreClass = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd);

if RunService:IsServer() then
    local modProfile = shared.require(game.ServerScriptService.ServerLibrary.ProfileRotd);
    local modGameSave = shared.require(game.ServerScriptService.ServerLibrary.GameSaveRotd);
    local modApiRequestLibrary = shared.require(game.ServerScriptService.ServerLibrary.ApiRequestLibraryRotd);
    local modShopSystem = shared.require(game.ServerScriptService.ServerLibrary.ShopSystem);
    local modGameModeManager = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager);
    
end

function RotdCore.OnPlayerAdded(player)
    if RunService:IsServer() then
    elseif RunService:IsClient() then
    end
end

function RotdCore.OnCharacterAdded(player, character)
    if RunService:IsServer() then
    elseif RunService:IsClient() then
    end
end

function RotdCore.OnPlayerRemoving(player)
    if RunService:IsServer() then
    elseif RunService:IsClient() then
    end
end

function RotdCore.onRequire()
    Debugger:Warn("RotdCore onRequire.");
end

Debugger:Warn("Init RotdCore.");
return RotdCore;