
local ToolsLibrary = require(game.ReplicatedStorage.Library.ToolsLibrary);

for _, module in pairs(script:GetChildren()) do
	ToolsLibrary.LoadToolModule(module);
end
script.ChildAdded:Connect(ToolsLibrary.LoadToolModule)

return ToolsLibrary;