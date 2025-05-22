local modClothingLibrary = shared.require(game.ReplicatedStorage.Library.ClothingLibrary);

function modClothingLibrary.onRequire()
	for _, module in pairs(script:GetChildren()) do
		modClothingLibrary.LoadToolModule(module);
	end
	script.ChildAdded:Connect(modClothingLibrary.LoadToolModule)
end

return modClothingLibrary;