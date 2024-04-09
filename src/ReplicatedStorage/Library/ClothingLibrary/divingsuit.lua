local modClothingProperties = require(script.Parent:WaitForChild("ClothingProperties"));
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

return function()
	local Clothing = {};
	Clothing.Warmth = 6;

	Clothing.OxygenDrainReduction = 0.7;
	Clothing.OxygenRecoveryIncrease = 0.3;
	
	return modClothingProperties.new(Clothing);
end;