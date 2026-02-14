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
        {Name="Dr. Sinister"; Chance=10; Fmod=7;};
    }

    newGameController.BossConfig = {
        List={
            {Name="Corrosive"; Chance=100;};
            {Name="Fumes"; Chance=100;};
            {Name="Zomborg"; Chance=100;};
            {Name="Zomborg Prime"; Chance=100;};
        };
    };

    newGameController.ExtremeBossConfig = {
        List={
            {Name="Vein Of Nekron"; Chance=100;};
        };
    };

    newGameController.FogConfig = {
	    Density = 0.7;
    }

    newGameController.ObjectivesList = {
        {Type="SurviveTime"; Fmod=1;};
        {Type="ProtectObjTime"; Fmod=4;};
        {Type="Boss"; Fmod=5;};
        {Type="ExtremeBoss"; Fmod=10;};
        {Type="SuppliesRequest"; Fmod=9;};
    };

    newGameController.HazardsList = {
        {Type="HighSeas"; Fmod=4;};
        {Type="HeavyRain"; Fmod=5;};
        {Type="Airstrikes"; Fmod=6;};
        {Type="TicksGalore"; Fmod=9;};
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
            "rbxassetid://1079116841";
            "rbxassetid://1052438047";
            "rbxassetid://9644605742";
        }
        
        if math.random(1, 3) == 1 then
            npcClass.Properties.PresetShirt = {Id=shirtList[math.random(1, #shirtList)]};
        end
        
        if charModel.Name == "Zombie" and math.random(1, 10) <= 2 then
            task.spawn(function()
                local templateHardHat = modClothingLibrary.getPrefabList("hardhat")[1];
                if templateHardHat == nil then return end;

                local hardHat = templateHardHat:Clone();
                if math.random(1, 3) >= 2 then
                    for _, obj in pairs(hardHat:WaitForChild("Handle"):GetChildren()) do
                        if obj.Name == "_lightPoint" then
                            game.Debris:AddItem(obj, 0);
                        end
                    end
                end
                hardHat.Parent = charModel;
                
                npcClass.Garbage:Tag(hardHat);
            end)
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