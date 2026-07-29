local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local RotdCore = {};
--==
local modGlobalVars = shared.require(game.ReplicatedStorage.GlobalVariables);
modGlobalVars.DevVersion="3.0.x";
modGlobalVars.GameVersion = "3.0";
modGlobalVars.GameBuild = "132";
modGlobalVars.ModeVerLabel = `$Fps fps\t$UpTime\tRotd $GameVersion $BranchName $IsMobile`;

--==
local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library:WaitForChild("BranchConfigurationsRotd"));
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
local modMissionLibrary = shared.require(game.ReplicatedStorage.Library.MissionLibraryRotd);
local modSettings = shared.require(game.ReplicatedStorage.Library.SettingsRotd);
local modSafehomesLibrary = shared.require(game.ReplicatedStorage.Library.SafehomesLibrary);
local modStatusEffects = shared.require(game.ReplicatedStorage.Library.StatusEffectsRotd);
local modWorldCoreClass = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd);
local modGameModeLibrary = shared.require(game.ReplicatedStorage.Library.GameModeLibrary);
local modEmotesCommsLibrary = shared.require(game.ReplicatedStorage.Library.EmoteCommsLibraryRotd);
local modSkillTreeLibrary = shared.require(game.ReplicatedStorage.Library.SkillTreeLibraryRotd);
local modGpsLibrary = shared.require(game.ReplicatedStorage.Library.GpsLibrary);
local modFactionsLibrary = shared.require(game.ReplicatedStorage.Library.FactionsLibraryRotd);
local modFarmingSystem = shared.require(game.ReplicatedStorage.Library.FarmingSystem);

if RunService:IsServer() then
    local modProfile = shared.require(game.ServerScriptService.ServerLibrary.ProfileRotd);
    local modGameSave = shared.require(game.ServerScriptService.ServerLibrary.GameSaveRotd);
    local modApiRequestLibrary = shared.require(game.ServerScriptService.ServerLibrary.ApiRequestLibraryRotd);
    local modItemDrops = shared.require(game.ServerScriptService.ServerLibrary.ItemDropsRotd);
    local modShopSystem = shared.require(game.ServerScriptService.ServerLibrary.ShopSystem);
    local modGameModeManager = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager);
    local modAnalyticsService = shared.require(game.ServerScriptService.ServerLibrary.AnalyticsService);

    
    modAnalyticsService:InitCurrencies{
        Money = "Money";
        Perks = "Perks";
        TweakPoints = "TweakPoints";
        Gold = "Gold";
        PlayPoints = "PlayPoints";
        FactionMoney = "FactionMoney";
    };
    modAnalyticsService:InitOnBoardingSteps{
        ClickPlay = 1;

        Mission1_WakeUp = 2;
        Mission1_TakePistol = 3;
        Mission1_EquipPistol = 4;
        Mission1_Complete = 5;

        Mission2_WakeUp = 6;
        Mission2_TalkToMason = 7;
        Mission2_ExitBedroom = 8;
        Mission2_DrDeniskiHeal = 9;
        Mission2_PurchaseAmmo = 10;
        Mission2_KillTenZombies = 11;
        Mission2_Complete = 12;

        Mission5_Start = 13;
        Mission5_CheckBlueprintCost = 14;
        Mission5_BuildDamageMod = 15;
        Mission5_CollectDamageMod = 16;
        Mission5_Complete = 17;

        Mission6_Start = 18;
        Mission6_DestroyedBarricade = 19;
        Mission6_Complete = 20;

        Mission7_Start = 21;
        Mission7_EnteredBossFight = 22;
        Mission7_DefeatedBoss = 23;
        Mission7_UnlockedBloxmartGate = 24;
        Mission7_Complete = 25;
    };
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
    Debugger:Print("RotdCore onRequire.");
    
end

Debugger:Print("Init RotdCore.");
return RotdCore;