local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modTouchHandler = shared.require(game.ReplicatedStorage.Library.TouchHandler);
local modHealthComponents = shared.require(game.ReplicatedStorage.Components.HealthComponent);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

if RunService:IsServer() then
    modGameModeStronghold = shared.require(game.ServerScriptService.ServerLibrary.GameModeStronghold);
    modGameModeManager = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager);
    modGameModeManager.GameWorld = true;
end

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new(script);

local GAME_MODE, GAME_STAGE = "Raid", "North Star Embassy";
--=

function WorldCore.InitGameController()
    local newGameController = modGameModeStronghold.new();

    newGameController.ModeType = GAME_MODE;
    newGameController.ModeStage = GAME_STAGE;

    newGameController.EnemiesList = {
        {Name="Bandit"; Chance=100;};
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