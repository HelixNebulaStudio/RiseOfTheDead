local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

if RunService:IsServer() then
    modGameModeSurvival = shared.require(game.ServerScriptService.ServerLibrary.GameModeSurvival);
    modGameModeManager = shared.require(game.ServerScriptService.ServerLibrary.GameModeManager);
    modGameModeManager.GameWorld = true;
end

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new(script);

local GAME_MODE, GAME_STAGE = "Survival", "Sector F";
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
    }

    newGameController.BossConfig = {
        List={
            {Name="Tanker"; Chance=100;};
            {Name="Fumes"; Chance=100;};
            {Name="Corrosive"; Chance=100;};
            {Name="The Prisoner"; Chance=100;};
        };
    };

    newGameController.FogConfig = {
        Density = 0.9;
    }

    newGameController.ObjectivesList = {
        {Type="Eliminate"; Fmod=1;};
        {Type="Boss"; Fmod=6;};
        {Type="SuppliesRequest"; Fmod=9;};
        {Type="ProtectObjTime"; Fmod=10;};
        -- {Type="Oily"; Fmod=3;};
    };

    newGameController.HazardsList = {
        {Type="Fog"; Fmod=4;};
        {Type="Witherers"; Fmod=3;};
        -- {Type="ToxicGas"; Fmod=6;};
    };

    newGameController.CorruptVision = {};

    newGameController.IntroMessage = "Sparks from exposed wiring sizzles the floor in Sector F";

    function newGameController:OnEnemySpawn(npcClass: NpcClass)
        local npcChar = npcClass.Character;
        if npcChar.Name ~= "Zombie"
            and npcChar.Name ~= "Leaper Zombie"
            and npcChar.Name ~= "Heavy Zombie" then return end;
        
        local shirtList = {
            "rbxassetid://2240854863";
            "rbxassetid://981391795";
        }
        
        if math.random(1, 4) == 1 then
            npcClass.Properties.PresetShirt = {Id=shirtList[math.random(1, #shirtList)]};
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

    shared.modNpcs.spawn2{
        Name = "Lennon";
        CFrame = CFrame.new(9.44034672, 60.2189713, -17.7514229, -1, 0, 0, 0, 1, 0, 0, 0, -1);
    };
    
	script:WaitForChild("sewersWindow"):Clone().Parent = workspace.Interactables;

    shared.modEngineCore:ConnectOnPlayerAdded(script, function(player: Player)
        local profile: ProfileRotd = shared.modProfile:WaitForProfile(player) :: ProfileRotd;
        if profile == nil then return end;

        task.delay(10, function()
            local remotes = game.ReplicatedStorage:WaitForChild("Remotes");
            local remoteSetHeadIcon = remotes:WaitForChild("SetHeadIcon");
            remoteSetHeadIcon:FireAllClients(1, "Lennon", "HideAll");
        end)
    end, 999);
end


return WorldCore;