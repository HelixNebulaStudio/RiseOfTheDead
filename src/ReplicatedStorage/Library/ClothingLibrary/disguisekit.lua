local modClothingProperties = require(script.Parent:WaitForChild("ClothingProperties"));
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

return function()
	local Clothing = {};
	Clothing.GasProtection = 0.1;
	Clothing.HasFlinchProtection = true;
	
	return modClothingProperties.new(Clothing);
end;