local modClothingProperties = require(script.Parent:WaitForChild("ClothingProperties"));
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

return function()
	local Clothing = {};

	Clothing.BaseAdditionalStamina = 50;
	Clothing.AdditionalStamina = Clothing.BaseAdditionalStamina;
	Clothing.Warmth = 4;
	
	return modClothingProperties.new(Clothing);
end;