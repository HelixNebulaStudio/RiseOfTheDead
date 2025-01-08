local modClothingProperties = require(game.ReplicatedStorage.Library.ClothingLibrary:WaitForChild("ClothingProperties"));

local attirePackage = {
	GroupName="MiscGroup";
}

function attirePackage.NewToolLib(handler)
	local toolLib = {};

	toolLib.FloatOnWater = true;
	
	return modClothingProperties.new(toolLib);
end

return attirePackage;