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

local GAME_MODE, GAME_STAGE = "Raid", "Eighth Street";
local MAP_SEED = math.random(1, 9999);
--==

function WorldCore.InitGameController()
    if RunService:IsStudio() and shared.gameConfig.MapSeed ~= nil then
        MAP_SEED = shared.gameConfig.MapSeed;
    end
    local newGameController = modGameModeRaid.new();

    newGameController.ModeType = GAME_MODE;
    newGameController.ModeStage = GAME_STAGE;

    newGameController.Objective = {
        Id = "Eliminate";
        EnemyCap = 45;
        
        HordeWhenEnemiesDropsBelow = 1;
        HordeCycle = 600;
        HordeSpawnRate = 1;

        HordeTimerDeduction = NumberRange.new(25, 35);
    };

    newGameController.EnemiesList = {
        {Name="Zombie"; Chance=100;};
    };

	local mapWaveCollapse = modWaveCollapseSystem.new(workspace.Environment.CollapseMapTemplate);
    mapWaveCollapse:UpdateBaseConstraint(function(baseConstraint)
        baseConstraint.CountLimit = 16;
    end)
	mapWaveCollapse:PrototypeConstraints({
		-- TileRoadZ = {CountLimit=16};
		-- TileRoadZS = {CountLimit=16};
		-- TileRoadX = {CountLimit=16};
		-- TileRoadXS = {CountLimit=16};
		-- TileRoadNW = {CountLimit=16};
		-- TileRoadSW = {CountLimit=16};
		-- TileRoadNE = {CountLimit=16};
		-- TileRoadSE = {CountLimit=16};
	});


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

        mapWaveCollapse:SetSeed(MAP_SEED);
        mapWaveCollapse:Solve(workspace.Environment.CollapseMap);

        WorldCore.MapWaveCollapse = mapWaveCollapse;
        
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