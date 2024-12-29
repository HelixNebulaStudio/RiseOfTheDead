local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modBitFlags = require(game.ReplicatedStorage.Library.BitFlags);
local modRemotesManager = require(game.ReplicatedStorage.Library.RemotesManager);
local modSyncTime = require(game.ReplicatedStorage.Library.SyncTime);

local remoteEventService = modRemotesManager:Get("EventService") :: RemoteEvent;

local EventHandlerPermissions = modBitFlags.new();
EventHandlerPermissions:AddFlag("CanInvoke", "Client can invoke");
EventHandlerPermissions:AddFlag("CanListen", "Client can listen to event")
EventHandlerPermissions:AddFlag("CanCancel", "Client can cancel event");

local EventSource = {
    Server = 1;
    Client = 2;
};

local localPlayer = game.Players.LocalPlayer;

local EventPacket = {};
local EventHandler = {};
local EventService = {};

--== MARK: EventPacket;
EventPacket.__index = function(t, k)
    if k == "Player" then
        return t.Players and t.Players[1];
    end
    return t[k];
end;
EventPacket.__metatable = "The metatable is locked";
EventPacket.__newindex = function(t, k, v)
    if k == "Players" then
        rawset(t, k, v);

        return;
    end

    error(`Attempt modify locked values by setting k({k}) = v({v}).`);
end;

type EventPacketObject = {
	Cancelled: boolean;
    Completed: boolean;

    Player: Player?;
    Players: {[number]: Player}?;
}
export type EventPacket = typeof(setmetatable({} :: EventPacketObject, EventPacket));


function EventPacket.new(key: string, eventSource: number) : EventPacket
    local self = {
        Key = key;
        Source = eventSource;

        Cancelled = false;
        Completed = false;

        Players = nil;
    };

    setmetatable(self, EventPacket);
    return self;
end

function EventPacket:SetCancelled(value: boolean)
    if self.Completed then
        Debugger:Warn(`Failed to set cancel on completed event ({self.Key}).`);
        return;
    end

    if RunService:IsClient() then
        if self.Source == EventSource.Server then
            Debugger:Warn(`Client has no authority to cancel event from received server ({self.Key}).`);

        else
            local eventHandler = EventService:GetHandler(self.Key);
        
            if eventHandler == nil or eventHandler:HasPermissions(localPlayer, "CanCancel") == false then
                Debugger:Warn(`Player ({localPlayer}) does not have permission:CanCancel to listen to event ({self.Key}).`);
                return;
            end

        end
    end

    rawset(self, "Cancelled", value);
end


--== MARK: EventHandler;
EventHandler.__index = EventHandler;

type EventHandlerObject = {
    Key: string;
    Listeners: {[number]: {
        StackTrace: string;
        Function: (event: EventPacket, ...any) -> nil;
    }};
    
    HandlerBitString: number | string;
    ClientsBitString: {[Player]: number | string};
}
export type EventHandler = typeof(setmetatable({} :: EventHandlerObject, EventHandler));


