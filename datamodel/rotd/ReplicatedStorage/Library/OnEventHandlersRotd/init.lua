local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modOnEventsHandlers = shared.require(game.ReplicatedStorage.Library.OnEventHandlers);

function modOnEventsHandlers.onRequire()
    for _, m in pairs(script:GetChildren()) do
        task.spawn(modOnEventsHandlers.loadHandler, m);
    end
    script.ChildAdded:Connect(modOnEventsHandlers.loadHandler);
end

return modOnEventsHandlers;