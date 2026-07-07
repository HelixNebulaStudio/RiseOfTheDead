local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modDestructibles = shared.require(game.ReplicatedStorage.Entity.Destructibles);

--==
local Hazard = {
	Title = "Zpider Eggs";
	Description = "Zpider Eggs are everywhere!";
	Controller = nil;
};
Hazard.__index = Hazard;
--==
function Hazard.onRequire()
    zpiderEggsPrefab = game.ServerStorage.Prefabs.Objects:WaitForChild("ZpiderEggs");
end

function Hazard.new()
	local self = {
        Spawns = {};
        Eggs = {};
        NextSpawnTick = tick()+4;
    };
	
	setmetatable(self, Hazard);
	return self;
end

function Hazard:Load()
end

function Hazard:Begin()
	local controller = self.Controller;
	controller.StageGarbage:Tag(controller.OnSurvivalNpcSpawn:Connect(function(npcClass: NpcClass)
        if npcClass.HumanoidType ~= "Zombie" then return end;
        if npcClass.Properties.BasicEnemy ~= true then return end;

        npcClass.HealthComp.OnIsDeadChanged:Connect(function(isDead)
            if not isDead then return end;
            local deathPoint = npcClass:GetCFrame().Position;
            local gridPoint = Vector3.new(math.floor(deathPoint.X/4)*4, math.ceil(deathPoint.Y/4)*4, math.floor(deathPoint.Z/4)*4);
            
            if self.Spawns[gridPoint] and tick() <= self.Spawns[gridPoint] then return end; 
            self.Spawns[gridPoint] = tick();
        end)
    end))

    controller.StageGarbage:Tag(function()
        for _, egg in pairs(self.Eggs) do
            egg:Destroy();
        end
    end)
end

function Hazard:Tick()
	local controller = self.Controller;
    if #self.Eggs > 10 then return end;

    if tick() <= self.NextSpawnTick then return end;
    self.NextSpawnTick = tick() + math.random(4, 14);

    local sortedSpawns = {};
    for pos, t in pairs(self.Spawns) do
        table.insert(sortedSpawns, {
            T = t;
            Point = pos;
        });
    end
    table.sort(sortedSpawns, function(a, b)
        return a.T < b.T;
    end)

    local pickSpawn = sortedSpawns[1];
    if pickSpawn == nil then return; end;

    pickSpawn.T = tick() + math.random(10, 20);

    local spawnPoint = pickSpawn.Point + Vector3.new(math.random(0, 350)/100, 0, math.random(0, 350)/100);

    local rayParams = RaycastParams.new();
    rayParams.IncludeInstances = {workspace.Environment; workspace.Terrain};

    local rayResult = workspace:Raycast(spawnPoint, -Vector3.yAxis*8, rayParams);
    if rayResult == nil then
        self.NextSpawnTick = tick();
        return
    end;

    local spawnCf = CFrame.new(rayResult.Position) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0);

    local new = zpiderEggsPrefab:Clone();
    new:PivotTo(spawnCf);
    new.Parent = workspace.Environment.Game.Destructible;

    local destructConfig = new:WaitForChild("Destructible");
    destructConfig:SetAttribute("Level", self.Controller.Wave or 1);
    local destructible: DestructibleInstance = modDestructibles.getOrNew(destructConfig);
    destructible.OnDestroy:Connect(function() 
        for a=#self.Eggs, 1, -1 do
            if self.Eggs[a] ~= new then continue end;

            table.remove(self.Eggs, a);
        end
    end)
    table.insert(self.Eggs, new);

end

function Hazard:End()
	local controller = self.Controller;

    local zpiderlings = shared.modNpcs.listNpcClasses(function(npcClass: NpcClass)
        return npcClass.Name == "Zpiderling";
    end)
    for a=1, #zpiderlings do
        zpiderlings[a]:Destroy();
    end

end

return Hazard;
