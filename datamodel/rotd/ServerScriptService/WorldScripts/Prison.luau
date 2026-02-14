local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);

if RunService:IsServer() then
    modGameModeSurvival = shared.require(game.ServerScriptService.ServerLibrary.GameModeSurvival);
    modGameModeManager = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager);
    modGameModeManager.GameWorld = true;
end

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new(script);

local GAME_MODE, GAME_STAGE = "Survival", "Prison";
--==

function WorldCore.InitGameController()
    local newGameController = modGameModeSurvival.new();

    newGameController.ModeType = GAME_MODE;
    newGameController.ModeStage = GAME_STAGE;

    newGameController.EnemiesList = {
        {Name="Zombie"; Chance=100;};
        {Name="Ticks Zombie"; Chance=50; Fmod=2;};
        {Name="Leaper Zombie"; Chance=25; Fmod=3;};
        {Name="Heavy Zombie"; Chance=15; Fmod=4;};
        {Name="Bloater"; Chance=10; Fmod=5;};
        {Name="Dr. Sinister"; Chance=1; Fmod=6;};
    }

    newGameController.BossConfig = {
        List={
            {Name="The Prisoner"; Chance=100;};
            {Name="Zpider"; Chance=100;};
            {Name="Shadow"; Chance=100;};
            {Name="Zomborg"; Chance=100;};
        };
    };

    newGameController.FogConfig = {
	    Density = 0.7;
    }

    newGameController.ObjectivesList = {
        {Type="Eliminate"; Fmod=1;};
        --{Type="Oily"; Fmod=2;};	
        {Type="ProtectObjTime"; Fmod=4;};	
        {Type="Boss"; Fmod=6;};
        {Type="SuppliesRequest"; Fmod=9;};
    };

    newGameController.HazardsList = {
	    {Type="Fog"; Fmod=4;};
    };

    newGameController.CorruptVision = {
	    TintColor = Color3.fromRGB(151, 169, 204);
    };

    newGameController.IntroMessage = "Cell bars clinks in the Wrighton Dale Prison";

    function newGameController:OnEnemySpawn(npcClass: NpcClass)
        local npcChar = npcClass.Character;
        if npcChar.Name ~= "Zombie"
            and npcChar.Name ~= "Leaper Zombie"
            and npcChar.Name ~= "Heavy Zombie" then return end;
        
        local shirtList = {
            "rbxassetid://532764030";
            "rbxassetid://5943316923";
        }
        
        if math.random(1, 2) == 1 then
            npcClass.Properties.PresetShirt = {Id=shirtList[math.random(1, #shirtList)];};
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
    
	modAudio.Play("MetalicAmbience", workspace, true);
end


return WorldCore;