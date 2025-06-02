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
    end)

    
    task.spawn(function()
        local modWeatherService = shared.require(game.ReplicatedStorage.Library.WeatherService);
        modWeatherService:SetWeather({
            Id="heavyrain";
        });
    end)
end

return WorldCore;