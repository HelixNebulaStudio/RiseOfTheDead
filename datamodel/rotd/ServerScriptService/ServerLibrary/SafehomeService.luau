local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local modBranchConfigs = shared.require(game.ReplicatedStorage.Library.BranchConfigurations);
local modRemotesManager = shared.require(game.ReplicatedStorage.Library.RemotesManager);
local modSafehomesLibrary = shared.require(game.ReplicatedStorage.Library.SafehomesLibrary);
local modGarbageHandler = shared.require(game.ReplicatedStorage.Library.GarbageHandler);

local modInteractables = shared.require(game.ReplicatedStorage.Library.Interactables);
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);
local modDoors = shared.require(game.ReplicatedStorage.Entity.Doors);

local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);

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

function SafehomeClass.new(player: Player?)
    local self = {
        IsLoading = false;
        IsSafehomeWorld = modBranchConfigs.IsWorld("Safehome");

        Owner = player;
        FactionTag = nil;
        MapId = nil;
        IsInspectOnly = false;

        Garbage = modGarbageHandler.new();

        SpawnBasePart = nil;
        InstanceConfigList = {};
        NpcClassList = {};
    };

    setmetatable(self, SafehomeClass);

    if player then
        player.Destroying:Connect(self.Destroy);
    end

    return self;
end

function SafehomeClass:Destroy()
    Debugger:Warn(`SafehomeClass:Destroy()`);
    self.Garbage:Destruct();
    table.clear(self.InstanceConfigList);

    for npcName, npcClass in pairs(self.NpcClassList) do
        npcClass:Destroy();
    end
    table.clear(self.NpcClassList);

    self.Owner = nil;
end

--MARK: ChangeMap
function SafehomeClass:ChangeMap(mapId: string)
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
        npcClass.RootPart.Anchored = true;
    end
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
                    if c.Name == "FactionElements" and self.FactionTag == nil then
                        game.Debris:AddItem(obj, 0);

                    elseif c.Name == "Game" then
                        for _, gameChild in pairs(c:GetChildren()) do
                            if not gameChild:IsA("Model") then continue end;
                            
                            local interactConfig = gameChild:FindFirstChild("Interactable", true);
                            if interactConfig and interactConfig:IsA("Configuration") then
                                table.insert(self.InstanceConfigList, interactConfig);
                            end
                        end
                        self.Garbage:Tag(c);
                        c.Parent = workspace.Environment;

                    else
                        self.Garbage:Tag(c);
                        c.Parent = workspace.Environment;
                    end
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
    
    for a=1, #self.InstanceConfigList do
        local interactConfig = self.InstanceConfigList[a];

        local interactable: InteractableInstance = modInteractables.getOrNew(interactConfig);
        if interactable == nil then continue end;

        if interactable.Type == "Door" then
		    local door: DoorInstance = modDoors.getOrNew(interactConfig.Parent:FindFirstChild("Door"));
            if door then
            end
        end
    end

    for a=1, #self.NpcClassList do
        local npcClass: NpcClass = self.NpcClassList[a];

        local npcSpotAtt = self:GetNpcSpot(npcClass.Name);
        npcClass:SetCFrame(npcSpotAtt.WorldCFrame);

        npcClass.RootPart.Anchored = false;
    end

    Debugger:StudioLog("ChangedMap self.InstanceConfigList", self.InstanceConfigList);

    self.IsLoading = false;
end

