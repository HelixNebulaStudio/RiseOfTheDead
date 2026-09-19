
local modToolsLibrary = shared.require(game.ReplicatedStorage.Library.ToolsLibrary);

function modToolsLibrary.onRequire()
	for _, module in pairs(script:GetChildren()) do
		modToolsLibrary.LoadToolModule(module);
	end
	script.ChildAdded:Connect(modToolsLibrary.LoadToolModule);
end

return modToolsLibrary;