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
            {Name="Fumes"; Chance=100;};
            {Name="Zomborg"; Chance=100;};
            {Name="Zomborg Prime"; Chance=100;};
            {Name="Tanker"; Chance=100;};
            {Name="The Billies"; Chance=100;};
        };
    };

    newGameController.ExtremeBossConfig = {
        List={
            {Name="Mothena"; Chance=100; ZombieSpawnChance=0;};
            {Name="Bandit Pilot"; Chance=100; HardChance=1; ZombieSpawnChance=0;};
        };
    };

    newGameController.FogConfig = {
	    Density = 0.8;
    }

    newGameController.ObjectivesList = {
        {Type="SurviveTime"; Fmod=1;};
        {Type="ProtectObjTime"; Fmod=4;};
        {Type="Boss"; Fmod=5;};
        {Type="ExtremeBoss"; Fmod=10;};
        {Type="SuppliesRequest"; Fmod=9;};
    };

    newGameController.HazardsList = {
        {Type="Fog"; Fmod=5;};
        {Type="Airstrikes"; Fmod=6;};
    };

    newGameController.CorruptVision = {
	    TintColor = Color3.fromRGB(151, 169, 204);
    };

    newGameController.IntroMessage = shared.gameConfig.IntroMessage;

    function newGameController:OnEnemySpawn(npcClass: NpcClass)
        local charModel = npcClass.Character;
        
        task.spawn(function()
            while workspace.Entity:IsAncestorOf(charModel) do
                task.wait(5);
                local pivot = charModel:GetPivot();
                if pivot.Y <= 200 then
                    charModel:Destroy();
                end
            end
        end)
        
        if charModel.Name == "Tanker" then
            charModel.Name = "The Manager";
            
            npcClass.Properties.PresetShirt = {Id="rbxassetid://10476909213"};
            npcClass.Properties.PresetPants = {Id="rbxassetid://6505810778"};

            -- npcModule.FollowLinkedUnits = false;
            -- npcModule.Garbage:Tag(npcClass.Think:Connect(function()
            --     npcModule.BehaviorTree:RunTree("DrSinisterTree", true);
            -- end));
            
            return;
            
        elseif charModel.Name == "Klyde" then
            npcClass.Properties.PresetShirt = {Id="rbxassetid://10018757058"};
            npcClass.Properties.PresetPants = {Id="rbxassetid://6505810778"};
            return;
            
        elseif charModel.Name == "Karl" then
            npcClass.Properties.PresetShirt = {Id="rbxassetid://10476909213"};
            npcClass.Properties.PresetPants = {Id="rbxassetid://6505810778"};
            
            task.spawn(function()
                local hat;
                repeat
                    task.wait(0.1) 
                    hat = charModel:FindFirstChild("Straw Hat");
                until hat or not workspace:IsAncestorOf(charModel);
                
                task.spawn(function()
                    local templateFedora = modClothingLibrary.getPrefabList("fedora")[1];
                    if templateFedora == nil then return end;

                    local fedora = templateFedora:Clone();
                    fedora.Parent = charModel;
                    
                    npcClass.Garbage:Tag(fedora);
                end)
            end)
            return;

        end
        
        -- Change any other enemies' shirt
        if charModel.Name ~= "Zombie"
            and charModel.Name ~= "Leaper Zombie"
            and charModel.Name ~= "Heavy Zombie" then return end;
        
        local shirtList = {
            "rbxassetid://5664380223";
            "rbxassetid://10080114469";
            "rbxassetid://5664456382";
            "rbxassetid://10018757058";
            "rbxassetid://9997554268";
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