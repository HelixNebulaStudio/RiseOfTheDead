local modClothingProperties = require(script.Parent:WaitForChild("ClothingProperties"));
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

return function()
	local Clothing = {};
	Clothing.TickRepellent = 1;
	Clothing.BaseArmorPoints = 5;
	Clothing.ModArmorPoints = 5;
	Clothing.Warmth = 10;
	
	return modClothingProperties.new(Clothing);
end;