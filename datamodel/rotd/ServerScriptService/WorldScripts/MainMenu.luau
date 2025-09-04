local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClassRotd).new();
--==

function WorldCore.onRequire()
    if RunService:IsClient() then return end;

    local menuScenesList = game.ServerStorage:WaitForChild("MenuScenes"):GetChildren();
    local newRandomScene = menuScenesList[math.random(1, #menuScenesList)]:Clone();
    local existingScene = workspace.Environment:FindFirstChildWhichIsA("Model");
    if existingScene then
        existingScene.Name = "Scene";
        newRandomScene.Parent = game.ServerStorage;
        
    else
        newRandomScene.Name = "Scene";
        newRandomScene.Parent = workspace.Environment;
        
    end


    local repFocus = script:WaitForChild("RepFocus");
    repFocus.Parent = workspace;

    shared.modEngineCore:ConnectOnPlayerAdded(script, function(player: Player)
	    player.ReplicationFocus = repFocus.PrimaryPart;

        local profile: ProfileRotd = shared.modProfile:WaitForProfile(player) :: ProfileRotd;
        if profile == nil then return end;

        WorldCore:LoadPlayerMissions(player, profile);
    end)

    
    task.spawn(function()
        local modWeatherService = shared.require(game.ReplicatedStorage.Library.WeatherService);
        modWeatherService:SetWeather({
            Id="heavyrain";
        });
    end)
end

function WorldCore:LoadPlayerMissions(player: Player, profile: ProfileRotd)
    local modBlueprints = shared.require(game.ServerScriptService.ServerLibrary.Blueprints);

	local gameSave: GameSaveRotd = profile:GetActiveSave() :: GameSaveRotd;
	local missionsProfile: MissionsProfile = gameSave and gameSave.Missions;

    local mission5 = missionsProfile:Get(5);
    if mission5 and (mission5.Type == 1 or mission5.Type == 3) then
        modBlueprints.UnlockBlueprint(player, "pistoldamagebp");
        modBlueprints.UnlockBlueprint(player, "pistolfireratebp", nil, false);
    end
    
    local mission8 = missionsProfile:Get(8);
    if mission8 and (mission8.Type == 1 or mission8.Type == 3) then
        modBlueprints.UnlockBlueprint(player, "medkitbp");
    end
    
    local mission9 = missionsProfile:Get(9);
    if mission9 and (mission9.Type == 1 or mission9.Type == 3) then
        modBlueprints.UnlockBlueprint(player, "incendiarybp");
    end
    
    local mission15 = missionsProfile:Get(15);
    if mission15 and (mission15.Type == 1 or mission15.Type == 3) then
        modBlueprints.UnlockBlueprint(player, "electricbp");
    end
    
end

return WorldCore;