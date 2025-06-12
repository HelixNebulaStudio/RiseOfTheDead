local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modAudio = require(game.ReplicatedStorage.Library.Audio);
local modMissionLibrary = require(game.ReplicatedStorage.Library.MissionLibrary);
local modCutscene = require(game.ReplicatedStorage.Library.Cutscene);

local WorldCore = shared.require(game.ReplicatedStorage.Library.WorldCoreClass).new();
--==

function WorldCore.onRequire()
    if RunService:IsServer() then
        local modMission = require(game.ServerScriptService.ServerLibrary.Mission);

        shared.modEngineCore:ConnectOnPlayerAdded(script, function(player: Player)
            task.delay(5, function()
                if modMission:GetMission(player, 1) == nil then
                    modMission:AddMission(player, 1);
                    Debugger:Warn("Add mission 1");
                end
            end)

            local lib = modMissionLibrary.Get(1);
            modCutscene:LoadScript(lib.Name, lib.CutsceneScript);
            modCutscene.LazyLoader:Load(player, lib.Name);
        end)

        task.spawn(function()
            local modWeatherService = shared.require(game.ReplicatedStorage.Library.WeatherService);
            modWeatherService:SetWeather({
                Id="heavyrain";
            });

            modAudio.Play("Fire", workspace.Environment:WaitForChild("Destrutable"):WaitForChild("A"):WaitForChild("ExplosionPart"), true);
            modAudio.Play("WindAmbient1", workspace.Environment:WaitForChild("AmbientPart"), true);
            modAudio.Play("OceanAmbient1", workspace.Environment:WaitForChild("AmbientPart"), true);
        end)

    elseif RunService:IsClient() then
        
    end
end

return WorldCore;