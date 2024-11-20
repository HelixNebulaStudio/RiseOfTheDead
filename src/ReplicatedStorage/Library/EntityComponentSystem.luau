local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local RunService = game:GetService("RunService");

local EntityComponentSystem = {};
EntityComponentSystem.__index = EntityComponentSystem;

-- MARK: System
local System = {};
System.__index = System;

function System.new(stepSize)
    local self = {
        List = setmetatable({}, {__mode="v"});
        UpdateFunc = nil;
    };

    local updateStepTick = tick()-(stepSize or 0);
    RunService.Heartbeat:Connect(function(delta)
        if stepSize then
            if updateStepTick > tick() then return end;
            updateStepTick = tick() + stepSize;
        end

        for a=1, #self.List do
            if self.List[a] == nil then continue end;
            task.spawn(self.UpdateFunc, delta, self.List[a]);
        end
    end)

    setmetatable(self, System);
    return self;
end

function System:Update(func)
    self.UpdateFunc = func;
end

function System:Add(entity)
    if table.find(self.List, entity) then return end;
    table.insert(self.List, entity);

end

function System:Remove(entity)
    for a=#self.List, 1, -1 do
        if self.List[a] == entity then
            table.remove(self.List, a);
        end
    end
end

function EntityComponentSystem.newSystem(stepSize)
    return System.new(stepSize);
end


return EntityComponentSystem;