local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
shared.waitForIgnition();
--==
local RunService = game:GetService("RunService");
local CollectionService = game:GetService("CollectionService");

local modGlobalVars = shared.require(game.ReplicatedStorage:WaitForChild("GlobalVariables"));
local modMapLibrary = shared.require(game.ReplicatedStorage.Library.MapLibrary);
local modConfigurations = shared.require(game.ReplicatedStorage.Library.Configurations);
local modVector = shared.require(game.ReplicatedStorage.Library.Util.Vector);


local SPAWN_TYPE_SPACING = {
	Zombie=8;
}

local ACTIVE_SPAWNERS = {};
--==

local Spawner = {};
Spawner.__index = Spawner;

function Spawner.new(spawnConfig: Configuration)
	local spawnPart = spawnConfig.Parent;
    spawnPart.Parent = script;

    local self = {
        Disabled = false;

        PartName = spawnPart.Name;
        Config = spawnConfig;

		CFrame = spawnPart.CFrame;
		Size = spawnPart.Size;

        SpawnNpcName = spawnConfig:GetAttribute("SpawnNpcName");
        RespawnCooldown = spawnConfig:GetAttribute("RespawnCooldown");
        SpawnMax = spawnConfig:GetAttribute("SpawnMax");
        SpawnMin = spawnConfig:GetAttribute("SpawnMin");
        SpawnSpacing = spawnConfig:GetAttribute("SpawnSpacing");

        SpawnLevel = spawnConfig:GetAttribute("SpawnLevel");
        SpawnMinLevel = spawnConfig:GetAttribute("SpawnMinLevel");
        SpawnMaxLevel = spawnConfig:GetAttribute("SpawnMaxLevel");
        LevelTier = spawnConfig:GetAttribute("LevelTier") or 1;
        Immortal = spawnConfig:GetAttribute("Imortal");

        SpawnModelSize = nil;
        SpawnRegion = nil;

        SpawningTick = tick();

        ActiveNpcs = {};
    };

    setmetatable(self, Spawner);

    if spawnConfig:GetAttribute("Disabled") == nil then
        spawnConfig:SetAttribute("Disabled", false);
    end
    spawnConfig:GetAttributeChangedSignal("Disabled"):Connect(function()
        self.Disabled = spawnConfig:GetAttribute("Disabled") == true;
    end)

    local npcPrefab = shared.modNpcs.getNpcPrefab(self.SpawnNpcName);

    self.SpawnModelSize = npcPrefab:GetExtentsSize();

    local spawnAreaSize = self.Size;
    local spawnSpace = Vector2.new(spawnAreaSize.X,spawnAreaSize.Z) / Vector2.new(self.SpawnModelSize.X, self.SpawnModelSize.Z);

    local spawnTypeSpacing = SPAWN_TYPE_SPACING[self.SpawnNpcName] or self.SpawnSpacing or 32;
    self.SpawnMaxBySpace = math.ceil(math.ceil(spawnSpace.X) * math.ceil(spawnSpace.Y) / math.pow(spawnTypeSpacing,2) );
	
    local worldSpaceSize = self.CFrame:vectorToWorldSpace(self.Size);
    worldSpaceSize = Vector3.new(math.abs(worldSpaceSize.X), math.abs(worldSpaceSize.Y), math.abs(worldSpaceSize.Z));
    
    local pos = self.CFrame.Position;
    local pointMin = pos - worldSpaceSize/2;
    local pointMax = pos + worldSpaceSize/2;
    self.SpawnRegion = {Min=pointMin; Max=pointMax;};
    
    table.insert(ACTIVE_SPAWNERS, self);
    return self;
end

function Spawner:Destroy()
    for a=#self.ActiveNpcs, 1, -1 do
        local npcClass = self.ActiveNpcs[a];
        if npcClass == nil then continue end;
        
        npcClass:Destroy();
    end
end

