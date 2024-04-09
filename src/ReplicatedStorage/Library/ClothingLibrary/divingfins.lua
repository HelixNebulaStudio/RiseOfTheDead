local modClothingProperties = require(script.Parent:WaitForChild("ClothingProperties"));
local modConfigurations = require(game.ReplicatedStorage.Library.Configurations);

return function()
	local Clothing = {};
	Clothing.SwimmingSpeed = 25;
	
	return modClothingProperties.new(Clothing);
end;
