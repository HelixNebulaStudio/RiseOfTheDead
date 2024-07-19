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
        Debounce = {};

        RequestLimit=nil;

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

        local isDebounced = false;

        if lazyLoader.Debounce[player] == nil then
            lazyLoader.Debounce[player] = {LastTick=tick(); Rate=lazyLoader.RequestLimit; RequestingKeys={}};
        end
        local debounceTable = lazyLoader.Debounce[player];

        if table.find(debounceTable.RequestingKeys, key) then
            isDebounced = true;

        else
            table.insert(debounceTable.RequestingKeys, key);
            task.delay(1, function()
                for a=#debounceTable.RequestingKeys, 1, -1 do
                    if debounceTable.RequestingKeys[a] == key then
                        table.remove(debounceTable.RequestingKeys, a);
                    end
                end
            end)
            
            if lazyLoader.RequestLimit then
                if tick()-debounceTable.LastTick <= 10 then
                    debounceTable.Rate = debounceTable.Rate -1;
                else
                    debounceTable.Rate = lazyLoader.RequestLimit;
                end

                if debounceTable.Rate <= 0 then
                    isDebounced = true;
                end
            end
        end

        if isDebounced then 
            Debugger:StudioLog("Request debounced", player, lazyLoader.Script, key);
            return;
        end;

        if lazyLoader.OnServerRequested then
            local packet = lazyLoader.OnServerRequested(player, key);
            if packet then
                remote:FireClient(player, lazyLoader.Script, key, packet);
            end
        end
    end)

    game:GetService("Players").PlayerRemoving:Connect(function()
        task.wait(1);
        for src, lazyLoader in pairs(LazyLoader.List) do
            local debounceList = lazyLoader.Debounce;
            for player, _ in pairs(debounceList) do
                if game.Players:IsAncestorOf(player) then continue end;
                debounceList[player] = nil;
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