function Spawner:GetSpawnCFrame()
    local targetPos = Vector3.new(
        math.random(self.SpawnRegion.Min.X*10, self.SpawnRegion.Max.X*10)/10,
        self.SpawnRegion.Max.Y,
        math.random(self.SpawnRegion.Min.Z*10, self.SpawnRegion.Max.Z*10)/10
    );

    local rayDist = (self.SpawnRegion.Max.Y-self.SpawnRegion.Min.Y) + self.SpawnModelSize.Y;
    local groundRay = Ray.new(targetPos, Vector3.new(0, -rayDist, 0));
    local groundHit, groundPoint = workspace:FindPartOnRayWithWhitelist(groundRay, {workspace.Environment; workspace.Terrain}, false);

    if groundHit then
        targetPos = Vector3.new(targetPos.X, groundPoint.Y + (self.SpawnModelSize.Y/2)-0.25, targetPos.Z);
    end;
    
    local targetCFrame = CFrame.new(targetPos) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0);

    local isFreeSpace = modVector.IsFreeSpace(targetCFrame + Vector3.new(0, 0.5, 0), self.SpawnModelSize);
    
    if isFreeSpace == false then 
        return nil;
    end;

    return targetCFrame;
end

function Spawner:RequestSpawn()
    if self.Disabled == true then return end;
    if self.SpawningTick > tick() then return end;
    self.SpawningTick = tick()+2;

    local naturalSpawnLimit = modConfigurations.NaturalSpawnLimit or 999;

    task.spawn(function() 
        local spawnMaxBySpace = self.SpawnMaxBySpace;
        local spawnMin = self.SpawnMin or 1;
        local spawnMax = self.SpawnMax or spawnMaxBySpace;

        local minCount = math.max(spawnMin, math.floor(spawnMax * 0.2) or 0);
        local maxCount = math.min(spawnMaxBySpace, spawnMax, minCount);

        local playerClasses, _distSqrd = shared.modPlayers.PositionsOctree:RadiusSearch(self.CFrame.Position, 100);
        local playerCount = #playerClasses;

        if playerCount > 0 then
            playerCount = math.max(playerCount, 3);
        end

        local spawnCount = minCount + math.ceil(playerCount/game.Players.MaxPlayers * maxCount);
        if maxCount == 1 then
            spawnCount = 1;
        end

        if RunService:IsStudio() then
            self.Config:SetAttribute("_SpawnCount", spawnCount);
            self.Config:SetAttribute("_PlayerCount", playerCount);
            self.Config:SetAttribute("_ActiveCount", #self.ActiveNpcs);
            self.Config:SetAttribute("_MaxCount", maxCount);
            self.Config:SetAttribute("_MinCount", minCount);
            self.Config:SetAttribute("_SpawnMaxBySpace", spawnMaxBySpace);
        end
        
        if #self.ActiveNpcs < spawnCount then
            for a=1, math.min(spawnCount - #self.ActiveNpcs, 3) do
                if RunService:IsStudio() == false and #shared.modNpcs.ActiveNpcClasses > naturalSpawnLimit then break; end;

                local cframe = self:GetSpawnCFrame();
                if cframe == nil then continue; end;

                self:Spawn(cframe, playerClasses);

                task.wait();
            end
        end
    end)
end

--MARK: Spawn
function Spawner:Spawn(cframe: CFrame, playerClasses: {PlayerClass})
    if self.Disabled == true then return end;

    local spawnNpcName = self.SpawnNpcName;

    shared.modNpcs.spawn2{
        Name = spawnNpcName;
        CFrame = cframe;
        BindSetup = function(npcClass: NpcClass)
            npcClass.Character:SetAttribute("NaturalSpawn", true);
            table.insert(self.ActiveNpcs, npcClass);

            if self.Config:GetAttribute("BodyForceAnchor") then
                local bodyVelocity = Instance.new("BodyVelocity");
                local maxForce = 10000;
                bodyVelocity.MaxForce = Vector3.new(maxForce, 1000, maxForce);
                bodyVelocity.Velocity = Vector3.new(0, 0, 0);
                
                bodyVelocity.Parent = npcClass.RootPart;
            end

            task.spawn(function()
                local rp = npcClass.RootPart;
                if rp == nil then return end;

                rp.Anchored = true;
                task.wait(0.5);
                rp.Anchored = false;
            end)
            
            local layerName = modMapLibrary:GetLayer(cframe.Position);
            npcClass.Properties.MapLayerName = layerName;
            
            npcClass.HealthComp.OnIsDeadChanged:Connect(function(isDead) 
                if not isDead then return end;

                task.wait(self.RespawnCooldown or 10);

                for a=#self.ActiveNpcs, 1, -1 do
                    local npcClass: NpcClass = self.ActiveNpcs[a];
                    if npcClass.HealthComp and not npcClass.HealthComp.IsDead then continue end;
                    
                    table.remove(self.ActiveNpcs, a);
                end
            end)

            --== Set Level
            local maxLevel = math.round(modGlobalVars.MaxLevels-100);
            local spawnLevel = self.SpawnLevel;
            if spawnLevel then
                local levelPlus5Percent = math.ceil(spawnLevel*1.05);
                local levelMinus10Percent = math.floor(spawnLevel*0.9);
                spawnLevel = math.clamp(
                    math.random(levelMinus10Percent, levelPlus5Percent), 
                    0, 
                    maxLevel
                );

            else
                local avgPlayerLevel;
                for a=1, #playerClasses do
                    local playerClass: PlayerClass = playerClasses[a];
                    local profile: Profile = shared.modProfile:Get(playerClass:GetInstance());
                    local gameSave: GameSave = profile:GetActiveSave();
                    local playerLevel = gameSave and gameSave:GetStat("Level") or 1;
                    avgPlayerLevel = avgPlayerLevel and (avgPlayerLevel + playerLevel)/2 or playerLevel;
                end

                avgPlayerLevel = math.clamp(avgPlayerLevel or 0, 0, maxLevel);

                local areaDifficulty = 1;

                local mapLibFolder = layerName and game.ReplicatedStorage:FindFirstChild("MapLibraryData");
                if mapLibFolder then
                    local layerFolder = mapLibFolder:FindFirstChild(layerName);
                    areaDifficulty = layerFolder and layerFolder:GetAttribute("LevelDifficulty") or 1;

                    if RunService:IsStudio() then
                        self.Config:SetAttribute("_AreaDifficulty", areaDifficulty);
                    end
                end

                spawnLevel = math.clamp(
                    math.round(avgPlayerLevel * (areaDifficulty/10)), 
                    self.SpawnMinLevel or 1, 
                    self.SpawnMaxLevel or maxLevel
                );
            end

            npcClass.Properties.Level = spawnLevel;

            if self.Immortal ~= nil then
                npcClass.Properties.Immortal = self.Immortal;
            end
        end
    };
end

--==
local npcSpawnerList = CollectionService:GetTagged("NpcSpawner");
for a=1, #npcSpawnerList do
	local npcSpawnerConfig: Configuration = npcSpawnerList[a];
	if not npcSpawnerConfig:IsA("Configuration") then continue end;

    Spawner.new(npcSpawnerConfig);
end

CollectionService:GetInstanceAddedSignal("NpcSpawner"):Connect(function(newConfig)
    Spawner.new(newConfig);
end)

CollectionService:GetInstanceRemovedSignal("NpcSpawner"):Connect(function(removedConfig)
    for a=#ACTIVE_SPAWNERS, 1, -1 do
        if ACTIVE_SPAWNERS[a].Config ~= removedConfig then continue end;
        
        local spawner = ACTIVE_SPAWNERS[a];
        table.remove(ACTIVE_SPAWNERS, a);
        spawner:Destroy();
    end
end)

--==

local requestTick = tick();
RunService.Heartbeat:Connect(function()
    if tick()-requestTick < 0.5 then return end;
    requestTick = tick();

    for a=1, #ACTIVE_SPAWNERS do
        ACTIVE_SPAWNERS[a]:RequestSpawn();
    end
end)