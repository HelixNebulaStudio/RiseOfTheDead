local modClothingProperties = require(script.Parent:WaitForChild("ClothingProperties"));
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

return function()
	local Clothing = {};
	Clothing.TickRepellent = 3;
	Clothing.BaseArmorPoints = 10;
	Clothing.ModArmorPoints = 10;
	Clothing.Warmth = 4;
	
	return modClothingProperties.new(Clothing);
end;