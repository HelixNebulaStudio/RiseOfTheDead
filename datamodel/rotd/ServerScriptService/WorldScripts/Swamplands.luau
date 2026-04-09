local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

if RunService:IsServer() then
    modGameModeSurvival = shared.require(game.ServerScriptService.ServerLibrary.GameModeSurvival);
    modGameModeManager = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager);
    modGameModeManager.GameWorld = true;
end

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new(script);

local GAME_MODE, GAME_STAGE = "Survival", "Swamplands";
--==

function WorldCore.InitGameController()
    local newGameController = modGameModeSurvival.new();

    newGameController.ModeType = GAME_MODE;
    newGameController.ModeStage = GAME_STAGE;

    newGameController.EnemiesList = {
        {Name="Zombie"; Chance=100;};
        {Name="Ticks"; Chance=50; Fmod=2;};
        {Name="Bloater"; Chance=35; Fmod=3;};
        {Name="Leaper"; Chance=25; Fmod=3;};
        {Name="Heavy"; Chance=15; Fmod=5;};
    }

    newGameController.BossConfig = {
        List={
            {Name="Zpider"; Chance=100;};
            {Name="Corrosive"; Chance=100;};
            {Name="Shadow"; Chance=100;};
        };
    };

    newGameController.FogConfig = {
        Density = 0.9;
    }

    newGameController.ObjectivesList = {
        {Type="Eliminate"; Chance=1; Fmod=1;};
        {Type="Boss"; Chance=1/4; Fmod=6;};
        {Type="SuppliesRequest"; Chance=1/9; Fmod=9;};
        {Type="ProtectObjTime"; Chance=1/5; Fmod=10;};
    };

    newGameController.HazardsList = {
        {Type="PotArmor"; Chance=1/2; Fmod=4;};
        {Type="VexSpitter"; Chance=1/5; Fmod=3;};
        {Type="Fog"; Chance=1/3; Fmod=4;};
    };

    newGameController.IntroMessage = "A low pitched humming vibrates the water in the Swamplands";

    function newGameController:BindWorldCoreEnemySpawn(npcClass: NpcClass)
        local npcChar = npcClass.Character;
    end

    task.spawn(function()
        newGameController:Load();
    end);

    return newGameController;
end

function WorldCore.onRequire()
    if RunService:IsClient() then return end;

    WorldCore:InitGameWorld(GAME_MODE, GAME_STAGE);

    shared.modEngineCore:ConnectOnPlayerAdded(script, function(player: Player)
        local playerClass: PlayerClass = shared.modPlayers.get(player);

        task.spawn(function()
            while true do
                task.wait(1);
                if playerClass.Character == nil or playerClass.HealthComp.IsDead then continue end;

                local cf = playerClass:GetCFrame();
                if cf.Position.Y > -2 then continue end;

                playerClass.StatusComp:Apply("RedCrowToxin", {
                    Expires = workspace:GetServerTimeNow() + 1.2;
                    Duration = 1.2;
                });
            end
        end)
    end)
end


return WorldCore;