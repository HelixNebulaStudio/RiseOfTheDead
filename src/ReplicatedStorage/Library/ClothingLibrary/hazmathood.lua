local modClothingProperties = require(script.Parent:WaitForChild("ClothingProperties"));
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

return function()
	local Clothing = {};
	Clothing.GasProtection = 0.5;
	Clothing.Warmth = 3;
	Clothing.HasFlinchProtection = true;
	
	return modClothingProperties.new(Clothing);
end;
