local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modTouchHandler = shared.require(game.ReplicatedStorage.Library.TouchHandler);
local modHealthComponents = shared.require(game.ReplicatedStorage.Components.HealthComponent);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

if RunService:IsServer() then
    modGameModeRaid = shared.require(game.ServerScriptService.ServerLibrary.GameModeRaid);
    modGameModeManager = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager);
    modGameModeManager.GameWorld = true;
end

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new(script);

local GAME_MODE, GAME_STAGE = "Raid", "NorthStarEmbassy";
--=

function WorldCore.InitGameController()
    local newGameController = modGameModeRaid.new();

    newGameController.ModeType = GAME_MODE;
    newGameController.ModeStage = GAME_STAGE;

    newGameController.Objective = {
        Id = "Eliminate";

        --EliminateGoal = 100;
        EnemyCap = 35;

        HordeWhenEnemiesDropsBelow = 4;
        HordeCycle = 300;
        HordeSpawnRate = 0.5;
        HordeTimerDeduction = NumberRange.new(25, 35);
    };

    newGameController.EnemiesList = {
        {Name="Zombie"; Chance=100;};
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