local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

if RunService:IsServer() then
    modGameModeRaid = shared.require(game.ServerScriptService.ServerLibrary.GameModeRaid);
    modGameModeManager = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager);
    modGameModeManager.GameWorld = true;
end

local modPoster = shared.require(game.ReplicatedStorage.Library.Poster);
local modWaveCollapseSystem = shared.require(game.ReplicatedStorage.Library.WaveCollapseSystem);
local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new(script);

local GAME_MODE, GAME_STAGE = "Raid", "Abandoned Bunker";
local MAP_SEED = math.random(1, 9999); --if RunService:IsStudio() then MAP_SEED = 4262; end;
--==

function WorldCore.InitGameController()
    local newGameController = modGameModeRaid.new();

    newGameController.ModeType = GAME_MODE;
    newGameController.ModeStage = GAME_STAGE;

    newGameController.Objective = {
        Id = "Eliminate";
        EliminateGoal = 50;
        
        SpawnPlatformRadius = 64;
        EnemyCap = 20;
        MinSpawnCount = 2;
        MaxSpawnCount = 4;
        
        HordeWhenEnemiesDropsBelow = 2;
        HordeCycle = 120;
        HordeSpawnRate = 1;
    };

    newGameController.EnemiesList = {
        {Name="Zombie"; Chance=100;};
        {Name="Ticks"; Chance=50; Fmod=10;};
        {Name="Leaper"; Chance=25; Fmod=15;};
        {Name="Heavy"; Chance=15; Fmod=20;};
        {Name="Bloater"; Chance=10; Fmod=35; HordeWave=false;};
        {Name="Growler"; Chance=10; Fmod=50;};
        {Name="Dr. Sinister"; Chance=5; Fmod=60; HordeWave=false;};
    };

	local mapWaveCollapse = modWaveCollapseSystem.new(workspace.Environment.CollapseMapTemplate, MAP_SEED);

	mapWaveCollapse:PrototypeConstraints({
		TileFancyTransition = {Weight=4; TotalCountRequirement=24; CountLimit=1;};
		TileMidClassTransition = {Weight=4; TotalCountRequirement=16; CountLimit=1;};
		TileMidToFancyTransistion = {TotalCountRequirement=16; CountLimit=1;}; 
		TileDarkEntrance = {IsParent=true; TotalCountRequirement=1; CountLimit=1; CanSpawnFunc=function() return (RunService:IsStudio() or not workspace:GetAttribute("IsDayTime")); end};

		TileIntersection = {CountLimit=3};
		TileTIntersectionN = {CountLimit=2};
		TileTIntersectionS = {CountLimit=2};
		TileFancyIntersection = {CountLimit=2};
		TileFancyTLongN = {CountLimit=2};

		--Fancy
		TileRoomVar1 = {Weight=2; CountLimit=1};
		TileRoomVar4 = {CountLimit=1};
		TileFancyRoomVar3 = {CountLimit=1};

		--MidClass
		TileMidClassStore1 = {CountLimit=1};
		TileMidClassStore2 = {CountLimit=1};
		TileMidClassStore3 = {CountLimit=1};
		TileMidClassStore4 = {CountLimit=1};

		TileMidClassStore1X = {CountLimit=1};
		TileMidClassStore2X = {CountLimit=1};
		TileMidClassStore3X = {CountLimit=1};
		TileMidClassStore4X = {CountLimit=1};

		-- Special rooms;
		TileMidClassSecretStoreX = {Weight=4; CountLimit=2;};
		TileGreenRoom = {CountLimit=2; TotalCountRequirement=32;};
		TileSpiralChamber = {Weight=99; CountLimit=1; TotalCountRequirement=1;};
		TileIsolationRoom = {CountLimit=1; TotalCountRequirement=32;};

		TileDarkVariant1 = {IsParent=false; CountLimit=5};
		TileDarkVariant2 = {IsParent=false; CountLimit=5};
		TileDarkVariant3 = {IsParent=false; CountLimit=5};
		TileDarkVariant4 = {IsParent=false; CountLimit=5};
		TileDarkVariant5 = {IsParent=false; CountLimit=5};
		TileDarkVariant6 = {IsParent=false; CountLimit=5};
		TileDarkVariant7 = {IsParent=false; CountLimit=5};
		TileDarkVariant8 = {IsParent=false; CountLimit=5};
		TileDarkVariant9 = {IsParent=false; CountLimit=5};
		TileDarkVariant10 = {IsParent=false; CountLimit=5};
		TileDarkVariant11 = {IsParent=false; CountLimit=5};

	});
	mapWaveCollapse:Solve(workspace.Environment.CollapseMap);

    WorldCore.MapWaveCollapse = mapWaveCollapse;


    task.spawn(function()
        while modGameModeManager.TeleportDataLoaded ~= true do task.wait() end;
        
        local teleportData = modGameModeManager.TeleportData;
        local gameModeData = teleportData and teleportData.GameMode;
        local roomData = gameModeData and gameModeData.Room;
        
        local mapStorageItem = teleportData.MapStorageItem;
        if roomData.MapStorageItem then
            mapStorageItem = roomData.MapStorageItem;
        end
        
        Debugger:Warn("mapStorageItem", mapStorageItem);
        if mapStorageItem and mapStorageItem.Values and mapStorageItem.Values.Seed then
            MAP_SEED = mapStorageItem.Values.Seed;
        end
        
        task.delay(5, function()
            for _, player in pairs(game.Players:GetPlayers()) do
                shared.Notify(player, "Map Seed: ".. MAP_SEED, "Inform");
                Debugger:WarnClient(player, "Map Seed: "..MAP_SEED);
            end
        end)

        newGameController:Load();
        
        modPoster.LoadPosters(mapWaveCollapse.ParentFolder);
    end);

    return newGameController;
end

function WorldCore.onRequire()
    if RunService:IsClient() then return end;

    WorldCore:InitGameWorld(GAME_MODE, GAME_STAGE);
end

return WorldCore;