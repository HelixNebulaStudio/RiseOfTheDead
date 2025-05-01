local ClothingLibrary = require(game.ReplicatedStorage.Library.ClothingLibrary);

for _, module in pairs(script:GetChildren()) do
	ClothingLibrary.LoadToolModule(module);
end
script.ChildAdded:Connect(ClothingLibrary.LoadToolModule)

return ClothingLibrary;