local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modTables = shared.require(game.ReplicatedStorage.Library.Util.Tables);

if RunService:IsServer() then
    modGameModeManager = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager);
    modGameModeCoop = shared.require(game.ServerScriptService.ServerLibrary.GameModeCoop);

    modGameModeManager.GameWorld = true;
end

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new(script);

local GAME_MODE, GAME_STAGE = "Coop", "SunkenShip";
--=

function WorldCore.InitGameController()
    local newGameController = modGameModeCoop.new();

    newGameController.ModeType = GAME_MODE;
    newGameController.ModeStage = GAME_STAGE;

    task.spawn(function()
        newGameController:Load();
    end);

    return newGameController;
end

function WorldCore.onRequire()
    if RunService:IsClient() then return end;
    
    WorldCore:InitGameWorld(GAME_MODE, GAME_STAGE);

    shared.modNpcs.spawn2{
        Name = "Mysterious Engineer";
    }

    task.spawn(function()
        while true do
            task.wait(1);

            local validPlayers = {};
            for _, player in ipairs(game.Players:GetPlayers()) do
                local playerClass: PlayerClass = shared.modPlayers.get(player);
                if playerClass == nil then continue end;
                local playerCf = playerClass:GetCFrame();
                if playerCf == nil or playerCf.Position.Y > 229 then continue end;

                table.insert(validPlayers, playerClass);
            end

            if #validPlayers <= 0 then continue end;
            modTables.Shuffle(validPlayers);

            local numToSpawn = math.random(1, #validPlayers);
            for a=1, numToSpawn do
                local pickPlayer = validPlayers[a];

                shared.modNpcs.spawn2{
                    Name = "Vex Spitter";
                    CFrame = pickPlayer:GetCFrame();
                };
                task.wait(1);
            end
            task.wait(math.random(22, 42));
        end
    end)

end

return WorldCore;