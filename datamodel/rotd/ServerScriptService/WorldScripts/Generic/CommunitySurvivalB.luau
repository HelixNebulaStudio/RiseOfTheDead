local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modBranchConfigurations = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modAudio = shared.require(game.ReplicatedStorage.Library.Audio);
local modClothingLibrary = shared.require(game.ReplicatedStorage.Library.ClothingLibrary);
local modGameModeLibrary = shared.require(game.ReplicatedStorage.Library.GameModeLibrary);

if RunService:IsServer() then
    modGameModeSurvival = shared.require(game.ServerScriptService.ServerLibrary.GameModeSurvival);
    modGameModeManager = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager);
    modGameModeManager.GameWorld = true;
end

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new(script);

local GAME_MODE, GAME_STAGE = "Survival", modBranchConfigurations.WorldName;
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
        {Name="Growler"; Chance=10; Fmod=6;};
        {Name="Dr. Sinister"; Chance=2; StartWave=10; Fmod=5;};
    }

    newGameController.BossConfig = {
        List={
            {Name="The Prisoner"; Chance=100;};
            {Name="Zpider"; Chance=100;};
            {Name="Shadow"; Chance=100;};
            {Name="Zomborg"; Chance=100;};
        };
    };

    newGameController.ExtremeBossConfig = {
        List={
            {Name="Jaws"; Chance=100;};
            {Name="Vein Of Nekron"; Chance=100;};
        };
    };

    newGameController.FogConfig = {
	    Density = 0.8;
    }

    newGameController.ObjectivesList = {
        {Type="SurviveTime"; Fmod=1;};
        {Type="ProtectObjTime"; Fmod=4;};	
        {Type="Boss"; Fmod=6;};
        {Type="SuppliesRequest"; Fmod=9;};
        {Type="ExtremeBoss"; Fmod=10;};
    };

    newGameController.HazardsList = {
        {Type="Fog"; Fmod=8;};
        {Type="Witherers"; Fmod=6;};
    };

    newGameController.CorruptVision = {
	    TintColor = Color3.fromRGB(151, 169, 204);
    };

    newGameController.IntroMessage = shared.gameConfig.IntroMessage;

    function newGameController:OnEnemySpawn(npcClass: NpcClass)
        local charModel = npcClass.Character;
        if charModel.Name ~= "Zombie"
            and charModel.Name ~= "Leaper Zombie"
            and charModel.Name ~= "Heavy Zombie" then return end;
        
        local shirtList = {
            "rbxassetid://1424001775";
            "rbxassetid://249313146";
            "rbxassetid://1581395859";
        }
        
        if math.random(1, 3) == 1 then
            npcClass.Properties.PresetShirt = {Id=shirtList[math.random(1, #shirtList)]};
        end
    end

    task.spawn(function()
        newGameController:Load();
    end);

    return newGameController;
end

function WorldCore.onRequire()
    if RunService:IsClient() then

        local customAudio = shared.gameConfig.Config:FindFirstChild("Survival");
        if customAudio then
            local gameModeLib = modGameModeLibrary.GetStage(GAME_MODE, GAME_STAGE);
            
            for _, folder in ipairs(customAudio:GetChildren()) do
                local trackType = folder.Name;
                if gameModeLib[trackType] == nil then
                    Debugger:Warn(`Invalid audio track type: {trackType}`)
                    continue;
                end

                local names = {};
                for _, track in ipairs(folder:GetChildren()) do
                    if track:IsA("Sound") then
                        table.insert(names, track.Name);
                        modAudio.Load(track);
                    end
                end

                if #names > 0 then
                    gameModeLib[trackType] = names;
                end
            end
        end
        
        return;
    end;

    WorldCore:InitGameWorld(GAME_MODE, GAME_STAGE);
end


return WorldCore;