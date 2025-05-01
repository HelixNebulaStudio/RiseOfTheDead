
local WeaponsLibrary = require(game.ReplicatedStorage.Library.WeaponsLibrary);

for _, module in pairs(script:GetChildren()) do
	WeaponsLibrary.LoadToolModule(module);
end
script.ChildAdded:Connect(WeaponsLibrary.LoadToolModule)

return WeaponsLibrary;