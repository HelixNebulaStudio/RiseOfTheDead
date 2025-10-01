local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

if RunService:IsServer() then
    modGameModeStronghold = shared.require(game.ServerScriptService.ServerLibrary.GameModeStronghold);
    modGameModeManager = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager);
    modGameModeManager.GameWorld = true;
end

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new();

local GAME_MODE, GAME_STAGE = "Raid", "BanditOutpost";
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

function WorldCore.BindGameControllerInited(gameController)
    Debugger:StudioLog(`gameController`, gameController);
	if gameController.RoomData and gameController.RoomData.Mission then
        Debugger:StudioLog(`IsinMission`, gameController.RoomData.Mission);
	end
end

return WorldCore;