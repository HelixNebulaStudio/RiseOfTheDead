local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));

local attirePackage = {
	GroupName="LegGroup";
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};

	toolLib.Warmth = 2;
	
	return modClothingProperties.new(toolLib);
end

return attirePackage;