local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modTouchHandler = shared.require(game.ReplicatedStorage.Library.TouchHandler);
local modHealthComponents = shared.require(game.ReplicatedStorage.Components.HealthComponent);

local DamageData = shared.require(game.ReplicatedStorage.Data.DamageData);

if RunService:IsServer() then
    modGameModeRaid = shared.require(game.ServerScriptService.ServerLibrary.GameModeRaid);
    modGameModeManager = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager);
    modGameModeManager.GameWorld = true;
end

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new();

local GAME_MODE, GAME_STAGE = "Raid", "Office";
--=

function WorldCore.InitGameController()
    local newGameController = modGameModeRaid.new();

    newGameController.ModeType = GAME_MODE;
    newGameController.ModeStage = GAME_STAGE;

    newGameController.Objective = {
        Id="Eliminate";
        EliminateGoal=100;
        
        SpawnPlatformRadius=64;
        EnemyCap=35;
        MinSpawnCount=6;
        MaxSpawnCount=12;
        
        HordeWhenEnemiesDropsBelow=4;
        HordeCycle=300;
        HordeSpawnRate=0.5;
    };

    newGameController.EnemiesList = {
        {Name="Zombie"; Chance=100;};
        {Name="Leaper"; Chance=15; Fmod=15;};
        {Name="Ticks"; Chance=10; Fmod=10;};
        {Name="Heavy"; Chance=0.1; Fmod=10;};
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
        local touchHandler = modTouchHandler.new("BarbedFence", 1);
        local woodenBarb = workspace.Debris:WaitForChild("woodenBarb");
        local hitbox = woodenBarb:WaitForChild("Hitbox");

        touchHandler:AddObject(hitbox);
        function touchHandler:OnHumanoidTouch(humanoid, basePart, hitPart)
            local targetModel = hitPart.Parent;
            if targetModel == nil or not targetModel:IsA("Model") then return end;

            local healthComp: HealthComp = modHealthComponents.getByModel(targetModel);
            if healthComp == nil or healthComp.CompOwner.ClassName ~= "NpcClass" then return end;

            local npcClass: NpcClass = healthComp.CompOwner :: NpcClass;

            local damage = math.clamp(healthComp.MaxHealth * 0.001, 10, math.huge);
            healthComp:TakeDamage(DamageData.new{
                Damage = damage;
                TargetPart = hitPart;
            });

            local statusComp: StatusComp = npcClass.StatusComp;

            statusComp:Apply("BarbSlow", {
                Expires = workspace:GetServerTimeNow() + 2;
                Values = {
                    SlowValue = 2;
                }
            });
        end
    end)
end

return WorldCore;