local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modSafehomesLibrary = shared.require(game.ReplicatedStorage.Library.SafehomesLibrary);
local modGarbageHandler = shared.require(game.ReplicatedStorage.Library.GarbageHandler);

local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modDestructibles = shared.require(game.ReplicatedStorage.Library.Destructibles);

local SafehomeService = {};
SafehomeService.__index = SafehomeService;

function SafehomeService.onRequire()
    remoteSafehomeRequest = modRemotesManager:Get("SafehomeRequest");

end

function SafehomeService.teleportAllPlayersToSpawn()
    local spawnLocation = workspace:FindFirstChildWhichIsA("SpawnLocation");
    if spawnLocation == nil then return end;

    for _, player: Player in pairs(game.Players:GetPlayers()) do
        local playerClass: PlayerClass = shared.modPlayers.get(player);
        playerClass:SetCFrame(spawnLocation.CFrame * CFrame.new(0, 3, 0));
    end
end

local SafehomeClass = {};
SafehomeClass.__index = SafehomeClass;

function SafehomeClass.new()
    local self = {
        IsLoading = false;
        IsSafehomeWorld = modBranchConfigs.IsWorld("Safehome");
        MapId = nil;

        Garbage = modGarbageHandler.new();

        InstanceConfigList = {};
        NpcClassList = {};
    };

    setmetatable(self, SafehomeClass);
    return self;
end

function SafehomeClass:LoadMap(mapId: string)
    if self.IsLoading then return end;
    self.IsLoading = true;

    mapId = mapId or "default";
    if self.MapId == mapId then 
        self.IsLoading = false;
        return
    end;
    self.MapId = mapId;

	local safehomeLib = modSafehomesLibrary:Find(mapId);
	if safehomeLib == nil then
        Debugger:Warn("Invalid safehome lib", mapId);
        self.IsLoading = false;
        return;
    end;

    for a=1, #self.NpcClassList do
        local npcClass: NpcClass = self.NpcClassList[a];
        npcClass:Destroy();
    end
    table.clear(self.NpcClassList);
    table.clear(self.InstanceConfigList);
    
    if self.IsSafehomeWorld then
        SafehomeService.teleportAllPlayersToSpawn();
    end
    
    self.Garbage:Destruct();
    self.SpawningPlatformFolder = nil;

    if self.IsSafehomeWorld then
        local TEMPLATE_SAFEHOME_MAPS = game.ServerStorage:WaitForChild("SafehomeMaps");
        local mapFolder = TEMPLATE_SAFEHOME_MAPS:FindFirstChild(mapId);
        local newMap = mapFolder:Clone();

        for _, obj in pairs(newMap:GetChildren()) do
            if obj.Name == "Environment" then
                for _, c in pairs(obj:GetChildren()) do
                    self.Garbage:Tag(c);
                    c.Parent = workspace.Environment;
                end
                
            elseif obj.Name == "Debris" then
                for _, c in pairs(obj:GetChildren()) do
                    self.Garbage:Tag(c);
                    c.Parent = workspace.Debris;
                end
                
            elseif obj.Name == "Clips" then
                for _, c in pairs(obj:GetChildren()) do
                    self.Garbage:Tag(c);
                    c.Parent = workspace.Clips;
                end
                
                
            elseif obj.Name == "LightingConfiguration" then
                for _, c in pairs(obj:GetChildren()) do
                    local configTag = game.Lighting:FindFirstChild("Configuration") and game.Lighting.Configuration:FindFirstChild(c.Name);
                    if configTag then
                        configTag.Value = c.Value;
                    end
                end
                
            elseif obj.Name == "Interactables" then
                for _, c in pairs(obj:GetChildren()) do
                    self.Garbage:Tag(c);
                    c.Parent = workspace.Interactables;
                    
                    local interactConfig = c:FindFirstChild("Interactable", true);
                    if interactConfig and interactConfig:IsA("Configuration") then
                        table.insert(self.InstanceConfigList, interactConfig);
                    end

                    -- if inspectOnly == true then
                    --     local interactScript = c:FindFirstChild("Interactable", true);
                        
                    --     local doorObject = c:FindFirstChild("Door", true);
                    --     doorObject = doorObject and doorObject:IsA("ModuleScript") and shared.require(doorObject) or nil;
                    --     if doorObject then
                    --         doorObject:Toggle(true);
                    --     end
                    -- else
                    --     local interactScript = c:FindFirstChild("Interactable", true);
                        
                    -- end
                end
                
            elseif obj.Name == "SpawningPlatforms" then
                local spawningPlatformFolder = obj;
                spawningPlatformFolder.Parent = game.ServerStorage;
                self.Garbage:Tag(spawningPlatformFolder);

                self.SpawningPlatformFolder = spawningPlatformFolder;
                
            else
                if obj.Name == "Spawns" then
                    self.SpawnBasePart = obj;
                end
                self.Garbage:Tag(obj);
                obj.Parent = workspace;

            end
        end
    end

    


    self.IsLoading = false;
end

SafehomeService.SafehomeClass = SafehomeClass;
return SafehomeService;