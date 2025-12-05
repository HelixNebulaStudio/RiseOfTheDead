local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

if RunService:IsServer() then
    modGameModeRaid = shared.require(game.ServerScriptService.ServerLibrary.GameModeRaid);
    modGameModeManager = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager);
    modGameModeManager.GameWorld = true;
end

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new(script);

local GAME_MODE, GAME_STAGE = "Raid", "Factory";
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
        {Name="Leaper"; Chance=15; Fmod=15;};
        {Name="Ticks"; Chance=10; Fmod=10;};
    };

    task.spawn(function()
        newGameController:Load();
    end);

    return newGameController;
end

function WorldCore.onRequire()
    if RunService:IsClient() then return end;

    WorldCore:InitGameWorld(GAME_MODE, GAME_STAGE);
end

return WorldCore;