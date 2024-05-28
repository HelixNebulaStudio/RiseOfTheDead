local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local WeatherService = {};

local RunService = game:GetService("RunService");
local HttpService = game:GetService("HttpService");

local modEventService = require(game.ReplicatedStorage.Library.EventService);
local modLayeredVariable = require(game.ReplicatedStorage.Library.LayeredVariable);
local modWeatherLibrary = require(game.ReplicatedStorage.Library.WeatherLibrary);

WeatherService.WeatherLayers = modLayeredVariable.new({});
WeatherService.ActiveWeather = nil;

local onWeatherSetEventHandler = modEventService:GetHandler("WeatherService.OnWeatherSet", true);
onWeatherSetEventHandler:SetPermissions("CanListen", true);
--==

function WeatherService:OnTick()
    local activeWeather = WeatherService.WeatherLayers:Get();
    if WeatherService.ActiveWeather and WeatherService.ActiveWeather.Id == activeWeather.Id then return; end;
    WeatherService.ActiveWeather = activeWeather;

    if activeWeather.StartTick == nil then
        activeWeather.StartTick = workspace:GetServerTimeNow();
    end

    for a=#WeatherService.WeatherLayers.Table, 1, -1 do
        local weatherLayer = WeatherService.WeatherLayers.Table[a];
        if weatherLayer == nil then continue end;

        if weatherLayer.Value and weatherLayer.Value ~= activeWeather then
            weatherLayer.Value.StartTick = nil;
        end
    end
    
    script:SetAttribute("Active", HttpService:JSONEncode(activeWeather));
end

function WeatherService:GetActive()
    if RunService:IsClient() then
        return HttpService:JSONDecode(script:GetAttribute("Active"));
    end

    return WeatherService.WeatherLayers:Get();
end

function WeatherService:SetWeather(packet)
    local id = packet.Id;
    local priority = packet.Priority or 1;
    local expire = packet.Expire or 300;

    local event = modEventService:ServerInvoke("WeatherService.OnWeatherSet", game.Players:GetPlayers(), packet);
    if not event.Cancelled then
        WeatherService.WeatherLayers:Set(id, packet, priority, expire);

    else
        Debugger:Warn(`Set Weather ( {id} ) cancelled.`);

    end

    return event;
end

function WeatherService:ClearWeather(id)
    WeatherService.WeatherLayers:Remove(id);
end

if RunService:IsServer() then
    task.spawn(function()
		Debugger.AwaitShared("modCommandsLibrary");

		shared.modCommandsLibrary:HookChatCommand("weather", {
			Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;
			Description = [[Weather commands:
			/weather start [weatherId] [duration]
            /weather stop [weatherId]
            /weather list
			]];

			RequiredArgs = 0;
			Function = function(speaker, args)
				
				local action = args[1];
				
				if action == "start" then
                    local weatherId = args[2] or "rain";
                    local duration = args[3];

                    local event = WeatherService:SetWeather({
                        Id=weatherId;
                        Expire=duration;
                    });
                    if event.Cancelled then
                        shared.Notify(speaker, `Start ( {weatherId} ) Weather was cancelled.`, "Inform");
                    else
                        shared.Notify(speaker, `Started ( {weatherId} ) Weather.`, "Inform");
                    end

                elseif action == "stop" then
                    local weatherId = args[2] or WeatherService.ActiveWeather and WeatherService.ActiveWeather.Id;

                    WeatherService:ClearWeather(weatherId);
                    shared.Notify(speaker, `Clearing ( {weatherId} ) Weather.`, "Inform");

                elseif action == "list" then
                    local weathers = modWeatherLibrary:GetKeys();
                    shared.Notify(speaker, `Weathers: {table.concat(weathers, ", ")}`, "Inform");

                else
					shared.Notify(speaker, "Unknown action for /weather", "Negative");

				end

				return;
			end;
		});

	end)

    -- modEventService:OnInvoked("WeatherService.OnWeatherSet", function(event, packet)
    --     Debugger:Warn("Server event", event, "packet", packet);
    -- end)

else
    -- modEventService:OnInvoked("WeatherService.OnWeatherSet", function(event, packet)
    --     Debugger:Warn("Client event", event, "packet", packet);
    -- end)

end

return WeatherService;