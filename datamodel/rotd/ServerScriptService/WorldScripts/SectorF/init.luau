local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);

if RunService:IsServer() then
	modMission = shared.require(game.ServerScriptService.ServerLibrary.Mission);
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
        {Name="Ticks"; Chance=50; Fmod=2;};
        {Name="Leaper"; Chance=25; Fmod=3;};
        {Name="Heavy"; Chance=15; Fmod=4;};
        {Name="Bloater"; Chance=10; Fmod=5;};
    }

    newGameController.BossConfig = {
        List={
            {Name="The Prisoner"; Chance=100;};
            {Name="Tanker"; Chance=100;};
            {Name="Fumes"; Chance=100;};
            {Name="Corrosive"; Chance=100;};
        };
    };

    newGameController.FogConfig = {
        Density = 0.9;
    }

    newGameController.ObjectivesList = {
        {Type="Eliminate"; Chance=1; Fmod=1;};
        {Type="ProtectObjTime"; Chance=1/3; Fmod=10;};
        {Type="Boss"; Chance=1/4; Fmod=6;};
        {Type="Oily"; Chance=1/4; Fmod=3;};
        {Type="SuppliesRequest"; Chance=1/9; Fmod=9;};
    };

    newGameController.HazardsList = {
        {Type="PotArmor"; Chance=1/2; Fmod=4;};
        {Type="Witherers"; Chance=1/4; Fmod=3;};
        {Type="VexSpitter"; Chance=1/5; Fmod=3;};
        {Type="Fog"; Chance=1/6; Fmod=4;};
    };

    newGameController.CorruptVision = {};

    newGameController.IntroMessage = "Sparks from exposed wiring sizzles the floor in Sector F";

    function newGameController:BindWorldCoreEnemySpawn(npcClass: NpcClass)
        local npcChar = npcClass.Character;
        if npcChar.Name ~= "Zombie"
            and npcChar.Name ~= "Leaper"
            and npcChar.Name ~= "Heavy" then return end;
        
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
    
    local newSewersMsg = script:WaitForChild("sewersWindow"):Clone();
	newSewersMsg.Parent = workspace.Interactables;
    local sewersMsgConfig = modInteractables.createInteractable("Message");
    sewersMsgConfig:SetAttribute("Text", "Lennon: You can do it!");
    sewersMsgConfig.Parent = newSewersMsg;

    shared.modEngineCore:ConnectOnPlayerAdded(script, function(player: Player)
        local profile: ProfileRotd = shared.modProfile:WaitForProfile(player) :: ProfileRotd;
        if profile == nil then return end;

        task.delay(10, function()
            local remotes = game.ReplicatedStorage:WaitForChild("Remotes");
            local remoteSetHeadIcon = remotes:WaitForChild("SetHeadIcon");
            remoteSetHeadIcon:FireAllClients(1, "Lennon", "HideAll");
        end)

        Debugger:Warn(`IsGameWorld = {modGameModeManager.IsGameWorld }`);
        if modGameModeManager.IsGameWorld == true then return end;

        local mission62 = modMission:GetMission(player, 62);
        if mission62 and mission62.Type == 1 then
            game.Players:SetAttribute("AutoRespawn", true);
        end

    end, 999);
end


return WorldCore;