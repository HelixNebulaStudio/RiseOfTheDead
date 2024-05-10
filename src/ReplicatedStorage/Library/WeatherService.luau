local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local WeatherService = {};

local RunService = game:GetService("RunService");
local HttpService = game:GetService("HttpService");

local modEventService = require(game.ReplicatedStorage.Library.EventService);
local modLayeredVariable = require(game.ReplicatedStorage.Library.LayeredVariable);

WeatherService.WeatherLayers = modLayeredVariable.new({});
--==

function WeatherService:OnTick()
    local activeWeather = WeatherService.WeatherLayers:Get();
    script:SetAttribute("Active", HttpService:JSONEncode(activeWeather));
end

function WeatherService:GetActive()
    if RunService:IsClient() then
        return HttpService:JSONDecode(script:GetAttribute("Active")); 
    end
    return;
end

function WeatherService:SetWeather(packet)
    local id = packet.Id;
    local priority = packet.Priority or 1;
    local expire = packet.Expire or 300;

    packet.TestWs = workspace;
    
    local event = modEventService:ReplicateInvoke("WeatherService.OnSetWeather", game.Players:GetPlayers(), packet);
    if not event.Cancelled then
        WeatherService.WeatherLayers:Set(id, packet, priority, expire);

    else
        Debugger:Warn(`Set Weather ( {id} ) cancelled.`);

    end

    return event;
end

if RunService:IsServer() then
    task.spawn(function()
		Debugger.AwaitShared("modCommandsLibrary");

		shared.modCommandsLibrary:HookChatCommand("weather", {
			Permission = shared.modCommandsLibrary.PermissionLevel.DevBranch;
			Description = [[Weather commands:
			/weather start [weatherId] [duration]
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
                        shared.Notify(speaker, `Start ( {weatherId} ) Event was cancelled.`, "Inform");
                    else
                        shared.Notify(speaker, `Started ( {weatherId} ) Event.`, "Inform");
                    end

                else
					shared.Notify(speaker, "Unknown action for /weather", "Negative");

				end

				return;
			end;
		});

	end)

    modEventService:OnInvoked("WeatherService.OnSetWeather", function(event, packet)
        Debugger:Warn("Server event", event, "packet", packet);
    end)

else
    modEventService:OnInvoked("WeatherService.OnSetWeather", function(event, packet)
        Debugger:Warn("Client event", event, "packet", packet);
    end)

end

return WeatherService;