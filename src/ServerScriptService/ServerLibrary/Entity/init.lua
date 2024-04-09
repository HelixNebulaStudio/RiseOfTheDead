local Entity = {};
Entity.__index = Entity;

local modNpc = require(script:WaitForChild("Npc")).init(Entity);

local random = Random.new();
--== Script;

function Entity.SpawnEntity(entityType, entityName)
    local modType = script:FindFirstChild(entityType);
    if modType then
        entityType = require(modType);
        return entityType.Spawn(entityName);
    else
        error("Entity type: "..entityType.." does not exist.");
    end
end;

Entity.GetCFrameFromPlatform = modNpc.GetCFrameFromPlatform;

return Entity;