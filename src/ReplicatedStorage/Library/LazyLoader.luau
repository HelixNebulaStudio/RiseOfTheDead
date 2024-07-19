local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local remote = script:WaitForChild("UnreliableRemoteEvent") :: UnreliableRemoteEvent; 
--
local LazyLoader = {};
LazyLoader.__index = LazyLoader;

LazyLoader.List = {};
--
function LazyLoader.new(src: LuaSourceContainer)
    if LazyLoader.List[src] then return LazyLoader.List[src] end;
    
    local self = {
        Script=src;

        OnServerRequested=nil;
        OnClientLoad=nil;
    };
    setmetatable(self, LazyLoader);

    LazyLoader.List[src] = self;
    return self;
end

if RunService:IsServer() then
    function LazyLoader:ConnectOnServerRequested(func)
        self.OnServerRequested = func;
    end

    remote.OnServerEvent:Connect(function(player, src: LuaSourceContainer, key)
        local lazyLoader = LazyLoader.List[src];
        if lazyLoader == nil then return end;

        if lazyLoader.OnServerRequested then
            local packet = lazyLoader.OnServerRequested(player, key);
            if packet then
                remote:FireClient(player, lazyLoader.Script, key, packet);
            end
        end
    end)
end

if RunService:IsClient() then
    function LazyLoader:Request(key)
        remote:FireServer(self.Script, key);
    end
    
    function LazyLoader:ConnectOnClientLoad(func)
        self.OnClientLoad = func;
    end

    remote.OnClientEvent:Connect(function(src, key, packet)
        local lazyLoader = LazyLoader.List[src];
        if lazyLoader == nil then return end;

        if lazyLoader.OnClientLoad then
            lazyLoader.OnClientLoad(key, packet);
        end
    end)
end

return LazyLoader;