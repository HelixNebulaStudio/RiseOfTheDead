local modClothingProperties = require(script.Parent:WaitForChild("ClothingProperties"));
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

return function()
	local Clothing = {};
	
	Clothing.FloatOnWater = true;
	
	return modClothingProperties.new(Clothing);
end;