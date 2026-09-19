
local modWeaponsLibrary = shared.require(game.ReplicatedStorage.Library.WeaponsLibrary);

function modWeaponsLibrary.onRequire()
	for _, module in pairs(script:GetChildren()) do
		modWeaponsLibrary.LoadToolModule(module);
	end
	script.ChildAdded:Connect(modWeaponsLibrary.LoadToolModule);
end

return modWeaponsLibrary;