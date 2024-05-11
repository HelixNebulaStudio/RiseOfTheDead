local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

local remoteEventService = modRemotesManager:Get("EventService");

--== MARK: EventPacket;
local EventPacket = {};
EventPacket.__index = EventPacket;

type EventPacketObject = {
	Cancelled: boolean;
    Completed: boolean;

    Players: {[number]: Player}?;
}
export type EventPacket = typeof(setmetatable({} :: EventPacketObject, EventPacket));


function EventPacket.new() : EventPacket
    local self = {
        Cancelled = false;
        Completed = false;

        Players = nil;
    };

    setmetatable(self, EventPacket);
    return self;
end

function EventPacket:SetCancelled(value: boolean)
    if self.Completed then
        Debugger:Warn(`Failed to set cancel on completed event.\nStackTrace: {debug.traceback()}`);
        return;
    end

    self.Cancelled = true;
end

--== MARK: EventHandler;
local EventHandler = {};
EventHandler.__index = EventHandler;

type EventHandlerObject = {
    Key: string;
    Listeners: {[number]: {
        StackTrace: string;
        Function: (event: EventPacket, ...any) -> nil;
    }};
}
export type EventHandler = typeof(setmetatable({} :: EventHandlerObject, EventHandler));


function EventHandler.new(key: string): EventHandler
    local self = {
        Key = key;
        Listeners = {};
    };

    setmetatable(self, EventHandler);
    return self;
end

function EventHandler:AddListener(func, position)
    position = position or math.max(#self.Listeners+1, 1);

    if self.Listeners[position] then
        Debugger:Warn(`Failed to add invoke listener for ( {self.Key} ) for Position: {position} / {#self.Listeners} \nTaken by: {self.Listeners[position].StackTrace}`);
        return;
    end
    self.Listeners[position] = {
        StackTrace = debug.traceback();
        Function = func;
    };

    return function()
        self.Listeners[position] = nil;
    end;
end

--== MARK: EventService
local EventService = {};
EventService.__index = EventService;
EventService.Handlers = {};

function EventService:GetHandler(key: string): EventHandler
    if self.Handlers[key] == nil then
        self.Handlers[key] = EventHandler.new(key);
    end
    return self.Handlers[key];
end

--[[
    EventService:Invoke(key: string, ...): EventPacket
    @return EventPacket
    @param key string | Key of event.
    @param ... ...any | Parameters of event.
]]
function EventService:Invoke(key: string, ...): EventPacket
    local eventHandler = EventService:GetHandler(key);
    local event = EventPacket.new();

    for pos, listener in pairs(eventHandler.Listeners) do
        listener.Function(event, ...);

        if event.Cancelled then
            break;
        end
    end
    event.Completed = true;

    return event;
end

--[[
    EventService:Invoke(key: string, ...): EventPacket
    @return EventPacket
    @param key string | Key of event.
    @param players {[number]: Player} | List of players to replicate to.
    @param ... ...any | Parameters of event.
]]
function EventService:ReplicateInvoke(key: string, players: {[number]: Player}, ...): EventPacket
    local eventHandler = EventService:GetHandler(key);
    local event = EventPacket.new();
    event.Players = players;

    for pos, listener in pairs(eventHandler.Listeners) do
        listener.Function(event, ...);

        if event.Cancelled then
            break;
        end
    end
    event.Completed = true;

    if not event.Cancelled then
        local packet = {
            [modRemotesManager.Ref("Key")] = key;
            [modRemotesManager.Ref("Arguments")] = {...};
        };

        for a=1, #event.Players do
            local player = event.Players[a];
            if not game.Players:IsAncestorOf(player) then continue end;

            remoteEventService:Fire(player, packet);
        end
    end

    return event;
end

--[[
    EventService:OnInvoked(key: string, func: (event: {}, ...any) -> nil, position: number?): () -> nil
    @return `() -> nil` Disconnects invoke handler.
    @param key string | Key of event.
    @param func (event, ...) -> nil | Function that gets called when event is handled.
    @param position number? | Priority of the listener connected.
]]
function EventService:OnInvoked(key: string, func: (event: EventPacket, ...any) -> nil, position: number?): () -> nil
    local eventHandler = EventService:GetHandler(key);

    return eventHandler:AddListener(func, position);
end

function EventService:GetHandlerKeys()
    local list = {};

    for key, _ in pairs(self.Handlers) do
        table.insert(list, key);
    end

    return list;
end

if RunService:IsServer() then
    modSyncTime.GetClock():GetPropertyChangedSignal("Value"):Connect(function()
        EventService:ReplicateInvoke("OnClockTick", game.Players:GetPlayers(), modSyncTime.GetTime());
	end)

else
    remoteEventService.OnEvent:Connect(function(packet)
		local key = packet[modRemotesManager.Ref("Key")];
		local args = packet[modRemotesManager.Ref("Arguments")];

        EventService:Invoke(key, unpack(args));
    end)

end

return EventService;