function SafehomeClass:GetNpcSpot(npcName: string)
    local spawnsBasePart = self.SpawnBasePart;
    if self.SpawnBasePart == nil then return end;
    
    local defaultSpawnAtt = spawnsBasePart:WaitForChild("DefaultSpawn");

	if spawnsBasePart == nil then
		return defaultSpawnAtt;
	end
	
	local npcSpots = {};
	for _, spawnAtt in pairs(spawnsBasePart:GetChildren()) do
		if spawnAtt.Name == "NpcSpot" and spawnAtt:GetAttribute("ActiveNpc") == nil then
			table.insert(npcSpots, spawnAtt);
		end
	end
	
	if #npcSpots <= 0 then return defaultSpawnAtt end;
	
	local rngNpcSpot = npcSpots[math.random(1, #npcSpots)];
	rngNpcSpot:SetAttribute("ActiveNpc", npcName);
	
	return rngNpcSpot;
end

function SafehomeClass:LoadNpcs(namesList)
    local spawnsBasePart = self.SpawnBasePart;
    if self.SpawnBasePart == nil then return end;

    for _, spawnAtt in pairs(spawnsBasePart:GetChildren()) do
        if spawnAtt.Name == "NpcSpot" then
            spawnAtt:SetAttribute("ActiveNpc", nil);
        end
    end

    for a=1, #namesList do
        local npcName = namesList[a];
        local npcClass: NpcClass = self.NpcClassList[npcName];

        if npcClass then continue end;

        local npcSpotAtt = self:GetNpcSpot(npcName);

        npcClass = shared.modNpcs.spawn2{
            Name = npcName;
            CFrame = npcSpotAtt.WorldCFrame;
            Player = self.Owner;
        };

        self.NpcClassList[npcName] = npcClass;
    end
end

function SafehomeClass:SetInspectMode(value: boolean)
    if value == self.IsInspectOnly then return end;

    self.IsInspectOnly = value;

    for a=1, #self.InstanceConfigList do
        local interactConfig: Configuration = self.InstanceConfigList[a];
        local interactable = modInteractables.getOrNew(interactConfig);
        if interactable == nil then continue end;
        if interactable.Type == "Door" then continue end;

        interactable.Values.InspectMode = value;
    end
end

function SafehomeClass:LoadCustomization(homeData)
    if homeData == nil then return end;

    Debugger:Warn("Safehome homeData", homeData);

    local safehomeCustomizableFolder = workspace.Environment:FindFirstChild("Customizable");
    if safehomeCustomizableFolder then
        for groupId, groupData in pairs(homeData and homeData.Customization or {}) do
            local folder = safehomeCustomizableFolder:FindFirstChild(groupId);
            if folder then
                local newColor = Color3.fromHex(groupData.Color);
                for _, obj in pairs(folder:GetChildren()) do
                    obj.Color = newColor;
                end
            end
        end
    end

end

function SafehomeClass:GetSpawnPlatform(spaceSize, platformsFilterFunc)
    local outsideSpawnPlatforms = {};
    for _, obj in pairs(self.SpawningPlatformFolder:GetChildren()) do
        if platformsFilterFunc ~= nil and platformsFilterFunc(obj) ~= true then continue end;

        table.insert(outsideSpawnPlatforms, obj);
    end

    for a=1, 100 do
        local platformPart = outsideSpawnPlatforms[math.random(1, #outsideSpawnPlatforms)];
        
        local size = platformPart.Size;
        local cframe = platformPart.CFrame;

        local worldSpaceSize = cframe:VectorToWorldSpace(size);
        worldSpaceSize = Vector3.new(math.abs(worldSpaceSize.X), math.abs(worldSpaceSize.Y), math.abs(worldSpaceSize.Z));
        
        local pos = cframe.Position;
        local pointMin = pos - worldSpaceSize/2;
        local pointMax = pos + worldSpaceSize/2;

        local targetPos = Vector3.new(
            math.random(pointMin.X*10, pointMax.X*10)/10,
            pointMax.Y,
            math.random(pointMin.Z*10, pointMax.Z*10)/10
        );

        local targetCFrame = CFrame.new(targetPos) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0);

        local isFreeSpace = modVector.IsFreeSpace(targetCFrame + Vector3.new(0, 0.5 + spaceSize.Y/2, 0), spaceSize);
        if not isFreeSpace then continue end;

        return targetCFrame;
    end

    return;
end

SafehomeService.SafehomeClass = SafehomeClass;
return SafehomeService;