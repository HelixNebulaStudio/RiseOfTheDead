local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modTouchHandler = shared.require(game.ReplicatedStorage.Library.TouchHandler);
local modHealthComponents = shared.require(game.ReplicatedStorage.Components.HealthComponent);
local modProjectile = require(game.ReplicatedStorage.Library.Projectile);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

if RunService:IsServer() then
    modGameModeManager = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager);
    modGameModeCoop = shared.require(game.ServerScriptService.ServerLibrary.GameModeCoop);
    modFlammable = require(game.ServerScriptService.ServerLibrary.Flammable);

    modGameModeManager.GameWorld = true;
end

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new(script);

local GAME_MODE, GAME_STAGE = "Coop", "Genesis";
--=

function WorldCore.InitGameController()
    local newGameController = modGameModeCoop.new();

    newGameController.ModeType = GAME_MODE;
    newGameController.ModeStage = GAME_STAGE;

    newGameController.EnemiesList = {
        {Name="Zombie"; Chance=100;};
        {Name="Ticks"; Chance=10;};
    };

    task.spawn(function()
        newGameController:Load();
    end);

    return newGameController;
end

function WorldCore.onRequire()
    if RunService:IsClient() then return end;
    
    WorldCore:InitGameWorld(GAME_MODE, GAME_STAGE);

    task.spawn(function()
        local random = Random.new();
        local gameObjects = workspace:WaitForChild("Environment"):WaitForChild("Game");
        local leakyGasolinePipe = gameObjects:WaitForChild("leakyGasolinePipe");

        while true do
			local origin = CFrame.new(leakyGasolinePipe.Position);
			local dirCf = CFrame.lookAt(
                origin.Position, 
                origin.Position 
                + Vector3.new(random:NextNumber(-1,1), 0, random:NextNumber(-1,1))
            ).LookVector * random:NextNumber(0,1)
			
            local projectileInstance = modProjectile.fire("gasoline", {
                OriginCFrame = origin;
                SpreadDirection = dirCf;
            });

            modProjectile.serverSimulate(projectileInstance, {
                RayWhitelist = {workspace.Environment};
                Velocity = dirCf * 20;
                IgnoreEntities = true;
            });
            
			task.wait(math.random(4,9)/10);
			modFlammable:Ignite(projectileInstance.Part);
        end

    end)
end

return WorldCore;