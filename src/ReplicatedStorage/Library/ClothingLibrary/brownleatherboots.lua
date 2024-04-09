local modClothingProperties = require(script.Parent:WaitForChild("ClothingProperties"));

return function()
	local Clothing = {};
	
	Clothing.MoveImpairReduction = 0.1;
	Clothing.Warmth = 4;
	
	return modClothingProperties.new(Clothing);
end;
