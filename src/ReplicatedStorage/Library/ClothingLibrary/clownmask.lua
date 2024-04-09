local modClothingProperties = require(script.Parent:WaitForChild("ClothingProperties"));
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

return function()
	local Clothing = {};

	Clothing.Slaughterfest=modConfigurations.SpecialEvent.Halloween;
	Clothing.Warmth = 4;
	Clothing.HasFlinchProtection = true;
	
	return modClothingProperties.new(Clothing);
end;