function EventHandler.new(key: string): EventHandler
    local self = {
        Key = key;
        Listeners = {};

        ReplicateToClients = false;
        ReplicateToServer = false;

        HandlerBitString = 0;
        ClientsBitString = {};
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

function EventHandler:SetPermissions(flagTag: string, value: boolean)
    self.HandlerBitString = EventHandlerPermissions:Set(self.HandlerBitString, flagTag, value);
end

function EventHandler:HasPermissions(flagTag: string, player: Player?): boolean
    local eventFlag = EventHandlerPermissions:Test(flagTag, self.HandlerBitString);

    local clientBitString = player and self.ClientsBitString[player];
    if clientBitString == nil then return eventFlag; end

    local clientFlag = EventHandlerPermissions:Test(flagTag, clientBitString);
    return eventFlag and clientFlag;
end

function EventHandler:SetPlayerPermissions(player: Player, flagTag: string, value: boolean)
    local clientBitString = self.ClientsBitString[player] or 0;
    clientBitString = EventHandlerPermissions:Set(clientBitString, flagTag, value);
    self.ClientsBitString[player] = clientBitString;
end


--== MARK: EventService
EventService.__index = EventService;
EventService.EventSource = EventSource;
EventService.Handlers = {};


function EventService:GetHandler(key: string, newIfNil: boolean?): EventHandler
    if self.Handlers[key] == nil and newIfNil == true then
        self.Handlers[key] = EventHandler.new(key);
    end
    return self.Handlers[key];
end

function EventService:ServerInvoke(key: string, players: Player? | {Player}?, ...): EventPacket
    assert(RunService:IsServer(), `Can not call ServerInvoke ({key}) from client.`);

    local eventSource = EventSource.Server;    
    if typeof(players) == "Instance" and players:IsA("Player") then
        eventSource = EventSource.Client;
    end

    local eventHandler = EventService:GetHandler(key, true);
    local event = EventPacket.new(key, eventSource);
    event.Players = typeof(players) == "table" and players or typeof(players) == "Instance" and {players} or nil;

    for pos, listener in pairs(eventHandler.Listeners) do
        listener.Function(event, ...);

        if event.Cancelled then
            break;
        end
    end
    rawset(event, "Completed", true);

    if not event.Cancelled then
        local packet = {
            [modRemotesManager.Ref("Key")] = key;
            [modRemotesManager.Ref("Arguments")] = {...};
        };

        if eventSource == EventSource.Server then
            if event.Players then
                for _, player in pairs(event.Players) do
                    if eventHandler:HasPermissions("CanListen", player) then
                        remoteEventService:FireClient(player, packet);
                    end
                end
            end
            
        elseif RunService:IsClient() and eventSource == EventSource.Client then
            remoteEventService:FireServer(packet);

        end
       
    end

    return event;
end


function EventService:ClientInvoke(key: string, player: Player?, ...): EventPacket
    assert(RunService:IsClient(), `Can not call ClientInvoke ({key}) from server.`);

    local eventSource = EventSource.Client;
    if typeof(player) == "nil" then
        eventSource = EventSource.Server;
    end

    local eventHandler = EventService:GetHandler(key, true);
    local event = EventPacket.new(key, eventSource);

    for pos, listener in pairs(eventHandler.Listeners) do
        listener.Function(event, ...);

        if event.Cancelled then
            break;
        end
    end
    rawset(event, "Completed", true);

    if not event.Cancelled then
        local packet = {
            [modRemotesManager.Ref("Key")] = key;
            [modRemotesManager.Ref("Arguments")] = {...};
        };

        if eventSource == EventSource.Client then
            remoteEventService:FireServer(packet);

        end
       
    end

    return event;
end

function EventService:OnInvoked(key: string, func: (event: EventPacket, ...any) -> nil, position: number?): () -> nil
    local eventHandler = EventService:GetHandler(key, true);
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
    game.Players.PlayerRemoving:Connect(function(player)
        for key, eventHandler: EventHandler in pairs(EventService.Handlers) do
            eventHandler.ClientsBitString[player] = nil;
        end
    end)

    remoteEventService.OnServerEvent:Connect(function(player, packet)
		local key = packet[modRemotesManager.Ref("Key")];
		local args = packet[modRemotesManager.Ref("Arguments")] or {};

        if key == nil or key ~= key then Debugger:Warn(`Invalid event key ({key}).`); return end;

        local eventHandler = EventService:GetHandler(key);
        if eventHandler == nil then Debugger:Warn(`Invalid event handler ({key}).`); return end;

        if eventHandler:HasPermissions("CanInvoke", player) == false then
            Debugger:Warn(`Player ({player}) does not have permission:CanInvoke to invoke event ({key})`);
            return;
        end

        EventService:ServerInvoke(key, player, unpack(args));
    end)


    local onClockTickEventHandler = EventService:GetHandler("OnClockTick", true);
    onClockTickEventHandler:SetPermissions("CanListen", true);

    modSyncTime.GetClock():GetPropertyChangedSignal("Value"):Connect(function()
        EventService:ServerInvoke("OnClockTick", game.Players:GetPlayers(), modSyncTime.GetTime());
	end)

else
    remoteEventService.OnClientEvent:Connect(function(packet)
		local key = packet[modRemotesManager.Ref("Key")];
		local args = packet[modRemotesManager.Ref("Arguments")] or {};

        EventService:ClientInvoke(key, nil, unpack(args));
    end)

end


return EventService;

