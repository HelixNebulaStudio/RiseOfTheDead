local modClothingProperties = require(script.Parent:WaitForChild("ClothingProperties"));
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

return function()
	local Clothing = {};
	Clothing.TickRepellent = 1;
	Clothing.BaseArmorPoints = 1;
	Clothing.ModArmorPoints = 1;
	Clothing.Warmth = 5;
	
	return modClothingProperties.new(Clothing);
end;