local modClothingProperties = require(script.Parent:WaitForChild("ClothingProperties"));
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

return function()
	local Clothing = {};
	Clothing.GasMask = true;
	Clothing.GasProtection = 0.5;
	Clothing.Warmth = 4;
	Clothing.UnderwaterVision = 0.03;
	Clothing.HasFlinchProtection = true;
	
	return modClothingProperties.new(Clothing);
end;