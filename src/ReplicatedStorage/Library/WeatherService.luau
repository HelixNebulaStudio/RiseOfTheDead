local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local WeatherService = {};

local TweenService = game:GetService("TweenService");
local RunService = game:GetService("RunService");
local HttpService = game:GetService("HttpService");
local CollectionService = game:GetService("CollectionService");

local modEventService = require(game.ReplicatedStorage.Library.EventService);
local modLayeredVariable = require(game.ReplicatedStorage.Library.LayeredVariable);
local modWeatherLibrary = require(game.ReplicatedStorage.Library.WeatherLibrary);
local modGarbageHandler = require(game.ReplicatedStorage.Library.GarbageHandler);
local modAudio = require(game.ReplicatedStorage.Library.Audio);

WeatherService.Garbage = modGarbageHandler.new();

WeatherService.WeatherLayers = modLayeredVariable.new({});
WeatherService.ActiveWeather = nil;

local onWeatherSetEventHandler = modEventService:GetHandler("WeatherService.OnWeatherSet", true);
onWeatherSetEventHandler:SetPermissions("CanListen", true);
--==

function WeatherService:OnTick()
    local activeWeather = WeatherService.WeatherLayers:Get();
    local activeWeatherId = activeWeather and activeWeather.Id or nil;
    
    if WeatherService.ActiveWeather and WeatherService.ActiveWeather.Id == activeWeather.Id then 
        if activeWeatherId then
            local weatherLib = modWeatherLibrary:Find(activeWeatherId);
            if weatherLib and weatherLib.OnSeverTick then
                task.spawn(weatherLib.OnSeverTick, WeatherService);
            end
        end

        local waterPuddles = CollectionService:GetTagged("WaterPuddle");
        for a=1, #waterPuddles do
            local puddle: BasePart = waterPuddles[a];

            local despawnTick = puddle:GetAttribute("DespawnTick");
            if despawnTick == nil then
                despawnTick = tick()+math.random(600, 1200)/10
                puddle:SetAttribute("DespawnTick", despawnTick);

            elseif despawnTick == 0 then

            elseif tick()>despawnTick then
                puddle:SetAttribute("DespawnTick", 0);

                local d = math.random(40, 120)/10;
                TweenService:Create(puddle, TweenInfo.new(d), {
                    Transparency = 1;
                }):Play();
                game.Debris:AddItem(puddle, d);
                
            end
        end
        return; 
    end;
    WeatherService.ActiveWeather = activeWeather;

    for a=#WeatherService.WeatherLayers.Table, 1, -1 do
        local weatherLayer = WeatherService.WeatherLayers.Table[a];
        if weatherLayer == nil then continue end;

        if weatherLayer.Value and weatherLayer.Value ~= activeWeather then
            weatherLayer.Value.StartTick = nil;
        end
    end
    
    WeatherService.Garbage:Loop(function(index, trash)
        if typeof(trash) == "Instance" and trash:IsA("Sound") then
            local tweenInfo = TweenInfo.new(5);
            local tween = TweenService:Create(trash, tweenInfo, {Volume = 0})
            tween.Completed:connect(function(state)
            	if state == Enum.PlaybackState.Completed then
                    trash:Destroy();
            	end
            	tween:Destroy();
            end)
            tween:Play();
            WeatherService.Garbage.Trash[index] = nil;
        end
    end)
    WeatherService.Garbage:Destruct();

    if activeWeather.StartTick == nil then
        activeWeather.StartTick = workspace:GetServerTimeNow();
    end

    script:SetAttribute("Active", HttpService:JSONEncode(activeWeather));

    if activeWeatherId == nil then return end;

    local weatherLib = modWeatherLibrary:Find(activeWeatherId);
    if weatherLib == nil then return end;

    if weatherLib.WeatherSounds then
        for a=1, #weatherLib.WeatherSounds do
            local soundData = weatherLib.WeatherSounds[a];
            local sound = modAudio.Play(soundData.Id, workspace);
            sound.Volume = 0;
            sound:AddTag("WeatherSound");
            WeatherService.Garbage:Tag(sound);
            TweenService:Create(sound, TweenInfo.new(5), {Volume = 1}):Play();
        end
    end
end

function WeatherService:GetActive()
    if RunService:IsClient() and script:GetAttribute("Active") then
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
            /weather getactive
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

                elseif action == "getactive" then

                    Debugger:Warn("Weather GetActive", WeatherService:GetActive());

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