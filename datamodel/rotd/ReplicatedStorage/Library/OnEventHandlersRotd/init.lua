local Debugger = require(game.ReplicatedStorage.Library.Debugger).new(script);
--==
local modOnEventsHandlers = shared.require(game.ReplicatedStorage.Library.OnEventHandlers);

for _, m in pairs(script:GetChildren()) do
    modOnEventsHandlers.loadHandler(m);
end
script.ChildAdded:Connect(modOnEventsHandlers.loadHandler);

return modOnEventsHandlers;