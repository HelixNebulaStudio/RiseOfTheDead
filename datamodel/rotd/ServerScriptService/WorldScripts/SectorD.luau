local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

if RunService:IsServer() then
    modGameModeSurvival = shared.require(game.ServerScriptService.ServerLibrary.GameModeSurvival);
    modGameModeManager = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager);
    modGameModeManager.GameWorld = true;
end

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new(script);

local GAME_MODE, GAME_STAGE = "Survival", "SectorD";
--==

function WorldCore.InitGameController()
    local newGameController = modGameModeSurvival.new();

    newGameController.ModeType = GAME_MODE;
    newGameController.ModeStage = GAME_STAGE;

    newGameController.EnemiesList = {
        {Name="Zombie"; Chance=100;};
        {Name="Ticks"; Chance=50; Fmod=2;};
        {Name="Leaper"; Chance=25; Fmod=3;};
        {Name="Heavy"; Chance=15; Fmod=4;};
        {Name="Bloater"; Chance=10; Fmod=5;};
        {Name="Growler"; Chance=10; Fmod=6;};
        {Name="Dr. Sinister"; Chance=1; StartWave=10; Fmod=5;};
    }

    newGameController.BossConfig = {
        List={
            {Name="Shadow"; Chance=100;};
            {Name="Zomborg Prime"; Chance=100;};
            {Name="Zomborg"; Chance=100;};
        };
    };

    newGameController.ExtremeBossConfig = {
        List={
            {Name="Jaws"; Chance=100;};
            {Name="Vein Of Nekron"; Chance=100;};
        };
    };

    newGameController.ObjectivesList = {
        {Type="Eliminate"; Fmod=1;};
        {Type="ProtectObjTime"; Fmod=4;};	
        {Type="Boss"; Fmod=6;};
        {Type="SuppliesRequest"; Fmod=9;};
        {Type="ExtremeBoss"; Fmod=10;};
    };

    newGameController.FogConfig = {
        Density = 0.7;
    };

    newGameController.HazardsList = {
        {Type="Fog"; Fmod=4;};
        {Type="TicksGalore"; Fmod=10;};
    };

    newGameController.CorruptVision = {
        TintColor = Color3.fromRGB(250, 192, 185);
    };

    newGameController.IntroMessage = "Lights and dials of experimental apparatus flickers in Sector D";

    function newGameController:OnEnemySpawn(npcClass: NpcClass)
        local npcChar = npcClass.Character;
        if npcChar.Name ~= "Zombie"
        and npcChar.Name ~= "Leaper Zombie"
        and npcChar.Name ~= "Heavy Zombie" then return end;
        
        local shirtList = {
            "rbxassetid://2240854863";
            "rbxassetid://981391795";
        }
        
        if math.random(1, 3) == 1 then
            npcClass.SetShirt = shirtList[math.random(1, #shirtList)];
        end
    end

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